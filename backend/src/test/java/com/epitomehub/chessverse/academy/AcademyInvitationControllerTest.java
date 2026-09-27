package com.epitomehub.chessverse.academy;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import com.zaxxer.hikari.HikariDataSource;
import java.util.Map;
import java.util.UUID;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.web.server.ResponseStatusException;

@SpringJUnitConfig(AcademyInvitationControllerTest.Config.class)
class AcademyInvitationControllerTest {
    @Configuration @EnableTransactionManagement
    static class Config {
        @Bean(destroyMethod = "close") DataSource dataSource() {
            HikariDataSource pool = new HikariDataSource();
            pool.setJdbcUrl("jdbc:h2:mem:academy_invites;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_UPPER=false");
            pool.setUsername("sa"); pool.setPassword(""); pool.setMaximumPoolSize(1); return pool;
        }
        @Bean JdbcTemplate jdbc(DataSource ds) { return new JdbcTemplate(ds); }
        @Bean DataSourceTransactionManager transactionManager(DataSource ds) { return new DataSourceTransactionManager(ds); }
        @Bean PlayerAuthenticationService auth() { return mock(PlayerAuthenticationService.class); }
        @Bean AcademyInvitationController controller(JdbcTemplate db, PlayerAuthenticationService auth) {
            return new AcademyInvitationController(db, auth);
        }
    }

    @Autowired AcademyInvitationController controller;
    @Autowired JdbcTemplate db;
    @Autowired DataSource ds;
    @Autowired PlayerAuthenticationService auth;
    UUID org;

    @BeforeEach void setup() {
        reset(auth); db.execute("DROP ALL OBJECTS");
        db.execute("CREATE TABLE player_account(id UUID PRIMARY KEY,display_name VARCHAR(100),email VARCHAR(254),verified BOOLEAN DEFAULT TRUE)");
        new ResourceDatabasePopulator(
                new ClassPathResource("db/migration/V62__organization_portal.sql"),
                new ClassPathResource("db/migration/V64__academy_invitations.sql")).execute(ds);
        org = UUID.randomUUID();
        db.update("INSERT INTO academy_organization(id,name,kind,seats,status) VALUES(?,?,'ACADEMY',2,'ACTIVE')", org, "Invite Academy");
        account("admin", "admin@example.com", true);
        UUID adminId = db.queryForObject("SELECT id FROM player_account WHERE email='admin@example.com'", UUID.class);
        db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,?, 'ORGANIZATION_ADMIN')", UUID.randomUUID(), org, adminId, "Admin");
    }

    UUID account(String token, String email, boolean verified) {
        UUID id = UUID.randomUUID();
        db.update("INSERT INTO player_account(id,display_name,email,verified) VALUES(?,?,?,?)", id, token, email, verified);
        when(auth.requireBearer(token)).thenReturn(new AuthenticatedPlayer(id, token, token, null));
        return id;
    }

    String invite(String email, String role) {
        return controller.invite("admin", org, new AcademyInvitationController.InviteInput(email, role)).get("token").toString();
    }

    @Test void verifiedStudentAcceptsOnceAndConsumesOneSeat() {
        UUID student = account("student", "student@example.com", true);
        String token = invite("Student@Example.com", "STUDENT");
        Map<String, Object> accepted = controller.accept("student", new AcademyInvitationController.AcceptInput(token));
        assertEquals(true, accepted.get("accepted"));
        assertEquals(1, db.queryForObject("SELECT COUNT(*) FROM academy_member WHERE organization_id=? AND account_id=? AND role='STUDENT'", Integer.class, org, student));
        assertEquals(1, db.queryForObject("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND account_id=?", Integer.class, org, student));
        assertEquals(HttpStatus.GONE, assertThrows(ResponseStatusException.class,
                () -> controller.accept("student", new AcademyInvitationController.AcceptInput(token))).getStatusCode());
    }

    @Test void wrongEmailUnverifiedAccountAndNonAdminAreRejected() {
        account("wrong", "wrong@example.com", true);
        account("unverified", "pending@example.com", false);
        String student = invite("student@example.com", "STUDENT");
        assertEquals(HttpStatus.FORBIDDEN, assertThrows(ResponseStatusException.class,
                () -> controller.accept("wrong", new AcademyInvitationController.AcceptInput(student))).getStatusCode());
        String pending = invite("pending@example.com", "COACH");
        assertEquals(HttpStatus.FORBIDDEN, assertThrows(ResponseStatusException.class,
                () -> controller.accept("unverified", new AcademyInvitationController.AcceptInput(pending))).getStatusCode());
        assertEquals(HttpStatus.FORBIDDEN, assertThrows(ResponseStatusException.class,
                () -> controller.invite("wrong", org, new AcademyInvitationController.InviteInput("x@example.com", "COACH"))).getStatusCode());
    }

    @Test void seatLimitRollsBackStudentMembershipButAllowsCoach() {
        account("existing", "existing@example.com", true);
        db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) SELECT ?,?,?,?,'STUDENT'", UUID.randomUUID(), org,
                db.queryForObject("SELECT id FROM player_account WHERE email='existing@example.com'", UUID.class), "Existing");
        db.update("INSERT INTO academy_student(id,organization_id,name,email,account_id) SELECT ?,?,?,?,id FROM player_account WHERE email='existing@example.com'", UUID.randomUUID(), org, "Existing", "existing@example.com");
        account("second", "second@example.com", true);
        db.update("UPDATE academy_organization SET seats=1 WHERE id=?", org);
        String student = invite("second@example.com", "STUDENT");
        assertEquals(HttpStatus.CONFLICT, assertThrows(ResponseStatusException.class,
                () -> controller.accept("second", new AcademyInvitationController.AcceptInput(student))).getStatusCode());
        assertEquals(0, db.queryForObject("SELECT COUNT(*) FROM academy_member WHERE organization_id=? AND account_id=(SELECT id FROM player_account WHERE email='second@example.com')", Integer.class, org));
        UUID pending = db.queryForObject("SELECT id FROM academy_invitation WHERE organization_id=? AND email='second@example.com' AND status='PENDING'", UUID.class, org);
        controller.revoke("admin", org, pending);
        String coach = invite("second@example.com", "COACH");
        assertEquals(true, controller.accept("second", new AcademyInvitationController.AcceptInput(coach)).get("accepted"));
    }

    @Test void revokePreventsAcceptanceAndRawTokensAreNeverStored() {
        account("coach", "coach@example.com", true);
        Map<String, Object> created = controller.invite("admin", org,
                new AcademyInvitationController.InviteInput("coach@example.com", "COACH"));
        String token = created.get("token").toString();
        assertEquals(0, db.queryForObject("SELECT COUNT(*) FROM academy_invitation WHERE token_hash=?", Integer.class, token));
        controller.revoke("admin", org, UUID.fromString(created.get("id").toString()));
        assertEquals(HttpStatus.GONE, assertThrows(ResponseStatusException.class,
                () -> controller.accept("coach", new AcademyInvitationController.AcceptInput(token))).getStatusCode());
    }
}

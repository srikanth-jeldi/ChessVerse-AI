package com.epitomehub.chessverse.academy;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.time.LocalDate;
import java.util.*;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.*;
import org.springframework.core.io.ClassPathResource;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

@SpringJUnitConfig(AcademyControllerTest.Config.class)
class AcademyControllerTest {
    @Configuration @EnableTransactionManagement
    static class Config {
        @Bean(destroyMethod="close") DataSource dataSource() {
            // Keep physical connections alive: H2 2.4 CHECK IN expressions retain their creation session.
            HikariDataSource pool = new HikariDataSource();
            pool.setJdbcUrl("jdbc:h2:mem:academy;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_UPPER=false");
            pool.setUsername("sa"); pool.setPassword(""); pool.setMaximumPoolSize(1);
            return pool;
        }
        @Bean JdbcTemplate jdbc(DataSource ds) { return new JdbcTemplate(ds); }
        @Bean DataSourceTransactionManager transactionManager(DataSource ds) { return new DataSourceTransactionManager(ds); }
        @Bean PlayerAuthenticationService auth() { return mock(PlayerAuthenticationService.class); }
        @Bean AcademyController controller(JdbcTemplate jdbc, PlayerAuthenticationService auth) {
            return new AcademyController(jdbc,auth,new ObjectMapper(),new AcademyGuidanceService(new ObjectMapper(),false,"","",""));
        }
    }
    @Autowired AcademyController controller;
    @Autowired JdbcTemplate db;
    @Autowired DataSource ds;
    @Autowired PlayerAuthenticationService auth;
    UUID orgA,orgB,adminA,adminB,coachAccount,coachMember,parentAccount,parentMember,studentAccount,studentA,studentB,otherStudent;
    @BeforeEach void setup() {
        reset(auth);
        db.execute("DROP ALL OBJECTS");
        db.execute("CREATE TABLE player_account(id UUID PRIMARY KEY,display_name VARCHAR(100),email VARCHAR(254),verified BOOLEAN DEFAULT TRUE)");
        db.execute("CREATE TABLE computer_game_history(player_id UUID,game_id VARCHAR(80),draft TEXT,created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(player_id,game_id))");
        new ResourceDatabasePopulator(new ClassPathResource("db/migration/V62__organization_portal.sql")).execute(ds);
        orgA=org("Academy A"); orgB=org("School B");
        adminA=account("admin-a");adminB=account("admin-b");coachAccount=account("coach");parentAccount=account("parent");studentAccount=account("student");
        member(orgA,adminA,"ORGANIZATION_ADMIN");member(orgB,adminB,"ORGANIZATION_ADMIN");
        coachMember=member(orgA,coachAccount,"COACH");parentMember=member(orgA,parentAccount,"PARENT");member(orgA,studentAccount,"STUDENT");
        studentA=student(orgA,"Assigned",studentAccount,coachMember);otherStudent=student(orgA,"Unassigned",null,null);studentB=student(orgB,"Secret B",null,null);
        db.update("INSERT INTO academy_parent_link(organization_id,member_id,student_id) VALUES(?,?,?)",orgA,parentMember,studentA);
    }
    UUID org(String name) { UUID id=UUID.randomUUID();db.update("INSERT INTO academy_organization(id,name,kind) VALUES(?,?,'ACADEMY')",id,name);return id; }
    UUID account(String name) {UUID id=UUID.randomUUID();db.update("INSERT INTO player_account(id,display_name,email) VALUES(?,?,?)",id,name,name+"@example.com");when(auth.requireBearer(name)).thenReturn(new AuthenticatedPlayer(id,name,name,null));return id;}
    UUID member(UUID org,UUID account,String role) {UUID id=UUID.randomUUID();db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,?,?)",id,org,account,role,role);return id;}
    UUID student(UUID org,String name,UUID account,UUID coach) {UUID id=UUID.randomUUID();db.update("INSERT INTO academy_student(id,organization_id,name,email,account_id,coach_id) VALUES(?,?,?,?,?,?)",id,org,name,name+"@example.com",account,coach);return id;}
    @SuppressWarnings("unchecked") List<Map<String,Object>> list(Map<String,Object> data,String key) {return (List<Map<String,Object>>)data.get(key);}
    void denied(HttpStatus status,Runnable action) {assertEquals(status,assertThrows(ResponseStatusException.class,action::run).getStatusCode());}
    AcademyController.StudentInput input(String name,UUID batch,UUID coach) {return new AcademyController.StudentInput(name,name+"@example.com",null,batch,coach,true);}

    @Test void foreignTenantIsRejectedEvenWithKnownIdentifier() {
        denied(HttpStatus.FORBIDDEN,()->controller.workspace("admin-a",orgB));
        denied(HttpStatus.NOT_FOUND,()->controller.editStudent("admin-a",orgA,studentB,input("Hacked",null,null)));
        assertEquals("Secret B",db.queryForObject("SELECT name FROM academy_student WHERE id=?",String.class,studentB));
    }
    @Test void coachParentAndStudentOnlySeeTheirOwnScope() {
        for(String token:List.of("coach","parent","student")) {
            var result=controller.workspace(token,orgA);
            assertEquals(List.of(studentA),list(result,"students").stream().map(s->s.get("id")).toList());
            assertTrue(list(result,"invoices").isEmpty());
            assertTrue(list(result,"parentLinks").isEmpty());
        }
        assertEquals(2,list(controller.workspace("admin-a",orgA),"students").size());
    }
    @Test void coachCannotAssignOrReportOnUnassignedOrForeignStudents() {
        for(UUID student:List.of(otherStudent,studentB)) {
            denied(HttpStatus.NOT_FOUND,()->controller.assign("coach",orgA,new AcademyController.AssignmentInput(List.of(student),"Task","PUZZLES","Solve",LocalDate.now())));
            denied(HttpStatus.NOT_FOUND,()->controller.report("coach",orgA,new AcademyController.ReportInput(student,"WEEKLY")));
        }
        assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_assignment",Integer.class));
    }
    @Test void multiStudentAssignmentRollsBackIfAnyStudentIsOutOfScope() {
        denied(HttpStatus.NOT_FOUND,()->controller.assign("coach",orgA,new AcademyController.AssignmentInput(List.of(studentA,otherStudent),"Task","PUZZLES","Solve",LocalDate.now())));
        assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_assignment",Integer.class));
    }
    @Test void parentCannotWriteAndTenantAdminCannotGrantSuperAdmin() {
        denied(HttpStatus.FORBIDDEN,()->controller.addStudent("parent",orgA,input("Injected",null,null)));
        denied(HttpStatus.FORBIDDEN,()->controller.assign("parent",orgA,new AcademyController.AssignmentInput(List.of(studentA),"Task","PUZZLES","Solve",LocalDate.now())));
        denied(HttpStatus.FORBIDDEN,()->controller.platform("admin-a"));
        denied(HttpStatus.FORBIDDEN,()->controller.license("admin-a",orgB,new AcademyController.LicenseInput("Free",500,LocalDate.now(),"ACTIVE","")));
    }
    @Test void foreignCoachOrBatchIsRejectedByServiceAndDatabase() {
        UUID foreignCoach=member(orgB,account("foreign-coach"),"COACH"),batch=UUID.randomUUID();
        db.update("INSERT INTO academy_batch(id,organization_id,name,level,schedule) VALUES(?,?,'B','BEGINNER','Mon')",batch,orgB);
        denied(HttpStatus.BAD_REQUEST,()->controller.addStudent("admin-a",orgA,input("Invalid",batch,null)));
        denied(HttpStatus.BAD_REQUEST,()->controller.addStudent("admin-a",orgA,input("Invalid",null,foreignCoach)));
        assertThrows(DataIntegrityViolationException.class,()->db.update("UPDATE academy_student SET coach_id=? WHERE id=?",foreignCoach,studentA));
        assertThrows(DataIntegrityViolationException.class,()->db.update("UPDATE academy_student SET batch_id=? WHERE id=?",batch,studentA));
    }
    @Test void seatLimitAndAtomicImportAreEnforced() {
        db.update("UPDATE academy_organization SET seats=3 WHERE id=?",orgA);
        denied(HttpStatus.CONFLICT,()->controller.importStudents("admin-a",orgA,new AcademyController.ImportInput(List.of(input("New1",null,null),input("New2",null,null)))));
        assertEquals(2,db.queryForObject("SELECT COUNT(*) FROM academy_student WHERE organization_id=?",Integer.class,orgA));
    }
    @Test void duplicateImportRollsBackAndAccountsNeedMembership() {
        denied(HttpStatus.CONFLICT,()->controller.importStudents("admin-a",orgA,new AcademyController.ImportInput(List.of(input("Same",null,null),input("Same",null,null)))));
        assertEquals(2,db.queryForObject("SELECT COUNT(*) FROM academy_student WHERE organization_id=?",Integer.class,orgA));
        denied(HttpStatus.BAD_REQUEST,()->controller.addStudent("admin-a",orgA,new AcademyController.StudentInput("Other","other@example.com",adminB,null,null,true)));
    }
    @Test void suspendedOrganizationAndInactiveMembershipLoseAccess() {
        db.update("UPDATE academy_member SET active=FALSE WHERE id=?",coachMember);
        denied(HttpStatus.FORBIDDEN,()->controller.workspace("coach",orgA));
        db.update("UPDATE academy_organization SET status='SUSPENDED' WHERE id=?",orgA);
        denied(HttpStatus.FORBIDDEN,()->controller.workspace("admin-a",orgA));
    }
    @Test void consumerGamesArePrivateUntilStudentSharesOwnGame() {
        db.update("INSERT INTO computer_game_history(player_id,game_id,draft) VALUES(?,'mine','{\"id\":\"mine\"}')",studentAccount);
        db.update("INSERT INTO computer_game_history(player_id,game_id,draft) VALUES(?,'theirs','{\"id\":\"theirs\"}')",adminB);
        assertTrue(list(controller.workspace("admin-a",orgA),"games").isEmpty());
        assertEquals(List.of("mine"),controller.shareableGames("student",orgA).stream().map(g->g.get("id")).toList());
        denied(HttpStatus.FORBIDDEN,()->controller.shareableGames("coach",orgA));
        denied(HttpStatus.NOT_FOUND,()->controller.shareGame("student",orgA,"theirs"));
        denied(HttpStatus.FORBIDDEN,()->controller.shareGame("coach",orgA,"mine"));
        controller.shareGame("student",orgA,"mine");controller.shareGame("student",orgA,"mine");
        var games=list(controller.workspace("coach",orgA),"games");assertEquals(1,games.size());
        UUID game=(UUID)games.getFirst().get("id");
        assertTrue(controller.game("parent",orgA,game).toString().contains("mine"));
        denied(HttpStatus.FORBIDDEN,()->controller.game("admin-b",orgA,game));
        denied(HttpStatus.NOT_FOUND,()->controller.game("admin-b",orgB,game));
    }
    @Test void reportsRemainScopedAndRetainSnapshots() {
        controller.observe("coach",orgA,new AcademyController.ObservationInput(studentA,LocalDate.now(),1200,78,60,12,3,2,1,4,10,2,"Practice opposition"));
        controller.report("coach",orgA,new AcademyController.ReportInput(studentA,"WEEKLY"));
        controller.report("admin-a",orgA,new AcademyController.ReportInput(otherStudent,"MONTHLY"));
        var reports=list(controller.workspace("parent",orgA),"reports");assertEquals(1,reports.size());
        assertTrue(reports.getFirst().get("summary").toString().contains("Practice opposition"));
        assertTrue(list(controller.workspace("admin-b",orgB),"reports").isEmpty());
    }
    @Test void parentUnlinkRevokesAccessImmediately() {
        controller.removeParent("admin-a",orgA,parentMember,studentA);
        assertTrue(list(controller.workspace("parent",orgA),"students").isEmpty());
    }
    @Test void aiGuidanceRespectsCoachScopeAndDailyQuota() {
        denied(HttpStatus.NOT_FOUND,()->controller.guidance("coach",orgA,otherStudent));
        denied(HttpStatus.FORBIDDEN,()->controller.guidance("parent",orgA,studentA));
        for(int i=0;i<10;i++) assertEquals("RULES",controller.guidance("coach",orgA,studentA).source());
        denied(HttpStatus.TOO_MANY_REQUESTS,()->controller.guidance("coach",orgA,studentA));
    }
    @Test void cannotRemoveOwnAdminOrDemoteAssignedCoach() {
        denied(HttpStatus.CONFLICT,()->controller.member("admin-a",orgA,new AcademyController.MemberInput("admin-a@example.com","Admin","COACH",true)));
        denied(HttpStatus.CONFLICT,()->controller.member("admin-a",orgA,new AcademyController.MemberInput("coach@example.com","Coach","PARENT",true)));
    }
    @Test void seatApprovalIsIdempotentAndPlatformCannotReadStudentsImplicitly() {
        UUID platform=account("platform");db.update("INSERT INTO academy_super_admin(account_id) VALUES(?)",platform);
        controller.seats("admin-a",orgA,new AcademyController.SeatInput(5));
        UUID request=db.queryForObject("SELECT id FROM academy_seat_request",UUID.class);
        controller.approveSeats("platform",request);
        denied(HttpStatus.CONFLICT,()->controller.approveSeats("platform",request));
        assertEquals(30,db.queryForObject("SELECT seats FROM academy_organization WHERE id=?",Integer.class,orgA));
        denied(HttpStatus.FORBIDDEN,()->controller.workspace("platform",orgA));
        assertEquals(2,list(controller.platform("platform"),"organizations").size());
    }
}

package com.epitomehub.chessverse.academy;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import com.epitomehub.chessverse.auth.*;
import com.zaxxer.hikari.HikariDataSource;
import java.time.LocalDate;
import java.util.UUID;
import javax.sql.DataSource;
import org.junit.jupiter.api.*;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.web.server.ResponseStatusException;

class AcademyOperationsControllerTest {
    HikariDataSource ds; JdbcTemplate db; PlayerAuthenticationService auth; AcademyOperationsController api;
    UUID org,adminMember,coachMember,student;
    @BeforeEach void setup(){ds=new HikariDataSource();ds.setJdbcUrl("jdbc:h2:mem:ops"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_UPPER=false");db=new JdbcTemplate(ds);auth=mock(PlayerAuthenticationService.class);api=new AcademyOperationsController(db,auth);
        db.execute("CREATE TABLE player_account(id UUID PRIMARY KEY,display_name VARCHAR(100),email VARCHAR(254),verified BOOLEAN)");
        new ResourceDatabasePopulator(new ClassPathResource("db/migration/V62__organization_portal.sql"),new ClassPathResource("db/migration/V63__academy_self_service.sql"),new ClassPathResource("db/migration/V64__academy_invitations.sql"),new ClassPathResource("db/migration/V65__academy_operations.sql")).execute(ds);
        org=UUID.randomUUID();db.update("INSERT INTO academy_organization(id,name,kind,seats,status,renewal_date) VALUES(?,?,'ACADEMY',10,'ACTIVE',?)",org,"Ops",LocalDate.now().plusMonths(1));
        adminMember=member("admin", "ORGANIZATION_ADMIN");coachMember=member("coach","COACH");UUID learnerAccount=account("student");memberFor(learnerAccount,"Student","STUDENT");student=UUID.randomUUID();db.update("INSERT INTO academy_student(id,organization_id,name,email,account_id,coach_id) VALUES(?,?,?,?,?,?)",student,org,"Student","student@example.com",learnerAccount,coachMember);
    }
    UUID account(String token){UUID id=UUID.randomUUID();db.update("INSERT INTO player_account VALUES(?,?,?,TRUE)",id,token,token+"@example.com");when(auth.requireBearer(token)).thenReturn(new AuthenticatedPlayer(id,token,token,null));return id;}
    UUID member(String token,String role){return memberFor(account(token),token,role);} UUID memberFor(UUID account,String name,String role){UUID id=UUID.randomUUID();db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,?,?)",id,org,account,name,role);return id;}
    @AfterEach void close(){ds.close();}

    @Test void announcementsAttendancePreferencesAndAuditAreTenantScoped(){
        UUID announcement=UUID.fromString(api.announce("coach",org,new AcademyOperationsController.Announcement("STUDENT","Class","Bring your board",LocalDate.now().plusDays(1))).get("id").toString());
        assertEquals(1,api.announcements("student",org).size());
        api.attendance("coach",org,new AcademyOperationsController.Attendance(student,LocalDate.now(),"PRESENT","On time"));
        assertEquals(1,api.attendance("student",org,LocalDate.now(),LocalDate.now()).size());
        api.preferences("student",org,new AcademyOperationsController.Preferences(false,true,true,false,true));
        assertEquals(false,api.preferences("student",org).get("announcements"));
        assertTrue(api.audit("admin",org).size()>=2);
        api.deleteAnnouncement("admin",org,announcement);assertTrue(api.announcements("student",org).isEmpty());
    }

    @Test void roleAndMemberLifecycleGuardsPreventPrivilegeAndOrphans(){
        assertEquals(HttpStatus.FORBIDDEN,assertThrows(ResponseStatusException.class,()->api.audit("coach",org)).getStatusCode());
        assertEquals(HttpStatus.CONFLICT,assertThrows(ResponseStatusException.class,()->api.deactivate("admin",org,adminMember)).getStatusCode());
        assertEquals(HttpStatus.CONFLICT,assertThrows(ResponseStatusException.class,()->api.deactivate("admin",org,coachMember)).getStatusCode());
        db.update("UPDATE academy_student SET coach_id=NULL WHERE id=?",student);api.deactivate("admin",org,coachMember);
        assertEquals(false,db.queryForObject("SELECT active FROM academy_member WHERE id=?",Boolean.class,coachMember));
    }

    @Test void downgradeCannotUndercutSeatsAndNoPaymentIsTaken(){
        assertEquals(HttpStatus.CONFLICT,assertThrows(ResponseStatusException.class,()->api.subscription("admin",org,new AcademyOperationsController.Subscription("DOWNGRADE","STARTER",0,LocalDate.now().plusDays(1)))).getStatusCode());
        var result=api.subscription("admin",org,new AcademyOperationsController.Subscription("CANCEL",null,null,LocalDate.now().plusMonths(1)));
        assertEquals(false,result.get("paymentRequired"));assertEquals(1,api.subscriptions("admin",org).size());
        assertNotNull(api.schedule("coach",org,new AcademyOperationsController.ReportSchedule(student,"WEEKLY",true,LocalDate.now().plusDays(7))).get("id"));
    }
    @Test void approvedSubscriptionChangesApplyOnEffectiveDate(){
        UUID upgrade=UUID.randomUUID();db.update("INSERT INTO academy_subscription_request(id,organization_id,requested_by,action,plan_code,seats,effective_on,status) VALUES(?,?,?,?,?,?,?,'APPROVED')",upgrade,org,adminMember,"UPGRADE","GROWTH",25,LocalDate.now());
        new AcademySubscriptionProcessor(db).applyDue();
        assertEquals("GROWTH",db.queryForObject("SELECT plan FROM academy_organization WHERE id=?",String.class,org));
        assertEquals(25,db.queryForObject("SELECT seats FROM academy_organization WHERE id=?",Integer.class,org));
        assertEquals("APPLIED",db.queryForObject("SELECT status FROM academy_subscription_request WHERE id=?",String.class,upgrade));
        UUID cancel=UUID.randomUUID();db.update("INSERT INTO academy_subscription_request(id,organization_id,requested_by,action,effective_on,status) VALUES(?,?,?,?,?,'APPROVED')",cancel,org,adminMember,"CANCEL",LocalDate.now());
        new AcademySubscriptionProcessor(db).applyDue();
        assertEquals("SUSPENDED",db.queryForObject("SELECT status FROM academy_organization WHERE id=?",String.class,org));
    }
    @Test void renewalReminderIsSentOncePerRenewalDate(){
        db.update("UPDATE academy_organization SET renewal_date=? WHERE id=?",LocalDate.now().plusDays(7),org);
        AcademyBillingMailService mail=mock(AcademyBillingMailService.class);when(mail.renewal(anyString(),anyString(),anyString(),eq(7))).thenReturn(true);
        AcademyRenewalNotifier notifier=new AcademyRenewalNotifier(db,mail);notifier.notify(7);notifier.notify(7);
        verify(mail,times(1)).renewal(eq("admin@example.com"),eq("Ops"),eq(LocalDate.now().plusDays(7).toString()),eq(7));
        assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_billing_notice",Integer.class));
    }
}

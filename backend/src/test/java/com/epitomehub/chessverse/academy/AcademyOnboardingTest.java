package com.epitomehub.chessverse.academy;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import com.epitomehub.chessverse.auth.*;
import com.zaxxer.hikari.HikariDataSource;
import java.time.LocalDate;
import java.util.*;
import javax.sql.DataSource;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.*;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

@SpringJUnitConfig(AcademyOnboardingTest.Config.class)
class AcademyOnboardingTest {
 @Configuration @EnableTransactionManagement static class Config {
  @Bean(destroyMethod="close") DataSource ds(){var p=new HikariDataSource();p.setJdbcUrl("jdbc:h2:mem:academy_signup;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_UPPER=false");p.setUsername("sa");p.setMaximumPoolSize(1);return p;}
  @Bean JdbcTemplate db(DataSource ds){return new JdbcTemplate(ds);}
  @Bean DataSourceTransactionManager transactionManager(DataSource ds){return new DataSourceTransactionManager(ds);}
  @Bean PlayerAuthenticationService auth(){return mock(PlayerAuthenticationService.class);}
  @Bean AcademyPaymentGateway gateway(){return mock(AcademyPaymentGateway.class);}
  @Bean AcademyOnboardingController controller(JdbcTemplate db,PlayerAuthenticationService auth,AcademyPaymentGateway g){return new AcademyOnboardingController(db,auth,g,new ObjectMapper());}
 }
 @Autowired DataSource ds;@Autowired JdbcTemplate db;@Autowired PlayerAuthenticationService auth;@Autowired AcademyPaymentGateway gateway;@Autowired AcademyOnboardingController api;
 UUID account;
 @BeforeEach void setup(){reset(auth,gateway);db.execute("DROP ALL OBJECTS");db.execute("CREATE TABLE player_account(id UUID PRIMARY KEY,display_name VARCHAR(100),verified BOOLEAN DEFAULT TRUE)");new ResourceDatabasePopulator(new ClassPathResource("db/migration/V62__organization_portal.sql"),new ClassPathResource("db/migration/V63__academy_self_service.sql")).execute(ds);account=UUID.randomUUID();db.update("INSERT INTO player_account(id,display_name) VALUES(?,'Owner')",account);when(auth.requireBearer("owner")).thenReturn(new AuthenticatedPlayer(account,"owner","Owner",null));when(gateway.available()).thenReturn(true);when(gateway.publicKey()).thenReturn("rzp_live_public");when(gateway.createOrder(anyString(),anyLong(),anyString())).thenReturn(new AcademyPaymentGateway.ProviderOrder("order_abc","rzp_live_public"));when(gateway.validPaymentSignature(anyString(),anyString(),anyString())).thenReturn(true);db.update("UPDATE academy_plan_price SET enabled=TRUE");db.update("UPDATE academy_billing_config SET approved=TRUE,sac='998319'");}
 void enroll(String country){api.enroll("owner",new AcademyOnboardingController.Enrollment("Kings","ACADEMY",country));api.billing("owner",new AcademyOnboardingController.BillingDetails("Kings","billing@example.com","Road 1","Hyderabad","Telangana","500072","36",""));}
 Map<?,?> order(){return (Map<?,?>)api.order("owner",new AcademyOnboardingController.Plan("STARTER","",117882L));}
 AcademyOnboardingController.Verification verified(Map<?,?> o){return new AcademyOnboardingController.Verification((UUID)o.get("id"),"pay_abc","a".repeat(64));}
 @Test void registrationDoesNotGrantMembershipAndIsIdempotent(){enroll("IN");api.enroll("owner",new AcademyOnboardingController.Enrollment("Duplicate","SCHOOL","US"));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_enrollment",Integer.class));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_member",Integer.class));}
 @Test void capturedPaymentActivatesOnceAndCreatesImmutableGstInvoice(){enroll("IN");var o=order();assertEquals(117882L,o.get("amount"));api.verify("owner",verified(o));api.verify("owner",verified(o));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_organization",Integer.class));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_invoice",Integer.class));assertEquals("ORGANIZATION_ADMIN",db.queryForObject("SELECT role FROM academy_member",String.class));db.update("UPDATE academy_billing_config SET legal_name='Changed'");var invoice=(Map<?,?>)api.invoice("owner",(UUID)o.get("id"));assertTrue(invoice.get("billing").toString().contains("EPITOMEHUB TECHNOLOGIES PRIVATE LIMITED"));verify(gateway,times(1)).verifyCapturedPayment("pay_abc","order_abc",117882L,"INR");}
 @Test void signatureFailureNeverActivates(){enroll("IN");var o=order();when(gateway.validPaymentSignature(anyString(),anyString(),anyString())).thenReturn(false);assertThrows(ResponseStatusException.class,()->api.verify("owner",verified(o)));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_organization",Integer.class));}
 @Test void uncapturedPaymentRollsBackActivation(){enroll("IN");var o=order();doThrow(new IllegalStateException("not captured")).when(gateway).verifyCapturedPayment(anyString(),anyString(),anyLong(),anyString());assertThrows(IllegalStateException.class,()->api.verify("owner",verified(o)));assertEquals("PENDING",db.queryForObject("SELECT status FROM academy_checkout",String.class));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_member",Integer.class));}
 @Test void foreignAccountCannotVerifyOrReadInvoice(){enroll("IN");var o=order();UUID other=UUID.randomUUID();db.update("INSERT INTO player_account(id,display_name) VALUES(?,'Other')",other);when(auth.requireBearer("other")).thenReturn(new AuthenticatedPlayer(other,"other","Other",null));assertThrows(ResponseStatusException.class,()->api.verify("other",verified(o)));assertThrows(ResponseStatusException.class,()->api.invoice("other",(UUID)o.get("id")));}
 @Test void couponDiscountComesBeforeGstAndIsReservedOnce(){enroll("IN");db.update("UPDATE academy_coupon SET max_orders=1,expires_on=?,enabled=TRUE WHERE code='WELCOME20'",LocalDate.now().plusDays(30));var input=new AcademyOnboardingController.Plan("STARTER","welcome20",94306L);var quote=(Map<?,?>)api.quote("owner",input);assertEquals(79920L,quote.get("taxable"));assertEquals(7193L,quote.get("cgst"));assertEquals(94306L,quote.get("total"));var o=(Map<?,?>)api.order("owner",input);assertEquals(o,api.order("owner",input));verify(gateway,times(1)).createOrder(anyString(),eq(94306L),eq("INR"));assertThrows(ResponseStatusException.class,()->api.order("owner",new AcademyOnboardingController.Plan("GROWTH","")));}
 @Test void internationalCurrencyIsUsdButExportTaxIsNotAssumed(){enroll("US");assertEquals("USD",((Map<?,?>)api.plans("US")).get("currency"));assertThrows(ResponseStatusException.class,this::order);verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void sellerTaxSetupBlocksPaymentUntilApproved(){enroll("IN");db.update("UPDATE academy_billing_config SET approved=FALSE");assertThrows(ResponseStatusException.class,this::order);verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void unverifiedAccountCannotEnroll(){db.update("UPDATE player_account SET verified=FALSE");assertThrows(ResponseStatusException.class,()->enroll("IN"));}
 @Test void webhookSignatureAndReconciliationDoNotTrustBrowser(){enroll("IN");var o=order();assertThrows(ResponseStatusException.class,()->api.webhook("{}","bad"));when(gateway.findCapturedPayment("order_abc",117882L,"INR")).thenReturn("pay_abc");assertEquals(true,((Map<?,?>)api.reconcile("owner",(UUID)o.get("id"))).get("active"));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_invoice_document",Integer.class));}
 @Test void interstateTaxUsesIgstOnly(){enroll("IN");api.billing("owner",new AcademyOnboardingController.BillingDetails("Kings","bill@example.com","Road","Bengaluru","Karnataka","560001","29",""));var q=(Map<?,?>)api.quote("owner",new AcademyOnboardingController.Plan("STARTER","",117882L));assertEquals(0L,q.get("cgst"));assertEquals(17982L,q.get("igst"));}
 @Test void staleOrClientInventedTotalCannotCreateOrder(){enroll("IN");assertThrows(ResponseStatusException.class,()->api.order("owner",new AcademyOnboardingController.Plan("STARTER","",1L)));verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void expiredCouponsAreRejectedBeforePayment(){enroll("IN");db.update("UPDATE academy_coupon SET enabled=TRUE,expires_on=?",LocalDate.now().minusDays(1));assertThrows(ResponseStatusException.class,()->api.quote("owner",new AcademyOnboardingController.Plan("STARTER","WELCOME20")));verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
}

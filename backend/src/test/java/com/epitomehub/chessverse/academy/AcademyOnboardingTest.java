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
  @Bean AcademyBillingMailService mail(){return mock(AcademyBillingMailService.class);}
  @Bean AcademyOnboardingController controller(JdbcTemplate db,PlayerAuthenticationService auth,AcademyPaymentGateway g,AcademyBillingMailService mail){return new AcademyOnboardingController(db,auth,g,new ObjectMapper(),mail);}
 }
 @Autowired DataSource ds;@Autowired JdbcTemplate db;@Autowired PlayerAuthenticationService auth;@Autowired AcademyPaymentGateway gateway;@Autowired AcademyBillingMailService mail;@Autowired AcademyOnboardingController api;
 UUID account;
 @BeforeEach void resetMail(){reset(mail);}
 @BeforeEach void setup(){reset(auth,gateway);db.execute("DROP ALL OBJECTS");db.execute("CREATE TABLE player_account(id UUID PRIMARY KEY,display_name VARCHAR(100),email VARCHAR(254),verified BOOLEAN DEFAULT TRUE)");new ResourceDatabasePopulator(new ClassPathResource("db/migration/V62__organization_portal.sql"),new ClassPathResource("db/migration/V63__academy_self_service.sql"),new ClassPathResource("db/migration/V64__academy_invitations.sql"),new ClassPathResource("db/migration/V65__academy_operations.sql"),new ClassPathResource("db/migration/V75__academy_trial_and_first_payment_offer.sql"),new ClassPathResource("db/migration/V76__academy_annual_pricing.sql"),new ClassPathResource("db/migration/V77__academy_trial_student_limit.sql"),new ClassPathResource("db/migration/V79__academy_usd_pricing.sql"),new ClassPathResource("db/migration/V80__academy_payment_links.sql")).execute(ds);installRegionalPrices();account=UUID.randomUUID();db.update("INSERT INTO player_account(id,display_name,email) VALUES(?,'Owner','owner@example.com')",account);when(auth.requireBearer("owner")).thenReturn(new AuthenticatedPlayer(account,"owner","Owner",null));when(gateway.available()).thenReturn(true);when(gateway.publicKey()).thenReturn("rzp_live_public");when(gateway.createOrder(anyString(),anyLong(),anyString())).thenReturn(new AcademyPaymentGateway.ProviderOrder("order_abc","rzp_live_public"));when(gateway.validPaymentSignature(anyString(),anyString(),anyString())).thenReturn(true);db.update("UPDATE academy_plan_price SET enabled=TRUE");db.update("UPDATE academy_billing_config SET approved=TRUE,sac='998319'");}
 void installRegionalPrices(){db.execute("ALTER TABLE academy_plan_price DROP CONSTRAINT CONSTRAINT_F9");db.execute("ALTER TABLE academy_plan_price ADD CONSTRAINT academy_plan_price_currency_check CHECK(currency IN ('INR','USD','EUR','GBP'))");db.update("INSERT INTO academy_plan_price(plan_code,name,seats,amount_minor,annual_amount_minor,currency,enabled) VALUES ('STARTER','Starter Academy',25,1799,17999,'EUR',TRUE),('GROWTH','Growth Academy',60,4499,44999,'EUR',TRUE),('SCHOOL','Elite Academy',300,10999,109999,'EUR',TRUE),('STARTER','Starter Academy',25,1499,14999,'GBP',TRUE),('GROWTH','Growth Academy',60,3999,39999,'GBP',TRUE),('SCHOOL','Elite Academy',300,9999,99999,'GBP',TRUE)");db.update("UPDATE academy_plan_price SET annual_amount_minor=CASE plan_code WHEN 'STARTER' THEN 19000 WHEN 'GROWTH' THEN 49000 WHEN 'SCHOOL' THEN 119000 END WHERE currency='USD'");}
 void enroll(String country){api.enroll("owner",new AcademyOnboardingController.Enrollment("Kings","ACADEMY",country));api.billing("owner",new AcademyOnboardingController.BillingDetails("Kings","billing@example.com","Road 1","Hyderabad","Telangana","500072","36",""));}
 Map<?,?> order(){return (Map<?,?>)api.order("owner",new AcademyOnboardingController.Plan("STARTER","",176882L));}
 AcademyOnboardingController.Verification verified(Map<?,?> o){return new AcademyOnboardingController.Verification((UUID)o.get("id"),"pay_abc","a".repeat(64));}
 @Test void registrationDoesNotGrantMembershipAndIsIdempotent(){enroll("IN");api.enroll("owner",new AcademyOnboardingController.Enrollment("Duplicate","SCHOOL","US"));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_enrollment",Integer.class));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_member",Integer.class));}
 @Test void capturedPaymentActivatesOnceAndCreatesImmutableGstInvoice(){clearInvocations(mail);when(mail.invoice(anyString(),anyString(),anyString(),anyString())).thenReturn(true);enroll("IN");var o=order();assertEquals(176882L,o.get("amount"));api.verify("owner",verified(o));api.verify("owner",verified(o));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_organization",Integer.class));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_invoice",Integer.class));assertNotNull(db.queryForObject("SELECT invoice_emailed_at FROM academy_checkout",java.sql.Timestamp.class));assertEquals("ORGANIZATION_ADMIN",db.queryForObject("SELECT role FROM academy_member",String.class));db.update("UPDATE academy_billing_config SET legal_name='Changed'");var invoice=(Map<?,?>)api.invoice("owner",(UUID)o.get("id"));assertTrue(invoice.get("billing").toString().contains("EPITOMEHUB TECHNOLOGIES PRIVATE LIMITED"));verify(mail,times(1)).invoice(eq("owner@example.com"),eq("Kings"),anyString(),anyString());verify(gateway,times(1)).verifyCapturedPayment("pay_abc","order_abc",176882L,"INR");}
 @Test void signatureFailureNeverActivates(){enroll("IN");var o=order();when(gateway.validPaymentSignature(anyString(),anyString(),anyString())).thenReturn(false);assertThrows(ResponseStatusException.class,()->api.verify("owner",verified(o)));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_organization",Integer.class));}
 @Test void uncapturedPaymentRollsBackActivation(){enroll("IN");var o=order();doThrow(new IllegalStateException("not captured")).when(gateway).verifyCapturedPayment(anyString(),anyString(),anyLong(),anyString());assertThrows(IllegalStateException.class,()->api.verify("owner",verified(o)));assertEquals("PENDING",db.queryForObject("SELECT status FROM academy_checkout",String.class));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_member",Integer.class));}
 @Test void foreignAccountCannotVerifyOrReadInvoice(){enroll("IN");var o=order();UUID other=UUID.randomUUID();db.update("INSERT INTO player_account(id,display_name) VALUES(?,'Other')",other);when(auth.requireBearer("other")).thenReturn(new AuthenticatedPlayer(other,"other","Other",null));assertThrows(ResponseStatusException.class,()->api.verify("other",verified(o)));assertThrows(ResponseStatusException.class,()->api.invoice("other",(UUID)o.get("id")));}
 @Test void couponDiscountComesBeforeGstAndIsReservedOnce(){enroll("IN");db.update("UPDATE academy_coupon SET max_orders=1,expires_on=?,enabled=TRUE WHERE code='WELCOME20'",LocalDate.now().plusDays(30));var input=new AcademyOnboardingController.Plan("STARTER","welcome20",141506L);var quote=(Map<?,?>)api.quote("owner",input);assertEquals(119920L,quote.get("taxable"));assertEquals(10793L,quote.get("cgst"));assertEquals(141506L,quote.get("total"));var o=(Map<?,?>)api.order("owner",input);assertEquals(o,api.order("owner",input));verify(gateway,times(1)).createOrder(anyString(),eq(141506L),eq("INR"));assertThrows(ResponseStatusException.class,()->api.order("owner",new AcademyOnboardingController.Plan("GROWTH","")));}
 @Test void regionalCatalogUsesLocalCurrenciesAndKeepsInrPrices(){
  for(var region:Map.of("US","USD","AU","USD","AE","USD","GB","GBP","DE","EUR").entrySet()){
   var catalog=(Map<?,?>)api.plans(region.getKey());assertEquals(region.getValue(),catalog.get("currency"));
   assertEquals(false,catalog.get("checkoutAvailable"));
   var plans=(List<Map<String,Object>>)catalog.get("plans");
   assertEquals(List.of("Starter Academy","Growth Academy","Elite Academy"),plans.stream().map(p->p.get("name")).toList());
   assertEquals(List.of(25,60,300),plans.stream().map(p->((Number)p.get("seats")).intValue()).toList());
   assertTrue(plans.stream().allMatch(p->p.get("annual_amount_minor")!=null));
  }
  var india=(Map<?,?>)api.plans("IN");assertEquals("INR",india.get("currency"));
  var plans=(List<Map<String,Object>>)india.get("plans");
  assertEquals(List.of(149900L,399900L,999900L),plans.stream().map(p->((Number)p.get("amount_minor")).longValue()).toList());
  assertEquals(List.of(1499900L,3999900L,9999900L),plans.stream().map(p->((Number)p.get("annual_amount_minor")).longValue()).toList());
 }
 @Test void internationalCurrencyIsUsdButExportTaxIsNotAssumed(){enroll("US");assertEquals("USD",((Map<?,?>)api.plans("US")).get("currency"));assertThrows(ResponseStatusException.class,this::order);verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void sellerTaxSetupBlocksPaymentUntilApproved(){enroll("IN");db.update("UPDATE academy_billing_config SET approved=FALSE");assertThrows(ResponseStatusException.class,this::order);verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void unverifiedAccountCannotEnroll(){db.update("UPDATE player_account SET verified=FALSE");assertThrows(ResponseStatusException.class,()->enroll("IN"));}
 @Test void webhookSignatureAndReconciliationDoNotTrustBrowser(){enroll("IN");var o=order();assertThrows(ResponseStatusException.class,()->api.webhook("{}","bad"));when(gateway.findCapturedPayment("order_abc",176882L,"INR")).thenReturn("pay_abc");assertEquals(true,((Map<?,?>)api.reconcile("owner",(UUID)o.get("id"))).get("active"));assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_invoice_document",Integer.class));}
 @Test void capturedWebhookIsIdempotentAndCreatesOneInvoice(){enroll("IN");order();when(gateway.validWebhookSignature(anyString(),eq("valid"))).thenReturn(true);String body="{\"event\":\"payment.captured\",\"payload\":{\"payment\":{\"entity\":{\"order_id\":\"order_abc\",\"id\":\"pay_webhook\"}}}}";api.webhook(body,"valid");api.webhook(body,"valid");assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_invoice",Integer.class));assertEquals("PAID",db.queryForObject("SELECT status FROM academy_checkout",String.class));verify(gateway,times(1)).verifyCapturedPayment("pay_webhook","order_abc",176882L,"INR");}
 @Test void failedWebhookMarksCheckoutRetryableWithoutGrantingAccess(){clearInvocations(mail);when(mail.failed(anyString(),anyString(),anyString())).thenReturn(true);enroll("IN");order();when(gateway.validWebhookSignature(anyString(),eq("valid"))).thenReturn(true);String body="{\"event\":\"payment.failed\",\"payload\":{\"payment\":{\"entity\":{\"order_id\":\"order_abc\",\"error_description\":\"Bank declined\"}}}}";api.webhook(body,"valid");api.webhook(body,"valid");assertEquals("PENDING",db.queryForObject("SELECT status FROM academy_checkout",String.class));assertEquals("Bank declined",db.queryForObject("SELECT failure_reason FROM academy_checkout",String.class));assertNotNull(db.queryForObject("SELECT failed_at FROM academy_checkout",java.sql.Timestamp.class));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_member",Integer.class));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_invoice",Integer.class));verify(mail,times(1)).failed("owner@example.com","Kings","Bank declined");}
 @Test void interstateTaxUsesIgstOnly(){enroll("IN");api.billing("owner",new AcademyOnboardingController.BillingDetails("Kings","bill@example.com","Road","Bengaluru","Karnataka","560001","29",""));var q=(Map<?,?>)api.quote("owner",new AcademyOnboardingController.Plan("STARTER","",176882L));assertEquals(0L,q.get("cgst"));assertEquals(26982L,q.get("igst"));}
 @Test void staleOrClientInventedTotalCannotCreateOrder(){enroll("IN");assertThrows(ResponseStatusException.class,()->api.order("owner",new AcademyOnboardingController.Plan("STARTER","",1L)));verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void expiredCouponsAreRejectedBeforePayment(){enroll("IN");db.update("UPDATE academy_coupon SET enabled=TRUE,expires_on=?",LocalDate.now().minusDays(1));assertThrows(ResponseStatusException.class,()->api.quote("owner",new AcademyOnboardingController.Plan("STARTER","WELCOME20")));verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void trialIsFreeAndCannotBeRestarted(){enroll("IN");api.trial("owner");assertEquals(15,db.queryForObject("SELECT seats FROM academy_organization",Integer.class));assertEquals(LocalDate.now().plusDays(7),db.queryForObject("SELECT renewal_date FROM academy_organization",LocalDate.class));api.trial("owner");assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_organization",Integer.class));assertEquals(0,db.queryForObject("SELECT COUNT(*) FROM academy_invoice",Integer.class));verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void first100IsFixedAndCannotApplyOnRenewal(){enroll("IN");var input=new AcademyOnboardingController.Plan("STARTER","FIRST100",165082L);var q=(Map<?,?>)api.quote("owner",input);assertEquals(10000L,q.get("discount"));assertEquals(165082L,q.get("total"));var o=(Map<?,?>)api.order("owner",input);api.verify("owner",verified(o));assertThrows(ResponseStatusException.class,()->api.quote("owner",input));}
 @Test void trialUpgradeRetainsOrganization(){enroll("IN");api.trial("owner");UUID org=db.queryForObject("SELECT id FROM academy_organization",UUID.class);var o=order();api.verify("owner",verified(o));assertEquals(org,db.queryForObject("SELECT id FROM academy_organization",UUID.class));assertEquals("Starter Academy",db.queryForObject("SELECT plan FROM academy_organization",String.class));}
 @Test void starterAndTrialEnforceOneCoach(){enroll("IN");api.trial("owner");UUID org=db.queryForObject("SELECT id FROM academy_organization",UUID.class);UUID first=UUID.randomUUID();UUID second=UUID.randomUUID();db.update("INSERT INTO player_account(id,display_name) VALUES(?,'Coach')",first);db.update("INSERT INTO player_account(id,display_name) VALUES(?,'Coach2')",second);AcademyCoachLimits.adding(db,org,first);db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,'Coach','COACH')",UUID.randomUUID(),org,first);assertThrows(ResponseStatusException.class,()->AcademyCoachLimits.adding(db,org,second));AcademyCoachLimits.adding(db,org,first);}

 @Test void annualPaymentSnapshotsTwelveMonthsAndCannotSwitchPendingPeriod(){
  enroll("IN");var input=new AcademyOnboardingController.Plan("STARTER","FIRST100",1758082L,"YEARLY");
  var q=(Map<?,?>)api.quote("owner",input);assertEquals(1499900L,q.get("subtotal"));assertEquals(10000L,q.get("discount"));assertEquals(12,q.get("billingMonths"));
  var o=(Map<?,?>)api.order("owner",input);assertEquals(12,o.get("billingMonths"));
  assertThrows(ResponseStatusException.class,()->api.order("owner",new AcademyOnboardingController.Plan("STARTER","FIRST100",1758082L,"MONTHLY")));
  db.update("UPDATE academy_plan_price SET annual_amount_minor=2000000,name='Changed',seats=1 WHERE plan_code='STARTER' AND currency='INR'");
  api.verify("owner",verified(o));assertEquals(LocalDate.now().plusMonths(12),db.queryForObject("SELECT renewal_date FROM academy_organization",LocalDate.class));
  assertEquals(25,db.queryForObject("SELECT seats FROM academy_organization",Integer.class));
  var invoice=(Map<?,?>)api.invoice("owner",(UUID)o.get("id"));assertEquals(12,invoice.get("billingMonths"));assertEquals("Starter Academy",invoice.get("plan"));
 }
 @Test void activePaidPlanBlocksQuoteBeforeGatewayAndExplainsRenewalDate(){
  enroll("IN");var paid=order();api.verify("owner",verified(paid));clearInvocations(gateway);
  var state=(Map<?,?>)api.status("owner");assertTrue(state.get("checkoutBlockedReason").toString().contains(LocalDate.now().plusMonths(1).toString()));
  assertThrows(ResponseStatusException.class,()->api.quote("owner",new AcademyOnboardingController.Plan("STARTER","")));
  assertThrows(ResponseStatusException.class,this::order);verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());
  db.update("UPDATE academy_organization SET renewal_date=?",LocalDate.now());
  assertEquals("",((Map<?,?>)api.status("owner")).get("checkoutBlockedReason"));
  assertDoesNotThrow(()->api.quote("owner",new AcademyOnboardingController.Plan("STARTER","")));
 }
 @Test void monthlyDefaultStillActivatesOneMonth(){enroll("IN");var o=order();api.verify("owner",verified(o));assertEquals(LocalDate.now().plusMonths(1),db.queryForObject("SELECT renewal_date FROM academy_organization",LocalDate.class));}
 @Test void revisedPricesRequireFreshTotal(){enroll("IN");db.update("UPDATE academy_plan_price SET amount_minor=200000 WHERE plan_code='STARTER' AND currency='INR'");assertThrows(ResponseStatusException.class,this::order);verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}
 @Test void laterCampaignCanAllowReturningCustomersButFirst100Cannot(){
  enroll("IN");var o=order();api.verify("owner",verified(o));
  db.update("UPDATE academy_organization SET renewal_date=?",LocalDate.now());
  db.update("INSERT INTO academy_coupon(code,percent_off,max_orders,expires_on,enabled,first_payment_only) VALUES('RETURN10',10,100,?,TRUE,FALSE)",LocalDate.now().plusDays(30));
  var q=(Map<?,?>)api.quote("owner",new AcademyOnboardingController.Plan("STARTER","RETURN10"));assertEquals(14990L,q.get("discount"));
  assertThrows(ResponseStatusException.class,()->api.quote("owner",new AcademyOnboardingController.Plan("STARTER","FIRST100")));
 }
 @Test void newNamesPreserveCoachLimits(){assertEquals(1,AcademyCoachLimits.limit("Starter Academy"));assertEquals(5,AcademyCoachLimits.limit("Growth Academy"));assertEquals(15,AcademyCoachLimits.limit("Elite Academy"));assertEquals(15,AcademyCoachLimits.limit("School"));}
 @Test void yearlyCouponWorksForEveryInrTier(){enroll("IN");for(String plan:List.of("STARTER","GROWTH","SCHOOL")){var q=(Map<?,?>)api.quote("owner",new AcademyOnboardingController.Plan(plan,"FIRST100",null,"YEARLY"));assertEquals(10000L,q.get("discount"));assertEquals(12,q.get("billingMonths"));}}
 @Test void annualUsdCatalogIsConfiguredButCheckoutStillNeedsExportApproval(){var plans=(List<Map<String,Object>>)((Map<?,?>)api.plans("US")).get("plans");assertEquals(19000L,((Number)plans.getFirst().get("annual_amount_minor")).longValue());enroll("US");assertThrows(ResponseStatusException.class,()->api.quote("owner",new AcademyOnboardingController.Plan("STARTER","",null,"YEARLY")));verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());}

 AcademyOperationsController operations(){return new AcademyOperationsController(db,auth);}
 UUID endingTrial(){enroll("IN");api.trial("owner");UUID org=db.queryForObject("SELECT organization_id FROM academy_enrollment",UUID.class);db.update("UPDATE academy_enrollment SET trial_started_on=?",LocalDate.now().minusDays(6));db.update("UPDATE academy_organization SET renewal_date=?",LocalDate.now().plusDays(1));return org;}
 @Test void sixthDayReminderHasHonestEmptyFallbackAndNoEarlyReminder(){enroll("IN");api.trial("owner");UUID org=db.queryForObject("SELECT organization_id FROM academy_enrollment",UUID.class);assertEquals(false,operations().trialReminder("owner",org).get("show"));db.update("UPDATE academy_enrollment SET trial_started_on=?",LocalDate.now().minusDays(6));db.update("UPDATE academy_organization SET renewal_date=?",LocalDate.now().plusDays(1));var reminder=operations().trialReminder("owner",org);assertEquals(true,reminder.get("show"));assertFalse(reminder.get("message").toString().contains("AI"));assertTrue(reminder.get("message").toString().contains("ready for your students"));}
 @Test void paidPlanAndBillingOptOutSuppressTrialReminder(){UUID org=endingTrial();UUID member=db.queryForObject("SELECT id FROM academy_member",UUID.class);db.update("INSERT INTO academy_notification_preference(organization_id,member_id,billing) VALUES(?,?,FALSE)",org,member);assertEquals(false,operations().trialReminder("owner",org).get("show"));db.update("UPDATE academy_notification_preference SET billing=TRUE");db.update("UPDATE academy_organization SET plan='Starter Academy'");assertEquals(false,operations().trialReminder("owner",org).get("show"));}
 @Test void reminderCountsOnlyTrialPeriodAndCoachScopedStudents(){
  UUID org=endingTrial(),coachAccount=UUID.randomUUID(),coach=UUID.randomUUID(),student=UUID.randomUUID(),otherStudent=UUID.randomUUID();
  db.update("INSERT INTO player_account(id,display_name) VALUES(?,'Coach')",coachAccount);
  db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,'Coach','COACH')",coach,org,coachAccount);
  when(auth.requireBearer("coach")).thenReturn(new AuthenticatedPlayer(coachAccount,"coach","Coach",null));
  db.update("INSERT INTO academy_student(id,organization_id,name,email,coach_id) VALUES(?,?,'Student','s@example.com',?)",student,org,coach);
  db.update("INSERT INTO academy_student(id,organization_id,name,email) VALUES(?,?,'Other','o@example.com')",otherStudent,org);
  for(UUID sid:List.of(student,otherStudent))db.update("INSERT INTO academy_observation(id,organization_id,student_id,recorded_by,practiced_on,rating,accuracy,minutes,tactics,blunders,opening_errors,middle_errors,endgame_errors,retry_attempts,retry_failures,notes) VALUES(?,?,?,?,?,1000,70,10,1,5,0,0,0,4,1,'')",UUID.randomUUID(),org,sid,coach,LocalDate.now());
  db.update("INSERT INTO academy_observation(id,organization_id,student_id,recorded_by,practiced_on,rating,accuracy,minutes,tactics,blunders,opening_errors,middle_errors,endgame_errors,retry_attempts,retry_failures,notes) VALUES(?,?,?,?,?,1000,70,10,1,99,0,0,0,0,0,'')",UUID.randomUUID(),org,student,coach,LocalDate.now().minusDays(8));
  var reminder=operations().trialReminder("coach",org);assertEquals(5L,reminder.get("blunders"));assertEquals(3L,reminder.get("retrySolved"));assertEquals(false,reminder.get("canChoosePlan"));
  assertEquals(10L,operations().trialReminder("owner",org).get("blunders"));
  db.update("UPDATE academy_member SET role='STUDENT' WHERE id=?",coach);assertEquals(false,operations().trialReminder("coach",org).get("show"));
 }

 UUID pendingLink(){
  enroll("IN");var o=order();UUID id=(UUID)o.get("id");
  db.update("UPDATE academy_checkout SET provider_order='plink_fixture',payment_link_url='https://rzp.io/i/fixture',currency='USD',amount_minor=1900 WHERE id=?",id);
  return id;
 }
 @Test void linkCannotUseOrderSignatureVerification(){UUID id=pendingLink();assertThrows(ResponseStatusException.class,()->api.verify("owner",new AcademyOnboardingController.Verification(id,"pay_link","a".repeat(64))));assertEquals("PENDING",db.queryForObject("SELECT status FROM academy_checkout",String.class));}
 @Test void linkReconciliationUsesExactReferenceAndIsIdempotent(){
  UUID id=pendingLink();assertEquals(false,((Map<?,?>)api.reconcile("owner",id)).get("active"));
  when(gateway.findCapturedLinkPayment("plink_fixture",id.toString(),1900)).thenReturn("pay_link");
  assertEquals(true,((Map<?,?>)api.reconcile("owner",id)).get("active"));api.reconcile("owner",id);
  assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_invoice",Integer.class));
  verify(gateway,never()).findCapturedPayment(anyString(),anyLong(),anyString());
 }
 @Test void signedLinkWebhookRejectsWrongPaymentAndActivatesExactPayment(){
  UUID id=pendingLink();when(gateway.validWebhookSignature(anyString(),eq("signed"))).thenReturn(true);
  String raw="{\"event\":\"payment_link.paid\",\"payload\":{\"payment_link\":{\"entity\":{\"id\":\"plink_fixture\"}},\"payment\":{\"entity\":{\"id\":\"pay_link\"}}}}";
  when(gateway.findCapturedLinkPayment("plink_fixture",id.toString(),1900)).thenReturn("pay_other");assertThrows(ResponseStatusException.class,()->api.webhook(raw,"signed"));
  assertEquals("PENDING",db.queryForObject("SELECT status FROM academy_checkout",String.class));
  when(gateway.findCapturedLinkPayment("plink_fixture",id.toString(),1900)).thenReturn("pay_link");api.webhook(raw,"signed");api.webhook(raw,"signed");
  assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM academy_invoice",Integer.class));
 }
 @Test void missingInternationalTaxApprovalCannotCreateAnyPayableLink(){enroll("US");assertThrows(ResponseStatusException.class,()->api.order("owner",new AcademyOnboardingController.Plan("STARTER","",1900L)));verify(gateway,never()).createUsdLink(anyString(),anyLong(),anyString());}
 @Test void approvedBillingFixtureRoutesUsdToLinkAndResumesSameCheckout(){
  // Test fixture only: production export-tax approval is still blocked by AcademyBilling.
  enroll("US");
  var billing=new HashMap<String,Object>();billing.put("total",1900L);billing.put("tax",0L);billing.put("currency","USD");
  when(gateway.createUsdLink(anyString(),eq(1900L),anyString())).thenReturn(new AcademyPaymentGateway.ProviderLink("plink_fixture","https://rzp.io/i/fixture"));
  try(var approved=org.mockito.Mockito.mockStatic(AcademyBilling.class)){
   approved.when(()->AcademyBilling.snapshot(any(),any(),anyMap(),eq(1900L),eq(0L))).thenReturn(billing);
   var input=new AcademyOnboardingController.Plan("STARTER","",1900L);
   var first=(Map<?,?>)api.order("owner",input);assertEquals("https://rzp.io/i/fixture",first.get("paymentUrl"));assertEquals("USD",first.get("currency"));
   assertEquals(first,api.order("owner",input));verify(gateway,times(1)).createUsdLink(eq(first.get("id").toString()),eq(1900L),anyString());
   verify(gateway,never()).createOrder(anyString(),anyLong(),anyString());
  }
 }
}

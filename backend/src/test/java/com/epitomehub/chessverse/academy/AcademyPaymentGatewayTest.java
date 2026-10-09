package com.epitomehub.chessverse.academy;
import static org.junit.jupiter.api.Assertions.*;
import java.util.HexFormat;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;
class AcademyPaymentGatewayTest {
 @Test void testKeysNeverActivateProductionAcademy(){assertFalse(new AcademyPaymentGateway(new ObjectMapper(),true,"rzp_test_fixture","secret","webhook").available());}
 @Test void disabledGatewayCannotVerifyCheckout(){var g=new AcademyPaymentGateway(new ObjectMapper(),false,"rzp_live_fixture","secret","webhook");assertFalse(g.validPaymentSignature("order_a","pay_b","a".repeat(64)));}
 @Test void signatureBindsPaymentToExactServerOrder(){var g=new AcademyPaymentGateway(new ObjectMapper(),true,"rzp_live_fixture","secret","webhook");String signature=HexFormat.of().formatHex(AcademyPaymentGateway.hmacSha256("secret","order_a|pay_b"));assertTrue(g.validPaymentSignature("order_a","pay_b",signature));assertFalse(g.validPaymentSignature("order_other","pay_b",signature));assertFalse(g.validPaymentSignature("order_a","pay_other",signature));}
 @Test void webhookSignatureChecksUnmodifiedRawBody(){var g=new AcademyPaymentGateway(new ObjectMapper(),true,"rzp_live_fixture","secret","webhook");String raw="{\"event\":\"payment.captured\"}";String sig=HexFormat.of().formatHex(AcademyPaymentGateway.hmacSha256("webhook",raw));assertTrue(g.validWebhookSignature(raw,sig));assertFalse(g.validWebhookSignature(raw+" ",sig));}

 static final String REF="12345678-1234-1234-1234-123456789abc";
 final ObjectMapper mapper=new ObjectMapper();
 AcademyPaymentGateway linkGateway(){return org.mockito.Mockito.spy(new AcademyPaymentGateway(mapper,true,"rzp_live_fixture","secret","webhook"));}
 tools.jackson.databind.JsonNode link(String status,long amount,String currency,String ref,String url){
  return mapper.readTree("{\"id\":\"plink_fixture\",\"reference_id\":\""+ref+"\",\"amount\":"+amount+",\"currency\":\""+currency+"\",\"accept_partial\":false,\"short_url\":\""+url+"\",\"status\":\""+status+"\",\"amount_paid\":1900,\"order_id\":\"order_link\",\"payments\":[{\"payment_id\":\"pay_link\",\"status\":\"captured\",\"amount\":1900}]}");
 }
 @Test void usdLinkRequestHasExactAmountReferenceAndNoNotifications(){
  var g=linkGateway();org.mockito.Mockito.doReturn(mapper.readTree("{\"payment_links\":[]}")).when(g).linkRequest("GET","payment_links?reference_id="+REF,null);
  org.mockito.Mockito.doReturn(link("created",1900,"USD",REF,"https://rzp.io/i/fixture")).when(g).linkRequest(org.mockito.ArgumentMatchers.eq("POST"),org.mockito.ArgumentMatchers.eq("payment_links"),org.mockito.ArgumentMatchers.anyMap());
  assertEquals("plink_fixture",g.createUsdLink(REF,1900,"Starter Academy").id());
  var body=org.mockito.ArgumentCaptor.forClass(java.util.Map.class);org.mockito.Mockito.verify(g).linkRequest(org.mockito.ArgumentMatchers.eq("POST"),org.mockito.ArgumentMatchers.eq("payment_links"),body.capture());
  assertEquals(1900L,body.getValue().get("amount"));assertEquals("USD",body.getValue().get("currency"));assertEquals(REF,body.getValue().get("reference_id"));
  assertEquals(false,body.getValue().get("accept_partial"));assertEquals(java.util.Map.of("email",false,"sms",false),body.getValue().get("notify"));
 }
 @Test void retryRecoversSameLinkWithoutAnotherProviderCreate(){
  var g=linkGateway();var old=link("created",1900,"USD",REF,"https://rzp.io/i/fixture");
  org.mockito.Mockito.doReturn(mapper.readTree("{\"payment_links\":["+old+"]}")).when(g).linkRequest("GET","payment_links?reference_id="+REF,null);
  assertEquals("plink_fixture",g.createUsdLink(REF,1900,"Starter Academy").id());
  org.mockito.Mockito.verify(g,org.mockito.Mockito.never()).linkRequest(org.mockito.ArgumentMatchers.eq("POST"),org.mockito.ArgumentMatchers.anyString(),org.mockito.ArgumentMatchers.anyMap());
  assertThrows(org.springframework.web.server.ResponseStatusException.class,()->g.createUsdLink(REF,4900,"Growth Academy"));
 }
 @Test void onlyExactCapturedLinkCanActivate(){
  var g=linkGateway();org.mockito.Mockito.doReturn(link("paid",1900,"USD",REF,"https://rzp.io/i/fixture")).when(g).linkRequest("GET","payment_links/plink_fixture",null);
  org.mockito.Mockito.doReturn(new AcademyPaymentGateway.VerifiedPayment("pay_link")).when(g).verifyCapturedPayment("pay_link","order_link",1900,"USD");
  assertEquals("pay_link",g.findCapturedLinkPayment("plink_fixture",REF,1900));
  org.mockito.Mockito.verify(g).verifyCapturedPayment("pay_link","order_link",1900,"USD");
  assertThrows(org.springframework.web.server.ResponseStatusException.class,()->g.findCapturedLinkPayment("plink_fixture","other",1900));
  assertThrows(org.springframework.web.server.ResponseStatusException.class,()->g.findCapturedLinkPayment("plink_fixture",REF,4900));
 }
 @Test void unpaidLinkNeverActivates(){
  var g=linkGateway();org.mockito.Mockito.doReturn(link("created",1900,"USD",REF,"https://rzp.io/i/fixture")).when(g).linkRequest("GET","payment_links/plink_fixture",null);
  assertNull(g.findCapturedLinkPayment("plink_fixture",REF,1900));org.mockito.Mockito.verify(g,org.mockito.Mockito.never()).verifyCapturedPayment(org.mockito.ArgumentMatchers.anyString(),org.mockito.ArgumentMatchers.anyString(),org.mockito.ArgumentMatchers.anyLong(),org.mockito.ArgumentMatchers.anyString());
 }
 @Test void redirectRejectsUntrustedOrCredentialBearingUrls(){
  assertTrue(AcademyPaymentGateway.safePaymentLink("https://rzp.io/i/fixture"));
  for(String url:java.util.List.of("http://rzp.io/i/fixture","https://rzp.io.evil.example/test","https://user@rzp.io/i/x","javascript:alert(1)","https://rzp.io:444/x","https://example.com"))assertFalse(AcademyPaymentGateway.safePaymentLink(url),url);
 }
}

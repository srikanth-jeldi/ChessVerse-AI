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
}

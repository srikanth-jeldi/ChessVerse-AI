package com.epitomehub.chessverse.economy;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

class RazorpayPurchaseGatewayTest {
    private final RazorpayPurchaseGateway gateway = new RazorpayPurchaseGateway(
            new ObjectMapper(), true, "rzp_test_public", "test-secret", "webhook-secret");

    @Test
    void verifiesCheckoutSignatureInConstantTimeCompatibleForm() {
        assertTrue(gateway.validPaymentSignature("order_123", "pay_456",
                "3d11ef56573a9e31769e78a41f41a18d4af118e57d57888eef2f0dda4a479357"));
        assertFalse(gateway.validPaymentSignature("order_123", "pay_CHANGED",
                "3d11ef56573a9e31769e78a41f41a18d4af118e57d57888eef2f0dda4a479357"));
        assertFalse(gateway.validPaymentSignature("order_123", "pay_456", "not-hex"));
    }

    @Test
    void verifiesWebhookAgainstExactRawBody() {
        String raw = "{\"event\":\"payment.captured\"}";
        assertTrue(gateway.validWebhookSignature(raw,
                "0e95258623492dd0dae77245c958c256d46b4a30b338084b7e996fc25653c79c"));
        assertFalse(gateway.validWebhookSignature(raw + " ",
                "0e95258623492dd0dae77245c958c256d46b4a30b338084b7e996fc25653c79c"));
    }
}

package com.epitomehub.chessverse.economy;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

@Service
class PurchaseWebhookService {
    private final JdbcTemplate jdbc;
    private final ObjectMapper json;
    private final RazorpayPurchaseGateway razorpay;
    private final PurchaseService purchases;

    PurchaseWebhookService(JdbcTemplate jdbc, ObjectMapper json,
                           RazorpayPurchaseGateway razorpay, PurchaseService purchases) {
        this.jdbc = jdbc;
        this.json = json;
        this.razorpay = razorpay;
        this.purchases = purchases;
    }

    @Transactional
    void razorpay(String eventId, String signature, String rawBody) {
        if (rawBody == null || rawBody.isBlank() || rawBody.length() > 262_144
                || !razorpay.validWebhookSignature(rawBody, signature)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid webhook signature.");
        }
        String payloadHash = PurchaseService.sha256(rawBody);
        String replayKey = PurchaseService.sha256(
                eventId == null || eventId.isBlank() ? payloadHash : eventId.trim());
        JsonNode root;
        try {
            root = json.readTree(rawBody);
        } catch (Exception invalidJson) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid webhook payload.");
        }
        String type = root.path("event").asText("unknown");
        UUID storedId = UUID.randomUUID();
        try {
            jdbc.update("""
                    insert into purchase_provider_event(id,provider,event_id_hash,event_type,payload_hash,
                    processing_status,received_at) values(?,?,?,?,?,'RECEIVED',?)
                    """, storedId, "RAZORPAY", replayKey, type, payloadHash, Timestamp.from(Instant.now()));
        } catch (DuplicateKeyException replay) {
            return;
        }

        JsonNode payment = root.at("/payload/payment/entity");
        JsonNode refund = root.at("/payload/refund/entity");
        String paymentId = payment.path("id").asText();
        String providerOrderId = payment.path("order_id").asText();
        if ("payment.captured".equals(type) && !paymentId.isBlank() && !providerOrderId.isBlank()) {
            fulfillCaptured(providerOrderId, paymentId);
            finish(storedId, "PROCESSED");
            return;
        }
        String refundedPaymentId = "refund.processed".equals(type)
                ? refund.path("payment_id").asText() : paymentId;
        if (("refund.processed".equals(type) || "payment.refunded".equals(type))
                && !refundedPaymentId.isBlank()) {
            purchases.refundVerified("RAZORPAY", refundedPaymentId, replayKey);
            finish(storedId, "PROCESSED");
            return;
        }
        finish(storedId, "IGNORED");
    }

    private void fulfillCaptured(String providerOrderId, String paymentId) {
        var rows = jdbc.query("""
                select o.id,o.player_id,p.sku from purchase_order o
                join purchase_product p on p.id=o.product_id
                where o.provider='RAZORPAY' and o.provider_order_id=?
                """, (rs, row) -> new CapturedOrder(rs.getObject("id", UUID.class),
                rs.getObject("player_id", UUID.class), rs.getString("sku")), providerOrderId);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found.");
        CapturedOrder order = rows.getFirst();
        purchases.fulfillVerified(order.playerId, order.id, "RAZORPAY", order.sku, paymentId);
    }

    private void finish(UUID id, String status) {
        jdbc.update("update purchase_provider_event set processing_status=?,processed_at=? where id=?",
                status, Timestamp.from(Instant.now()), id);
    }

    private record CapturedOrder(UUID id, UUID playerId, String sku) {}
}

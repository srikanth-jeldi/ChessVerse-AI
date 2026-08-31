package com.epitomehub.chessverse.economy;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
class PurchaseReconciliationService {
    private final JdbcTemplate jdbc;
    private final RazorpayPurchaseGateway razorpay;
    private final PurchaseService purchases;

    PurchaseReconciliationService(JdbcTemplate jdbc, RazorpayPurchaseGateway razorpay,
                                  PurchaseService purchases) {
        this.jdbc = jdbc;
        this.razorpay = razorpay;
        this.purchases = purchases;
    }

    @Scheduled(fixedDelayString = "${chessverse.payments.reconciliation-delay-ms:300000}")
    void reconcile() {
        if (!razorpay.available()) return;
        var pending = jdbc.query("""
                select id,player_id,provider_order_id,price_minor,price_currency
                from purchase_order where provider='RAZORPAY' and status='PENDING'
                and updated_at<? order by updated_at limit 50
                """, (rs, row) -> new PendingOrder(rs.getObject("id", UUID.class),
                rs.getObject("player_id", UUID.class), rs.getString("provider_order_id"),
                rs.getLong("price_minor"), rs.getString("price_currency")),
                Timestamp.from(Instant.now().minus(2, ChronoUnit.MINUTES)));
        for (PendingOrder order : pending) {
            String paymentId = razorpay.findCapturedPayment(
                    order.providerOrderId, order.amount, order.currency);
            if (paymentId == null || paymentId.isBlank()) continue;
            try {
                purchases.reconcileRazorpay(order.playerId, order.id, paymentId);
            } catch (RuntimeException ignored) {
                // Leave pending so the next reconciliation or signed webhook can retry safely.
            }
        }
        jdbc.update("""
                update purchase_order set status='FAILED',updated_at=?
                where status='CREATED' and created_at<?
                """, Timestamp.from(Instant.now()),
                Timestamp.from(Instant.now().minus(1, ChronoUnit.DAYS)));
    }

    private record PendingOrder(UUID id, UUID playerId, String providerOrderId,
                                long amount, String currency) {}
}

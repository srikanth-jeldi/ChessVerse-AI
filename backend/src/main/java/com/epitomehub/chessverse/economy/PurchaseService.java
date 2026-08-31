package com.epitomehub.chessverse.economy;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
class PurchaseService {
    private static final String NOTICE = "Direct coin-pack purchase only. ChessVerseAI never stores money balances, card numbers, CVV, UPI PINs, OTPs, or bank credentials.";
    private final JdbcTemplate jdbc;
    private final EconomyService economy;
    private final GooglePlayPurchaseVerifier googlePlay;
    private final RazorpayPurchaseGateway razorpay;
    private final boolean appleStoreKitEnabled;

    PurchaseService(JdbcTemplate jdbc, EconomyService economy, GooglePlayPurchaseVerifier googlePlay,
                    RazorpayPurchaseGateway razorpay,
                    @Value("${chessverse.payments.apple-storekit.enabled:false}") boolean appleStoreKitEnabled) {
        this.jdbc = jdbc;
        this.economy = economy;
        this.googlePlay = googlePlay;
        this.razorpay = razorpay;
        this.appleStoreKitEnabled = appleStoreKitEnabled;
    }

    @Transactional
    PurchaseDtos.RazorpayCheckoutDto razorpayCheckout(AuthenticatedPlayer player, UUID orderId) {
        PurchaseDtos.OrderDto pending = order(player.id(), orderId);
        if (!"RAZORPAY".equals(pending.provider()) || !"CREATED".equals(pending.status())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Web checkout cannot start for this order.");
        }
        RazorpayPurchaseGateway.ProviderOrder provider = razorpay.createOrder(
                "cv-" + orderId, pending.priceMinor(), pending.priceCurrency());
        int updated = jdbc.update("""
                update purchase_order set provider_order_id=?,status='PENDING',updated_at=?
                where id=? and player_id=? and status='CREATED'
                """, provider.id(), Timestamp.from(Instant.now()), orderId, player.id());
        if (updated != 1) throw new ResponseStatusException(HttpStatus.CONFLICT, "Checkout already started.");
        return new PurchaseDtos.RazorpayCheckoutDto(orderId, provider.id(), provider.publicKeyId(),
                pending.priceMinor(), pending.priceCurrency(), pending.productName(),
                "Direct ChessVerseAI coin pack");
    }

    @Transactional
    PurchaseDtos.OrderDto verifyRazorpay(AuthenticatedPlayer player, UUID orderId,
                                         PurchaseDtos.RazorpayVerifyRequest request) {
        String storedOrder = jdbc.queryForObject("""
                select provider_order_id from purchase_order
                where id=? and player_id=? and provider='RAZORPAY'
                """, String.class, orderId, player.id());
        if (storedOrder == null || !storedOrder.equals(request.razorpayOrderId())
                || !razorpay.validPaymentSignature(storedOrder, request.razorpayPaymentId(),
                request.razorpaySignature())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Payment signature verification failed. No coins were credited.");
        }
        PurchaseDtos.OrderDto pending = order(player.id(), orderId);
        RazorpayPurchaseGateway.VerifiedPayment verified = razorpay.verifyCapturedPayment(
                request.razorpayPaymentId(), storedOrder, pending.priceMinor(), pending.priceCurrency());
        return fulfillVerified(player.id(), orderId, "RAZORPAY", pending.sku(), verified.id());
    }

    @Transactional
    PurchaseDtos.OrderDto verifyGooglePlay(AuthenticatedPlayer player, UUID orderId, String purchaseToken) {
        PurchaseDtos.OrderDto pending = order(player.id(), orderId);
        if (!"GOOGLE_PLAY".equals(pending.provider())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This is not a Google Play order.");
        }
        GooglePlayPurchaseVerifier.VerifiedGooglePurchase verified =
                googlePlay.verify(pending.sku(), purchaseToken);
        return fulfillVerified(player.id(), orderId, "GOOGLE_PLAY", verified.sku(), verified.transactionKey());
    }

    /**
     * Called only by a provider verifier after it has cryptographically/API
     * verified the purchase. Raw receipts and purchase tokens are deliberately
     * not persisted; only a SHA-256 replay-prevention fingerprint is retained.
     */
    @Transactional
    PurchaseDtos.OrderDto fulfillVerified(UUID playerId, UUID orderId, String provider,
                                           String verifiedSku, String providerTransactionId) {
        if (providerTransactionId == null || providerTransactionId.isBlank()) {
            throw new IllegalArgumentException("Verified provider transaction id is required.");
        }
        List<VerifiedOrder> rows = jdbc.query("""
                select o.id,o.player_id,o.provider,o.status,o.grant_currency,o.grant_amount,p.sku
                from purchase_order o join purchase_product p on p.id=o.product_id
                where o.id=? for update
                """, (rs, row) -> new VerifiedOrder(rs.getObject("id", UUID.class),
                rs.getObject("player_id", UUID.class), rs.getString("provider"), rs.getString("status"),
                rs.getString("grant_currency"), rs.getLong("grant_amount"), rs.getString("sku")), orderId);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Purchase order not found.");
        VerifiedOrder order = rows.getFirst();
        if (!order.playerId.equals(playerId)) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Purchase order not found.");
        if (!order.provider.equals(provider) || !order.sku.equals(verifiedSku)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Verified purchase does not match this order.");
        }
        if ("FULFILLED".equals(order.status)) return order(playerId, orderId);
        if (!("CREATED".equals(order.status) || "PENDING".equals(order.status) || "VERIFIED".equals(order.status))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Purchase order cannot be fulfilled.");
        }
        if (!"COINS".equals(order.grantCurrency)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Only direct coin packs are supported.");
        }
        Instant now = Instant.now();
        String fingerprint = sha256(provider + ':' + providerTransactionId);
        try {
            jdbc.update("""
                    update purchase_order set status='VERIFIED',provider_transaction_hash=?,verified_at=?,updated_at=?
                    where id=?
                    """, fingerprint, Timestamp.from(now), Timestamp.from(now), orderId);
        } catch (org.springframework.dao.DuplicateKeyException replay) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Purchase receipt was already used.");
        }
        economy.grantPurchasedCoins(playerId, order.grantAmount, orderId);
        jdbc.update("""
                update purchase_order set status='FULFILLED',fulfilled_at=?,updated_at=? where id=?
                """, Timestamp.from(now), Timestamp.from(now), orderId);
        return order(playerId, orderId);
    }

    @Transactional
    void refundVerified(String provider, String providerTransactionId, String eventHash) {
        String fingerprint = sha256(provider + ':' + providerTransactionId);
        List<RefundOrder> rows = jdbc.query("""
                select id,player_id,status,grant_amount from purchase_order
                where provider=? and provider_transaction_hash=? for update
                """, (rs, row) -> new RefundOrder(rs.getObject("id", UUID.class),
                rs.getObject("player_id", UUID.class), rs.getString("status"),
                rs.getLong("grant_amount")), provider, fingerprint);
        if (rows.isEmpty()) return;
        RefundOrder order = rows.getFirst();
        if ("REFUNDED".equals(order.status) || "REVOKED".equals(order.status)) return;
        if (!"FULFILLED".equals(order.status)) {
            jdbc.update("update purchase_order set status='REFUNDED',updated_at=? where id=?",
                    Timestamp.from(Instant.now()), order.id);
            return;
        }
        economy.revokePurchasedCoins(order.playerId, order.grantAmount, order.id, eventHash);
        jdbc.update("update purchase_order set status='REFUNDED',updated_at=? where id=?",
                Timestamp.from(Instant.now()), order.id);
    }

    PurchaseDtos.PurchaseCenterDto center(AuthenticatedPlayer player) {
        return new PurchaseDtos.PurchaseCenterDto(products(), orders(player.id(), 50),
                googlePlay.available(), appleStoreKitEnabled, razorpay.available(), NOTICE);
    }

    @Transactional
    PurchaseDtos.OrderDto create(AuthenticatedPlayer player, PurchaseDtos.CreateOrderRequest request) {
        String provider = request.provider();
        if ("RAZORPAY".equals(provider) && !razorpay.available()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Web checkout is not enabled yet. No payment was attempted.");
        }
        List<Product> products = jdbc.query("""
                select id,sku,display_name,grant_currency,grant_amount,price_minor,price_currency
                from purchase_product where id=? and active=true
                """, this::mapProductRow, request.productId());
        if (products.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Purchase product not found.");

        List<PurchaseDtos.OrderDto> existing = jdbc.query("""
                select o.id,o.product_id,p.sku,p.display_name,o.provider,o.status,o.price_minor,
                       o.price_currency,o.grant_currency,o.grant_amount,o.created_at,o.updated_at
                from purchase_order o join purchase_product p on p.id=o.product_id
                where o.player_id=? and o.idempotency_key=?
                """, this::mapOrder, player.id(), request.idempotencyKey());
        if (!existing.isEmpty()) return existing.getFirst();

        Product product = products.getFirst();
        Instant now = Instant.now();
        UUID id = UUID.randomUUID();
        jdbc.update("""
                insert into purchase_order(id,player_id,product_id,provider,status,idempotency_key,
                    price_minor,price_currency,grant_currency,grant_amount,created_at,updated_at)
                values(?,?,?,?,?,?,?,?,?,?,?,?)
                """, id, player.id(), product.id, provider, "CREATED", request.idempotencyKey(),
                product.priceMinor, product.priceCurrency, product.grantCurrency,
                product.grantAmount, Timestamp.from(now), Timestamp.from(now));
        return order(player.id(), id);
    }

    private List<PurchaseDtos.ProductDto> products() {
        return jdbc.query("""
                select id,sku,display_name,description,grant_currency,grant_amount,price_minor,price_currency
                from purchase_product where active=true order by sort_order,id
                """, (rs, row) -> new PurchaseDtos.ProductDto(rs.getObject("id", UUID.class), rs.getString("sku"),
                rs.getString("display_name"), rs.getString("description"), rs.getString("grant_currency"),
                rs.getLong("grant_amount"), rs.getLong("price_minor"), rs.getString("price_currency")));
    }

    private List<PurchaseDtos.OrderDto> orders(UUID playerId, int limit) {
        return jdbc.query("""
                select o.id,o.product_id,p.sku,p.display_name,o.provider,o.status,o.price_minor,
                       o.price_currency,o.grant_currency,o.grant_amount,o.created_at,o.updated_at
                from purchase_order o join purchase_product p on p.id=o.product_id
                where o.player_id=? order by o.created_at desc,o.id desc limit ?
                """, this::mapOrder, playerId, limit);
    }

    private PurchaseDtos.OrderDto order(UUID playerId, UUID orderId) {
        List<PurchaseDtos.OrderDto> rows = jdbc.query("""
                select o.id,o.product_id,p.sku,p.display_name,o.provider,o.status,o.price_minor,
                       o.price_currency,o.grant_currency,o.grant_amount,o.created_at,o.updated_at
                from purchase_order o join purchase_product p on p.id=o.product_id
                where o.player_id=? and o.id=?
                """, this::mapOrder, playerId, orderId);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Purchase order not found.");
        return rows.getFirst();
    }

    PurchaseDtos.OrderDto reconcileRazorpay(UUID playerId, UUID orderId, String paymentId) {
        PurchaseDtos.OrderDto pending = order(playerId, orderId);
        return fulfillVerified(playerId, orderId, "RAZORPAY", pending.sku(), paymentId);
    }

    private PurchaseDtos.OrderDto mapOrder(ResultSet rs, int row) throws SQLException {
        return new PurchaseDtos.OrderDto(rs.getObject("id", UUID.class), rs.getObject("product_id", UUID.class),
                rs.getString("sku"), rs.getString("display_name"), rs.getString("provider"), rs.getString("status"),
                rs.getLong("price_minor"), rs.getString("price_currency"), rs.getString("grant_currency"),
                rs.getLong("grant_amount"), rs.getTimestamp("created_at").toInstant(),
                rs.getTimestamp("updated_at").toInstant());
    }

    private Product mapProductRow(ResultSet rs, int row) throws SQLException {
        return new Product(rs.getObject("id", UUID.class), rs.getString("sku"), rs.getString("display_name"),
                rs.getString("grant_currency"), rs.getLong("grant_amount"), rs.getLong("price_minor"),
                rs.getString("price_currency"));
    }

    private record Product(UUID id, String sku, String name, String grantCurrency,
                           long grantAmount, long priceMinor, String priceCurrency) {}

    private record VerifiedOrder(UUID id, UUID playerId, String provider, String status,
                                 String grantCurrency, long grantAmount, String sku) {}

    private record RefundOrder(UUID id, UUID playerId, String status, long grantAmount) {}

    static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception impossible) {
            throw new IllegalStateException(impossible);
        }
    }
}

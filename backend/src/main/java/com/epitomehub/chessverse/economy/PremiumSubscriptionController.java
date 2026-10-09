package com.epitomehub.chessverse.economy;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Month;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/subscriptions")
public class PremiumSubscriptionController {
    private static final int TRIAL_DAYS = 7;
    private final PlayerAuthenticationService authentication;
    private final JdbcTemplate jdbc;
    private final GooglePlaySubscriptionVerifier googlePlay;

    public PremiumSubscriptionController(PlayerAuthenticationService authentication, JdbcTemplate jdbc,
            GooglePlaySubscriptionVerifier googlePlay) {
        this.authentication = authentication;
        this.jdbc = jdbc;
        this.googlePlay = googlePlay;
    }

    @GetMapping
    public Map<String, Object> status(
            @RequestHeader("Authorization") String bearer,
            @RequestHeader(value = "X-Country-Code", defaultValue = "IN") String countryCode) {
        AuthenticatedPlayer player = authentication.requireBearer(bearer);
        Entitlement entitlement = entitlement(player.id());
        List<Map<String, Object>> plans = jdbc.query("""
                select product_id,base_plan_id,billing_period,india_price_minor,currency
                from premium_plan_catalog where active=true order by india_price_minor
                """, (rs, row) -> Map.of(
                "productId", rs.getString("product_id"),
                "basePlanId", rs.getString("base_plan_id"),
                "billingPeriod", rs.getString("billing_period"),
                "indiaPriceMinor", rs.getLong("india_price_minor"),
                "currency", rs.getString("currency")));
        Map<String, Object> result = response(entitlement, plans, eligibleOffers(countryCode));
        result.put("googlePlayAvailable", googlePlay.available());
        return result;
    }

    @PostMapping("/google-play/verify")
    @Transactional
    public Map<String, Object> verifyGooglePlay(
            @RequestHeader("Authorization") String bearer,
            @RequestBody VerifyRequest request) {
        AuthenticatedPlayer player = authentication.requireBearer(bearer);
        GooglePlaySubscriptionVerifier.VerifiedSubscription verified =
                googlePlay.verify(request.purchaseToken());
        Instant now = Instant.now();
        String tokenHash = installationHash(request.purchaseToken());
        try {
            jdbc.update("""
                    insert into premium_entitlement(player_id,status,source,product_id,base_plan_id,
                    started_at,expires_at,auto_renewing,provider_token_hash,updated_at)
                    values(?,'ACTIVE','GOOGLE_PLAY',?,?,?,?,?,?,?)
                    on conflict(player_id) do update set status='ACTIVE',source='GOOGLE_PLAY',
                    product_id=excluded.product_id,base_plan_id=excluded.base_plan_id,
                    expires_at=excluded.expires_at,auto_renewing=excluded.auto_renewing,
                    provider_token_hash=excluded.provider_token_hash,updated_at=excluded.updated_at
                    """, player.id(), verified.productId(), verified.basePlanId(), Timestamp.from(now),
                    Timestamp.from(verified.expiresAt()), verified.autoRenewing(), tokenHash,
                    Timestamp.from(now));
        } catch (DuplicateKeyException claimedByAnotherAccount) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "This Google Play subscription is linked to another ChessVerseAI account.");
        }
        return response(entitlement(player.id()), activePlans(), List.of());
    }

    @PostMapping("/trial")
    @Transactional
    public Map<String, Object> startTrial(
            @RequestHeader("Authorization") String bearer,
            @RequestHeader(value = "X-Device-Id", required = false) String installationId) {
        AuthenticatedPlayer player = authentication.requireBearer(bearer);
        String installationHash = installationHash(installationId);
        Instant now = Instant.now();
        Instant expiresAt = now.plus(TRIAL_DAYS, ChronoUnit.DAYS);
        try {
            int claimed = jdbc.update("""
                    insert into premium_trial_installation(installation_hash,player_id,claimed_at)
                    values(?,?,?) on conflict do nothing
                    """, installationHash, player.id(), Timestamp.from(now));
            if (claimed == 0) throw trialUsed();
            int created = jdbc.update("""
                    insert into premium_entitlement(player_id,status,source,started_at,expires_at,
                    auto_renewing,updated_at)
                    select ?,'TRIAL','APP_TRIAL',?,?,false,?
                    where not exists(select 1 from premium_entitlement where player_id=?)
                    """, player.id(), Timestamp.from(now), Timestamp.from(expiresAt),
                    Timestamp.from(now), player.id());
            if (created == 0) throw trialUsed();
        } catch (DuplicateKeyException duplicate) {
            throw trialUsed();
        }
        return response(entitlement(player.id()), activePlans(), List.of());
    }

    private Map<String, Object> response(Entitlement entitlement, List<Map<String, Object>> plans,
            List<Map<String, Object>> offers) {
        Instant now = Instant.now();
        boolean premium = entitlement != null
                && ("TRIAL".equals(entitlement.status) || "ACTIVE".equals(entitlement.status))
                && entitlement.expiresAt.isAfter(now);
        String status = entitlement == null ? "NONE"
                : premium ? entitlement.status : "EXPIRED";
        return new HashMap<>(Map.of(
                "premium", premium,
                "status", status,
                "trialDays", TRIAL_DAYS,
                "expiresAt", entitlement == null ? "" : entitlement.expiresAt.toString(),
                "autoRenewing", entitlement != null && entitlement.autoRenewing,
                "plans", plans,
                "eligibleOffers", offers,
                "benefits", List.of("NO_ADS", "UNLIMITED_AI_REVIEWS",
                        "PREMIUM_BOARDS_AND_PIECES", "ADVANCED_TRAINING_INSIGHTS")));
    }

    private List<Map<String, Object>> eligibleOffers(String rawCountry) {
        String country = rawCountry == null ? "IN" : rawCountry.trim().toUpperCase();
        LocalDate today = LocalDate.now();
        List<Map<String, Object>> offers = new ArrayList<>();
        if ("IN".equals(country)) {
            offers.add(offer("FIRST30", "monthly", "₹30 off your first month", "FIXED", 3000));
            offers.add(offer("FIRST100", "yearly", "₹100 off your first year", "FIXED", 10000));
            if (today.getMonth() == Month.OCTOBER || today.getMonth() == Month.NOVEMBER) {
                offers.add(offer("DIWALI10", "monthly", "Diwali · 10% off the first month", "PERCENT", 10));
                offers.add(offer("DIWALI10", "yearly", "Diwali · 10% off the first year", "PERCENT", 10));
                offers.add(offer("DUSSEHRA10", "monthly", "Dussehra · 10% off the first month", "PERCENT", 10));
                offers.add(offer("DUSSEHRA10", "yearly", "Dussehra · 10% off the first year", "PERCENT", 10));
            }
        } else {
            offers.add(offer("WELCOME50", "monthly", "0.50 local-currency equivalent off", "REGIONAL_FIXED", 50));
            offers.add(offer("WELCOME50", "yearly", "0.50 local-currency equivalent off", "REGIONAL_FIXED", 50));
        }
        boolean southern = List.of("AU", "NZ", "ZA", "AR", "CL", "BR").contains(country);
        int month = today.getMonthValue();
        boolean summer = "IN".equals(country) ? month >= 4 && month <= 6
                : southern ? month == 12 || month <= 2 : month >= 6 && month <= 8;
        if (summer) {
            offers.add(offer("SUMMER10", "monthly", "Summer · 10% off the first month", "PERCENT", 10));
            offers.add(offer("SUMMER50", "yearly", "Summer · 50% off the first year", "PERCENT", 50));
        }
        if (month == 12 || month == 1) {
            offers.add(offer("CHRISTMAS10", "monthly", "Christmas · 10% off the first month", "PERCENT", 10));
            offers.add(offer("CHRISTMAS10", "yearly", "Christmas · 10% off the first year", "PERCENT", 10));
            offers.add(offer("NEWYEAR10", "monthly", "New Year · 10% off the first month", "PERCENT", 10));
            offers.add(offer("NEWYEAR10", "yearly", "New Year · 10% off the first year", "PERCENT", 10));
        }
        return offers;
    }

    private Map<String, Object> offer(String code, String basePlanId, String label,
            String discountType, int discountValue) {
        return Map.of("code", code, "basePlanId", basePlanId, "label", label,
                "discountType", discountType, "discountValue", discountValue,
                "playOfferTag", code.toLowerCase());
    }

    private List<Map<String, Object>> activePlans() {
        return jdbc.query("""
                select product_id,base_plan_id,billing_period,india_price_minor,currency
                from premium_plan_catalog where active=true order by india_price_minor
                """, (rs, row) -> Map.of(
                "productId", rs.getString(1), "basePlanId", rs.getString(2),
                "billingPeriod", rs.getString(3), "indiaPriceMinor", rs.getLong(4),
                "currency", rs.getString(5)));
    }

    private Entitlement entitlement(java.util.UUID playerId) {
        return jdbc.query("""
                select status,expires_at,auto_renewing from premium_entitlement where player_id=?
                """, rs -> rs.next() ? new Entitlement(rs.getString(1),
                rs.getTimestamp(2).toInstant(), rs.getBoolean(3)) : null, playerId);
    }

    private String installationHash(String installationId) {
        if (installationId == null || installationId.isBlank() || installationId.length() > 128) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "A valid app installation is required to start the trial.");
        }
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(installationId.trim().getBytes(StandardCharsets.UTF_8)));
        } catch (Exception impossible) {
            throw new IllegalStateException("SHA-256 is unavailable", impossible);
        }
    }

    private ResponseStatusException trialUsed() {
        return new ResponseStatusException(HttpStatus.CONFLICT,
                "The free trial has already been used by this account or installation.");
    }

    private record Entitlement(String status, Instant expiresAt, boolean autoRenewing) {}
    public record VerifyRequest(String purchaseToken) {}
}

package com.epitomehub.chessverse.analytics;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** Privacy-safe first-party product telemetry and super-admin reporting. */
@RestController
@RequestMapping("/api/v1/analytics")
public class ProductAnalyticsController {
    private static final String EVENT_PATTERN =
            "session_started|game_started|game_completed|rewarded_ad_started|rewarded_ad_completed|"
            + "rewarded_ad_dismissed|review_opened|share_completed|tournament_joined|subscription_viewed";

    public record EventInput(@NotNull UUID id,
            @NotNull @Pattern(regexp = EVENT_PATTERN) String name,
            @Size(max = 48) @Pattern(regexp = "[a-z0-9_\\-]*") String context) {}

    private final JdbcTemplate db;
    private final PlayerAuthenticationService authentication;

    public ProductAnalyticsController(JdbcTemplate db, PlayerAuthenticationService authentication) {
        this.db = db;
        this.authentication = authentication;
    }

    @PostMapping("/events")
    @Transactional
    public void event(@RequestHeader("Authorization") String bearer,
                      @Valid @RequestBody EventInput input) {
        AuthenticatedPlayer player = authentication.requireBearer(bearer);
        try {
            db.update("""
                    insert into product_analytics_event
                    (id,player_id,event_name,context_value,occurred_at,received_at)
                    values(?,?,?,?,?,?)
                    """, input.id(), player.id(), input.name(), clean(input.context()),
                    Timestamp.from(Instant.now()), Timestamp.from(Instant.now()));
        } catch (DuplicateKeyException duplicate) {
            // Mobile retries are expected; an event identifier is idempotent per account.
        }
    }

    @GetMapping("/platform")
    @Transactional(readOnly = true)
    public Map<String, Object> platform(@RequestHeader("Authorization") String bearer,
            @RequestParam(defaultValue = "30") @Min(1) @Max(90) int days) {
        AuthenticatedPlayer player = authentication.requireBearer(bearer);
        Long admins = db.queryForObject(
                "select count(*) from academy_super_admin where account_id=?", Long.class, player.id());
        if (admins == null || admins == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "EpitomeHub Super Admin required.");
        }
        Instant now = Instant.now();
        Instant from = now.minus(days, ChronoUnit.DAYS);
        Instant today = now.truncatedTo(ChronoUnit.DAYS);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("windowDays", days);
        result.put("generatedAt", now);
        result.put("activeToday", count("select count(distinct player_id) from product_analytics_event where occurred_at>=?", today));
        result.put("active7Days", count("select count(distinct player_id) from product_analytics_event where occurred_at>=?", now.minus(7, ChronoUnit.DAYS)));
        result.put("activeInWindow", count("select count(distinct player_id) from product_analytics_event where occurred_at>=?", from));
        result.put("returningPlayers", count("""
                select count(distinct recent.player_id) from product_analytics_event recent
                where recent.occurred_at>=? and exists(
                    select 1 from product_analytics_event older
                    where older.player_id=recent.player_id and older.occurred_at<?)
                """, from, from));
        result.put("events", rows("""
                select event_name,count(*) as events,count(distinct player_id) as players
                from product_analytics_event where occurred_at>=?
                group by event_name order by events desc,event_name
                """, from));
        long rewarded = count("""
                select count(*) from economy_transaction
                where transaction_type='REWARDED_AD' and created_at>=?
                """, from);
        result.put("rewardedAdsVerified", rewarded);
        result.put("rewardedCoinsIssued", count("""
                select coalesce(sum(amount),0) from economy_transaction
                where transaction_type='REWARDED_AD' and created_at>=?
                """, from));
        result.put("purchases", rows("""
                select price_currency,count(*) as orders,coalesce(sum(price_minor),0) as revenue_minor
                from purchase_order where status='FULFILLED' and fulfilled_at>=?
                group by price_currency order by price_currency
                """, from));
        long adStarts = count("""
                select count(*) from product_analytics_event
                where event_name='rewarded_ad_started' and occurred_at>=?
                """, from);
        result.put("rewardedAdStarts", adStarts);
        result.put("rewardedAdCompletionPercent",
                adStarts == 0 ? 0.0 : Math.min(100.0, rewarded * 100.0 / adStarts));
        return result;
    }

    private long count(String sql, Instant... instants) {
        Object[] args = java.util.Arrays.stream(instants).map(Timestamp::from).toArray();
        Long value = db.queryForObject(sql, Long.class, args);
        return value == null ? 0 : value;
    }

    private List<Map<String, Object>> rows(String sql, Instant instant) {
        return db.query(sql, (rs, row) -> {
            Map<String, Object> item = new LinkedHashMap<>();
            for (int index = 1; index <= rs.getMetaData().getColumnCount(); index++) {
                item.put(rs.getMetaData().getColumnLabel(index).toLowerCase(Locale.ROOT),
                        rs.getObject(index));
            }
            return item;
        }, Timestamp.from(instant));
    }

    private String clean(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim().toLowerCase(Locale.ROOT);
    }
}

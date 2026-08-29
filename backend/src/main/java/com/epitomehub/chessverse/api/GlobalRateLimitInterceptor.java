package com.epitomehub.chessverse.api;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Locale;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
class GlobalRateLimitInterceptor implements HandlerInterceptor {
    private static final int WINDOW_SECONDS = 60;
    private static final String UPSERT = """
            insert into api_rate_limit_bucket(bucket_key,window_start,request_count,expires_at)
            values(?,?,1,?)
            on conflict(bucket_key,window_start) do update
            set request_count=api_rate_limit_bucket.request_count+1,
                expires_at=excluded.expires_at
            returning request_count
            """;

    private final JdbcTemplate jdbc;
    private final boolean enabled;

    GlobalRateLimitInterceptor(
            JdbcTemplate jdbc,
            @Value("${chessverse.api.rate-limit.enabled:true}") boolean enabled) {
        this.jdbc = jdbc;
        this.enabled = enabled;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws IOException {
        if (!enabled || "OPTIONS".equalsIgnoreCase(request.getMethod()) || exempt(request.getRequestURI())) {
            return true;
        }

        Policy policy = policyFor(request.getMethod(), request.getRequestURI());
        long now = Instant.now().getEpochSecond();
        long window = now / WINDOW_SECONDS;
        long retryAfter = WINDOW_SECONDS - (now % WINDOW_SECONDS);
        Instant expiresAt = Instant.ofEpochSecond((window + 2) * WINDOW_SECONDS);

        String route = policy.name().toLowerCase(Locale.ROOT);
        int ipCount = increment("ip:" + hash(clientIp(request)) + ':' + route, window, expiresAt);
        if (ipCount > policy.ipLimit) return reject(response, retryAfter, policy.ipLimit);

        String authorization = request.getHeader("Authorization");
        if (authorization != null && authorization.regionMatches(true, 0, "Bearer ", 0, 7)) {
            String token = authorization.substring(7).trim();
            if (!token.isEmpty()) {
                int identityCount = increment("session:" + hash(token) + ':' + route, window, expiresAt);
                if (identityCount > policy.sessionLimit) return reject(response, retryAfter, policy.sessionLimit);
                response.setHeader("X-RateLimit-Limit", Integer.toString(policy.sessionLimit));
                response.setHeader("X-RateLimit-Remaining", Integer.toString(Math.max(0, policy.sessionLimit - identityCount)));
            }
        } else {
            response.setHeader("X-RateLimit-Limit", Integer.toString(policy.ipLimit));
            response.setHeader("X-RateLimit-Remaining", Integer.toString(Math.max(0, policy.ipLimit - ipCount)));
        }

        if (ThreadLocalRandom.current().nextInt(512) == 0) {
            jdbc.update("delete from api_rate_limit_bucket where expires_at < ?", Timestamp.from(Instant.now()));
        }
        return true;
    }

    private int increment(String key, long window, Instant expiresAt) {
        Integer count = jdbc.queryForObject(UPSERT, Integer.class, key, window, Timestamp.from(expiresAt));
        return count == null ? 1 : count;
    }

    private boolean reject(HttpServletResponse response, long retryAfter, int limit) throws IOException {
        response.setStatus(429);
        response.setHeader("Retry-After", Long.toString(retryAfter));
        response.setHeader("X-RateLimit-Limit", Integer.toString(limit));
        response.setHeader("X-RateLimit-Remaining", "0");
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write("{\"error\":\"Too many requests. Please wait and try again.\"}");
        return false;
    }

    static Policy policyFor(String method, String path) {
        String normalized = path == null ? "" : path.toLowerCase(Locale.ROOT);
        if (normalized.startsWith("/api/auth/")) {
            if (normalized.endsWith("/register") || normalized.endsWith("/resend-verification")
                    || normalized.endsWith("/password/forgot")) return Policy.AUTH_SENSITIVE;
            if (normalized.endsWith("/login")) return Policy.AUTH_LOGIN;
            return Policy.AUTH_OTHER;
        }
        if (normalized.contains("/messages/attachments")) return Policy.UPLOAD;
        if (normalized.contains("/messages")) return Policy.CHAT;
        if (normalized.contains("/tournaments")) return Policy.TOURNAMENT;
        if (normalized.contains("/matchmaking") || normalized.contains("/rooms")
                || normalized.endsWith("/online/queue")) return Policy.MATCHMAKING;
        if (normalized.matches(".*/matches/[^/]+/moves.*")) return Policy.GAME_MOVE;
        if (!"GET".equalsIgnoreCase(method)) return Policy.MUTATION;
        return Policy.READ;
    }

    private static boolean exempt(String path) {
        return path == null || path.equals("/api/v1/health") || path.startsWith("/actuator/");
    }

    private static String clientIp(HttpServletRequest request) {
        String remote = request.getRemoteAddr();
        if (trustedProxy(remote)) {
            String forwarded = request.getHeader("X-Forwarded-For");
            if (forwarded != null && !forwarded.isBlank()) {
                String candidate = forwarded.split(",", 2)[0].trim();
                if (candidate.matches("[0-9a-fA-F:.]{3,45}")) return candidate;
            }
        }
        return remote == null ? "unknown" : remote;
    }

    private static boolean trustedProxy(String address) {
        if (address == null) return false;
        if (address.equals("127.0.0.1") || address.equals("::1") || address.startsWith("10.")
                || address.startsWith("192.168.")) return true;
        if (!address.startsWith("172.")) return false;
        String[] parts = address.split("\\.", 3);
        if (parts.length < 2) return false;
        try {
            int second = Integer.parseInt(parts[1]);
            return second >= 16 && second <= 31;
        } catch (NumberFormatException ignored) {
            return false;
        }
    }

    private static String hash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest, 0, 16);
        } catch (Exception impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    enum Policy {
        AUTH_SENSITIVE(5, 5), AUTH_LOGIN(10, 10), AUTH_OTHER(20, 20),
        UPLOAD(12, 8), CHAT(90, 45), TOURNAMENT(60, 30), MATCHMAKING(45, 30),
        GAME_MOVE(240, 180), MUTATION(180, 120), READ(600, 360);

        final int ipLimit;
        final int sessionLimit;
        Policy(int ipLimit, int sessionLimit) { this.ipLimit = ipLimit; this.sessionLimit = sessionLimit; }
    }
}

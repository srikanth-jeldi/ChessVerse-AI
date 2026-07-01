package com.epitomehub.chessverse.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
class AuthRateLimitInterceptor implements HandlerInterceptor {
    private static final Duration WINDOW = Duration.ofMinutes(1);

    private final Map<String, RateWindow> windows = new ConcurrentHashMap<>();
    private final AtomicInteger requestsSinceCleanup = new AtomicInteger();
    private final boolean enabled;

    AuthRateLimitInterceptor(
            @Value("${chessverse.auth.rate-limit.enabled:true}") boolean enabled) {
        this.enabled = enabled;
    }

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler) {
        if (!enabled || !"POST".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        long now = System.nanoTime();
        String path = request.getRequestURI();
        String key = request.getRemoteAddr() + ':' + path;
        RateWindow window = windows.computeIfAbsent(key, ignored -> new RateWindow(now));
        if (!window.tryAcquire(limitFor(path), now)) {
            throw new AuthException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Too many requests. Wait a minute and try again.");
        }

        if (requestsSinceCleanup.incrementAndGet() >= 256) {
            requestsSinceCleanup.set(0);
            windows.entrySet().removeIf(entry -> entry.getValue().expired(now));
        }
        return true;
    }

    private int limitFor(String path) {
        if (path.endsWith("/register")
                || path.endsWith("/resend-verification")
                || path.endsWith("/password/forgot")) {
            return 5;
        }
        if (path.endsWith("/login")) {
            return 10;
        }
        return 20;
    }

    private static final class RateWindow {
        private long startedAt;
        private int count;

        private RateWindow(long startedAt) {
            this.startedAt = startedAt;
        }

        synchronized boolean tryAcquire(int limit, long now) {
            if (expired(now)) {
                startedAt = now;
                count = 0;
            }
            if (count >= limit) {
                return false;
            }
            count++;
            return true;
        }

        synchronized boolean expired(long now) {
            return now - startedAt >= WINDOW.toNanos();
        }
    }
}

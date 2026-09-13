package com.epitomehub.chessverse.api;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Locale;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Enforces the HTTP boundary of each deployable service role while the legacy
 * application is being decomposed. The default {@code all} role preserves the
 * existing single-process deployment.
 */
@Component
final class ServiceBoundaryFilter extends OncePerRequestFilter {
    private static final List<String> SHARED_PATHS = List.of(
            "/actuator/",
            "/api/v1/health");

    private final ServiceRole role;

    ServiceBoundaryFilter(@Value("${chessverse.service.role:all}") String role) {
        this.role = ServiceRole.parse(role);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        String path = request.getRequestURI();
        if (role == ServiceRole.ALL || matches(path, SHARED_PATHS) || matches(path, role.paths)) {
            filterChain.doFilter(request, response);
            return;
        }

        response.sendError(HttpStatus.NOT_FOUND.value());
    }

    private static boolean matches(String path, List<String> prefixes) {
        return prefixes.stream().anyMatch(path::startsWith);
    }

    enum ServiceRole {
        ALL(List.of("/")),
        IDENTITY(List.of(
                "/api/auth",
                "/api/v1/progress",
                "/api/v1/computer-game",
                "/api/v1/ai-bot-presets")),
        PLAY(List.of(
                "/api/v1/games",
                "/api/v1/online",
                "/api/v1/leaderboard",
                "/api/v1/social",
                "/api/v1/community",
                "/api/v1/notifications",
                "/ws/matches/")),
        LEARNING(List.of(
                "/api/v1/engine",
                "/api/v1/coach",
                "/api/v1/speech",
                "/api/v1/analysis",
                "/api/v1/puzzle-sprints")),
        ECONOMY(List.of(
                "/api/v1/economy",
                "/api/v1/purchases",
                "/api/v1/shop",
                "/api/v1/progression")),
        PLATFORM(List.of("/api/contact"));

        private final List<String> paths;

        ServiceRole(List<String> paths) {
            this.paths = paths;
        }

        static ServiceRole parse(String value) {
            try {
                return valueOf(value.trim().toUpperCase(Locale.ROOT));
            } catch (RuntimeException exception) {
                throw new IllegalArgumentException("Unknown chessverse service role: " + value, exception);
            }
        }
    }
}

package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.Map;
import java.util.UUID;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.HandshakeInterceptor;
import org.springframework.web.util.UriTemplate;

@Configuration
@EnableWebSocket
public class OnlineWebSocketConfiguration implements WebSocketConfigurer {
    private static final UriTemplate MATCH_PATH = new UriTemplate("/ws/matches/{matchId}");

    private final OnlineMatchSocketHandler handler;
    private final PlayerAuthenticationService authentication;
    private final OnlineMatchService matches;
    private final WebSocketTicketService tickets;
    private final String[] allowedOriginPatterns;

    public OnlineWebSocketConfiguration(
            OnlineMatchSocketHandler handler,
            PlayerAuthenticationService authentication,
            OnlineMatchService matches,
            WebSocketTicketService tickets,
            @Value("${chessverse.web.allowed-origin-patterns:http://localhost:*,http://127.0.0.1:*}")
            String allowedOriginPatterns) {
        this.handler = handler;
        this.authentication = authentication;
        this.matches = matches;
        this.tickets = tickets;
        this.allowedOriginPatterns = parseAllowedOrigins(allowedOriginPatterns);
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/matches/{matchId}")
                .addInterceptors(new MatchHandshakeInterceptor())
                .setAllowedOriginPatterns(allowedOriginPatterns);
    }

    static String[] parseAllowedOrigins(String configured) {
        String[] origins = java.util.Arrays.stream(configured == null ? new String[0] : configured.split(","))
                .map(String::trim).filter(value -> !value.isBlank()).toArray(String[]::new);
        if (origins.length == 0 || java.util.Arrays.asList(origins).contains("*")) {
            throw new IllegalArgumentException("WebSocket allowed origins must be an explicit allow-list");
        }
        return origins;
    }

    private final class MatchHandshakeInterceptor implements HandshakeInterceptor {
        @Override
        public boolean beforeHandshake(
                ServerHttpRequest request,
                ServerHttpResponse response,
                WebSocketHandler wsHandler,
                Map<String, Object> attributes) {
            try {
                String path = request.getURI().getPath();
                Map<String, String> variables = MATCH_PATH.match(path);
                UUID matchId = UUID.fromString(variables.get("matchId"));
                String authorization = request.getHeaders().getFirst("Authorization");
                UUID playerId;
                if (authorization != null && !authorization.isBlank()) {
                    AuthenticatedPlayer player = authentication.requireBearer(authorization);
                    playerId = player.id();
                } else {
                    String ticket = org.springframework.web.util.UriComponentsBuilder.fromUri(request.getURI())
                            .build().getQueryParams().getFirst("ticket");
                    playerId = tickets.consume(ticket, matchId);
                    if (playerId == null) {
                        response.setStatusCode(HttpStatus.UNAUTHORIZED);
                        return false;
                    }
                }
                if (!matches.isParticipant(playerId, matchId)) {
                    response.setStatusCode(HttpStatus.FORBIDDEN);
                    return false;
                }
                attributes.put("matchId", matchId);
                attributes.put("playerId", playerId);
                return true;
            } catch (RuntimeException exception) {
                response.setStatusCode(HttpStatus.UNAUTHORIZED);
                return false;
            }
        }

        @Override
        public void afterHandshake(
                ServerHttpRequest request,
                ServerHttpResponse response,
                WebSocketHandler wsHandler,
                Exception exception) {
        }
    }
}

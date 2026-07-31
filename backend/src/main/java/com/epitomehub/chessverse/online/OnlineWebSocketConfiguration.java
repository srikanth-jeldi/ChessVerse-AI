package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.Map;
import java.util.UUID;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.server.HandshakeInterceptor;
import org.springframework.web.util.UriTemplate;
import org.springframework.web.util.UriComponentsBuilder;

@Configuration
@EnableWebSocket
public class OnlineWebSocketConfiguration implements WebSocketConfigurer {
    private static final UriTemplate MATCH_PATH = new UriTemplate("/ws/matches/{matchId}");

    private final OnlineMatchSocketHandler handler;
    private final PlayerAuthenticationService authentication;
    private final OnlineMatchService matches;

    public OnlineWebSocketConfiguration(
            OnlineMatchSocketHandler handler,
            PlayerAuthenticationService authentication,
            OnlineMatchService matches) {
        this.handler = handler;
        this.authentication = authentication;
        this.matches = matches;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/matches/{matchId}")
                .addInterceptors(new MatchHandshakeInterceptor())
                .setAllowedOriginPatterns("*");
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
                if (authorization == null || authorization.isBlank()) {
                    String token = UriComponentsBuilder.fromUri(request.getURI())
                            .build()
                            .getQueryParams()
                            .getFirst("access_token");
                    authorization = token == null ? null : "Bearer " + token;
                }
                AuthenticatedPlayer player = authentication.requireBearer(authorization);
                if (!matches.isParticipant(player.id(), matchId)) {
                    response.setStatusCode(HttpStatus.FORBIDDEN);
                    return false;
                }
                attributes.put("matchId", matchId);
                attributes.put("playerId", player.id());
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

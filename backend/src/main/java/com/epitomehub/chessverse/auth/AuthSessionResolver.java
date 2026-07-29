package com.epitomehub.chessverse.auth;

import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class AuthSessionResolver {
    private final AuthService authService;

    AuthSessionResolver(AuthService authService) {
        this.authService = authService;
    }

    public AuthenticatedPlayer requirePlayer(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Sign in to continue.");
        }
        String token = authorization.substring("Bearer ".length()).trim();
        if (token.isEmpty()) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Sign in to continue.");
        }
        AuthDtos.PlayerResponse player = authService.currentPlayer(token);
        return new AuthenticatedPlayer(player.id(), player.username(), player.displayName());
    }

    public record AuthenticatedPlayer(UUID id, String username, String displayName) {
    }
}

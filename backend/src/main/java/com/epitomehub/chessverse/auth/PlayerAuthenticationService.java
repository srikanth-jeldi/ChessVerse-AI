package com.epitomehub.chessverse.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HexFormat;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PlayerAuthenticationService {
    private final AuthSessionRepository sessions;

    public PlayerAuthenticationService(AuthSessionRepository sessions) {
        this.sessions = sessions;
    }

    @Transactional(readOnly = true)
    public AuthenticatedPlayer requireBearer(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Sign in to play online.");
        }
        String token = authorization.substring("Bearer ".length()).trim();
        if (token.isEmpty()) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Sign in to play online.");
        }
        AuthSession session = sessions.findByTokenHash(sha256(token))
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED, "Your session has expired. Sign in again."));
        if (session.revokedAt != null || !session.expiresAt.isAfter(Instant.now())) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Your session has expired. Sign in again.");
        }
        return new AuthenticatedPlayer(
                session.player.id,
                session.player.username,
                session.player.displayName,
                session.player.photoUrl);
    }

    private String sha256(String value) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}

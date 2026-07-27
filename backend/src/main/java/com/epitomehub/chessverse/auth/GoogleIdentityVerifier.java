package com.epitomehub.chessverse.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
class GoogleIdentityVerifier {
    private final String clientId;
    private final GoogleIdTokenVerifier verifier;

    GoogleIdentityVerifier(@Value("${chessverse.oauth.google-web-client-id:}") String clientId) {
        this.clientId = clientId.trim();
        this.verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(this.clientId.isEmpty() ? List.of("not-configured") : List.of(this.clientId))
                .build();
    }

    VerifiedGoogleIdentity verify(String rawToken) {
        if (clientId.isEmpty() || clientId.startsWith("replace-")) {
            throw new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "Google login is not configured.");
        }
        try {
            GoogleIdToken token = verifier.verify(rawToken);
            if (token == null) {
                throw invalidToken();
            }
            GoogleIdToken.Payload payload = token.getPayload();
            if (!Boolean.TRUE.equals(payload.getEmailVerified())
                    || payload.getSubject() == null
                    || payload.getEmail() == null) {
                throw invalidToken();
            }
            Object name = payload.get("name");
            return new VerifiedGoogleIdentity(
                    payload.getSubject(),
                    payload.getEmail(),
                    name instanceof String value ? value : null);
        } catch (GeneralSecurityException | IOException exception) {
            throw invalidToken();
        }
    }

    private AuthException invalidToken() {
        return new AuthException(HttpStatus.UNAUTHORIZED, "Google sign-in could not be verified.");
    }

    record VerifiedGoogleIdentity(String subject, String email, String displayName) {
    }
}

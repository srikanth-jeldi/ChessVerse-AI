package com.epitomehub.chessverse.auth;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Service;

@Service
class OAuthTokenVerifier {
    private final List<String> googleClientIds;
    private final List<String> appleClientIds;

    OAuthTokenVerifier(
            @Value("${chessverse.auth.oauth.google-client-ids:}") String googleClientIds,
            @Value("${chessverse.auth.oauth.apple-client-ids:}") String appleClientIds) {
        this.googleClientIds = splitClientIds(googleClientIds);
        this.appleClientIds = splitClientIds(appleClientIds);
    }

    VerifiedIdentity verify(AuthDtos.OAuthLoginRequest request) {
        String provider = request.provider().toLowerCase(Locale.ROOT);
        ProviderConfiguration configuration = switch (provider) {
            case "google" -> new ProviderConfiguration(
                    "https://accounts.google.com",
                    "https://www.googleapis.com/oauth2/v3/certs",
                    googleClientIds);
            case "apple" -> new ProviderConfiguration(
                    "https://appleid.apple.com",
                    "https://appleid.apple.com/auth/keys",
                    appleClientIds);
            default -> throw new AuthException(HttpStatus.BAD_REQUEST, "Unsupported login provider.");
        };

        if (configuration.clientIds().isEmpty()) {
            throw new AuthException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    providerDisplayName(provider) + " login is not configured on this server.");
        }

        try {
            NimbusJwtDecoder decoder = NimbusJwtDecoder
                    .withJwkSetUri(configuration.jwkSetUri())
                    .build();
            OAuth2TokenValidator<Jwt> issuer =
                    JwtValidators.createDefaultWithIssuer(configuration.issuer());
            OAuth2TokenValidator<Jwt> audience = jwt ->
                    jwt.getAudience().stream().anyMatch(configuration.clientIds()::contains)
                            ? OAuth2TokenValidatorResult.success()
                            : OAuth2TokenValidatorResult.failure(new OAuth2Error(
                                    "invalid_token",
                                    "Identity token audience is not allowed.",
                                    null));
            decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(issuer, audience));
            Jwt jwt = decoder.decode(request.idToken());

            String tokenNonce = jwt.getClaimAsString("nonce");
            if (request.nonce() != null
                    && !request.nonce().isBlank()
                    && !request.nonce().equals(tokenNonce)) {
                throw new AuthException(HttpStatus.UNAUTHORIZED, "Identity token nonce is invalid.");
            }

            String email = jwt.getClaimAsString("email");
            Object verifiedClaim = jwt.getClaims().get("email_verified");
            boolean emailVerified = verifiedClaim == null
                    || Boolean.parseBoolean(verifiedClaim.toString());
            return new VerifiedIdentity(
                    provider,
                    jwt.getSubject(),
                    email == null ? null : email.toLowerCase(Locale.ROOT),
                    emailVerified,
                    request.displayName());
        } catch (AuthException exception) {
            throw exception;
        } catch (JwtException exception) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "The provider identity token is invalid.");
        }
    }

    private List<String> splitClientIds(String value) {
        return Arrays.stream(value.split(","))
                .map(String::trim)
                .filter(item -> !item.isBlank())
                .toList();
    }

    private String providerDisplayName(String provider) {
        return provider.substring(0, 1).toUpperCase(Locale.ROOT) + provider.substring(1);
    }

    record VerifiedIdentity(
            String provider,
            String subject,
            String email,
            boolean emailVerified,
            String displayName) {
    }

    private record ProviderConfiguration(
            String issuer,
            String jwkSetUri,
            List<String> clientIds) {
    }
}

package com.epitomehub.chessverse.auth;

import static com.epitomehub.chessverse.auth.AuthDtos.*;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class AuthService {
    private static final int MAX_OTP_ATTEMPTS = 5;

    private final PlayerAccountRepository players;
    private final EmailVerificationRepository verifications;
    private final AuthSessionRepository sessions;
    private final OtpDelivery otpDelivery;
    private final SmsOtpDelivery smsOtpDelivery;
    private final OAuthIdentityRepository oauthIdentities;
    private final OAuthTokenVerifier oauthTokenVerifier;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(12);
    private final SecureRandom random = new SecureRandom();
    private final Duration otpExpiry;
    private final Duration sessionExpiry;
    private final boolean exposeSmsDevelopmentCode;

    AuthService(
            PlayerAccountRepository players,
            EmailVerificationRepository verifications,
            AuthSessionRepository sessions,
            OtpDelivery otpDelivery,
            SmsOtpDelivery smsOtpDelivery,
            OAuthIdentityRepository oauthIdentities,
            OAuthTokenVerifier oauthTokenVerifier,
            @Value("${chessverse.auth.otp-expiry-minutes:10}") long otpExpiryMinutes,
            @Value("${chessverse.auth.session-expiry-days:30}") long sessionExpiryDays,
            @Value("${chessverse.auth.sms.expose-development-code:false}")
            boolean exposeSmsDevelopmentCode) {
        this.players = players;
        this.verifications = verifications;
        this.sessions = sessions;
        this.otpDelivery = otpDelivery;
        this.smsOtpDelivery = smsOtpDelivery;
        this.oauthIdentities = oauthIdentities;
        this.oauthTokenVerifier = oauthTokenVerifier;
        this.otpExpiry = Duration.ofMinutes(otpExpiryMinutes);
        this.sessionExpiry = Duration.ofDays(sessionExpiryDays);
        this.exposeSmsDevelopmentCode = exposeSmsDevelopmentCode;
    }

    @Transactional
    MessageResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        String username = request.username().trim();

        PlayerAccount player = players.findByEmailIgnoreCase(email).orElse(null);
        if (player != null && player.verified) {
            throw new AuthException(HttpStatus.CONFLICT, "An account already exists for this email.");
        }
        PlayerAccount usernameOwner = players.findByUsernameIgnoreCase(username).orElse(null);
        if (usernameOwner != null && (player == null || !usernameOwner.id.equals(player.id))) {
            throw new AuthException(HttpStatus.CONFLICT, "That user id is already taken.");
        }

        if (player == null) {
            player = new PlayerAccount(
                    username,
                    request.displayName().trim(),
                    email,
                    null,
                    passwordEncoder.encode(request.password()));
        } else {
            player.username = username;
            player.displayName = request.displayName().trim();
            player.passwordHash = passwordEncoder.encode(request.password());
            player.updatedAt = Instant.now();
        }
        players.save(player);

        EmailVerification recent = verifications
                .findFirstByPlayerIdAndConsumedAtIsNullOrderByCreatedAtDesc(player.id)
                .orElse(null);
        if (recent != null && recent.createdAt.isAfter(Instant.now().minusSeconds(60))) {
            throw new AuthException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Please wait one minute before requesting another code.");
        }

        String code = "%06d".formatted(random.nextInt(1_000_000));
        Instant expiresAt = Instant.now().plus(otpExpiry);
        verifications.save(new EmailVerification(player, passwordEncoder.encode(code), expiresAt));
        otpDelivery.sendVerificationCode(player.email, player.displayName, code);
        return new MessageResponse(
                "Verification code sent to " + maskEmail(email),
                expiresAt,
                null);
    }

    @Transactional
    MessageResponse registerPhone(RegisterPhoneRequest request) {
        String phone = request.phone().trim();
        String username = request.username().trim();

        PlayerAccount player = players.findByPhone(phone).orElse(null);
        if (player != null && player.verified) {
            throw new AuthException(HttpStatus.CONFLICT, "An account already exists for this phone number.");
        }
        PlayerAccount usernameOwner = players.findByUsernameIgnoreCase(username).orElse(null);
        if (usernameOwner != null && (player == null || !usernameOwner.id.equals(player.id))) {
            throw new AuthException(HttpStatus.CONFLICT, "That user id is already taken.");
        }

        if (player == null) {
            player = new PlayerAccount(
                    username,
                    request.displayName().trim(),
                    null,
                    phone,
                    passwordEncoder.encode(request.password()));
        } else {
            player.username = username;
            player.displayName = request.displayName().trim();
            player.passwordHash = passwordEncoder.encode(request.password());
            player.updatedAt = Instant.now();
        }
        players.save(player);

        VerificationCode verificationCode = createVerification(player);
        smsOtpDelivery.sendVerificationCode(phone, player.displayName, verificationCode.code());
        return new MessageResponse(
                "Verification code sent to " + maskPhone(phone),
                verificationCode.expiresAt(),
                exposeSmsDevelopmentCode ? verificationCode.code() : null);
    }

    @Transactional
    AuthResponse verify(VerifyRequest request) {
        PlayerAccount player = players.findByEmailIgnoreCase(request.email().trim())
                .orElseThrow(() -> new AuthException(HttpStatus.BAD_REQUEST, "No pending registration found."));
        return verifyCode(player, request.code());
    }

    @Transactional
    AuthResponse verifyPhone(VerifyPhoneRequest request) {
        PlayerAccount player = players.findByPhone(request.phone().trim())
                .orElseThrow(() -> new AuthException(HttpStatus.BAD_REQUEST, "No pending registration found."));
        return verifyCode(player, request.code());
    }

    private AuthResponse verifyCode(PlayerAccount player, String code) {
        EmailVerification verification = verifications
                .findFirstByPlayerIdAndConsumedAtIsNullOrderByCreatedAtDesc(player.id)
                .orElseThrow(() -> new AuthException(HttpStatus.BAD_REQUEST, "No active verification code found."));

        if (verification.expiresAt.isBefore(Instant.now())) {
            throw new AuthException(HttpStatus.GONE, "Verification code expired. Request a new code.");
        }
        if (verification.attempts >= MAX_OTP_ATTEMPTS) {
            throw new AuthException(HttpStatus.TOO_MANY_REQUESTS, "Too many attempts. Request a new code.");
        }
        verification.attempts++;
        if (!passwordEncoder.matches(code, verification.codeHash)) {
            verifications.save(verification);
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Incorrect verification code.");
        }

        verification.consumedAt = Instant.now();
        player.verified = true;
        player.updatedAt = Instant.now();
        verifications.save(verification);
        players.save(player);
        return createSession(player);
    }

    @Transactional
    AuthResponse login(LoginRequest request) {
        String identity = request.identity().trim();
        PlayerAccount player = (identity.startsWith("+")
                ? players.findByPhone(identity)
                : identity.contains("@")
                        ? players.findByEmailIgnoreCase(identity)
                        : players.findByUsernameIgnoreCase(identity))
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED, "Invalid user id or password."));

        if (!player.verified) {
            throw new AuthException(HttpStatus.FORBIDDEN, "Verify your account before signing in.");
        }
        if (!passwordEncoder.matches(request.password(), player.passwordHash)) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Invalid user id or password.");
        }
        return createSession(player);
    }

    @Transactional
    AuthResponse oauthLogin(OAuthLoginRequest request) {
        OAuthTokenVerifier.VerifiedIdentity identity = oauthTokenVerifier.verify(request);
        OAuthIdentity existingIdentity = oauthIdentities
                .findByProviderAndSubject(identity.provider(), identity.subject())
                .orElse(null);
        if (existingIdentity != null) {
            return createSession(existingIdentity.player);
        }
        if (identity.email() == null || !identity.emailVerified()) {
            throw new AuthException(
                    HttpStatus.UNAUTHORIZED,
                    "The provider did not return a verified email address.");
        }

        PlayerAccount player = players.findByEmailIgnoreCase(identity.email()).orElse(null);
        if (player == null) {
            String displayName = identity.displayName() == null || identity.displayName().isBlank()
                    ? identity.email().substring(0, identity.email().indexOf('@'))
                    : identity.displayName().trim();
            player = new PlayerAccount(
                    availableUsername(displayName),
                    displayName,
                    identity.email(),
                    null,
                    passwordEncoder.encode(UUID.randomUUID().toString() + UUID.randomUUID()));
        }
        player.verified = true;
        player.updatedAt = Instant.now();
        players.save(player);
        oauthIdentities.save(new OAuthIdentity(identity.provider(), identity.subject(), player));
        return createSession(player);
    }

    private String availableUsername(String preferredName) {
        String base = preferredName.toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9_.-]", "_")
                .replaceAll("_+", "_")
                .replaceAll("^[_\\-.]+|[_\\-.]+$", "");
        if (base.length() < 3) {
            base = "player";
        }
        base = base.substring(0, Math.min(base.length(), 32));
        String candidate = base;
        while (players.findByUsernameIgnoreCase(candidate).isPresent()) {
            candidate = base + "_" + (1000 + random.nextInt(9000));
        }
        return candidate;
    }

    private AuthResponse createSession(PlayerAccount player) {
        String token = UUID.randomUUID() + "." + UUID.randomUUID();
        Instant expiresAt = Instant.now().plus(sessionExpiry);
        sessions.save(new AuthSession(player, sha256(token), expiresAt));
        return new AuthResponse(token, expiresAt, PlayerResponse.from(player));
    }

    private String sha256(String value) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private String maskEmail(String email) {
        int at = email.indexOf('@');
        String local = email.substring(0, at);
        return local.charAt(0) + "***" + email.substring(at);
    }

    private String maskPhone(String phone) {
        return phone.substring(0, Math.min(3, phone.length() - 4))
                + "****"
                + phone.substring(phone.length() - 4);
    }

    private VerificationCode createVerification(PlayerAccount player) {
        EmailVerification recent = verifications
                .findFirstByPlayerIdAndConsumedAtIsNullOrderByCreatedAtDesc(player.id)
                .orElse(null);
        if (recent != null && recent.createdAt.isAfter(Instant.now().minusSeconds(60))) {
            throw new AuthException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Please wait one minute before requesting another code.");
        }

        String code = "%06d".formatted(random.nextInt(1_000_000));
        Instant expiresAt = Instant.now().plus(otpExpiry);
        verifications.save(new EmailVerification(player, passwordEncoder.encode(code), expiresAt));
        return new VerificationCode(code, expiresAt);
    }

    private record VerificationCode(String code, Instant expiresAt) {
    }
}

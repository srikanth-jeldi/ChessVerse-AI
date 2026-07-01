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
    private static final int MAX_LOGIN_ATTEMPTS = 5;

    private final PlayerAccountRepository players;
    private final EmailVerificationRepository verifications;
    private final PasswordResetRepository passwordResets;
    private final AuthSessionRepository sessions;
    private final OtpDelivery otpDelivery;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(12);
    private final SecureRandom random = new SecureRandom();
    private final Duration otpExpiry;
    private final Duration sessionExpiry;
    private final Duration loginLockout;
    private final Duration resendCooldown;
    private final boolean exposeDevelopmentCode;

    AuthService(
            PlayerAccountRepository players,
            EmailVerificationRepository verifications,
            PasswordResetRepository passwordResets,
            AuthSessionRepository sessions,
            OtpDelivery otpDelivery,
            @Value("${chessverse.auth.otp-expiry-minutes:10}") long otpExpiryMinutes,
            @Value("${chessverse.auth.session-expiry-days:30}") long sessionExpiryDays,
            @Value("${chessverse.auth.login-lockout-minutes:15}") long loginLockoutMinutes,
            @Value("${chessverse.auth.resend-cooldown-seconds:60}") long resendCooldownSeconds,
            @Value("${chessverse.auth.expose-development-code:false}") boolean exposeDevelopmentCode) {
        this.players = players;
        this.verifications = verifications;
        this.passwordResets = passwordResets;
        this.sessions = sessions;
        this.otpDelivery = otpDelivery;
        this.otpExpiry = Duration.ofMinutes(otpExpiryMinutes);
        this.sessionExpiry = Duration.ofDays(sessionExpiryDays);
        this.loginLockout = Duration.ofMinutes(loginLockoutMinutes);
        this.resendCooldown = Duration.ofSeconds(resendCooldownSeconds);
        this.exposeDevelopmentCode = exposeDevelopmentCode;
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
                    passwordEncoder.encode(request.password()));
        } else {
            player.username = username;
            player.displayName = request.displayName().trim();
            player.passwordHash = passwordEncoder.encode(request.password());
            player.updatedAt = Instant.now();
        }
        players.save(player);

        CodeDelivery delivery = createVerificationCode(player);
        return new MessageResponse(
                "Verification code sent to " + maskEmail(email),
                delivery.expiresAt(),
                exposeDevelopmentCode ? delivery.code() : null);
    }

    @Transactional(noRollbackFor = AuthException.class)
    AuthResponse verify(VerifyRequest request) {
        PlayerAccount player = players.findByEmailIgnoreCase(request.email().trim())
                .orElseThrow(() -> new AuthException(HttpStatus.BAD_REQUEST, "No pending registration found."));
        return verifyCode(player, request.code());
    }

    @Transactional
    MessageResponse resendVerification(EmailRequest request) {
        String email = normalizeEmail(request.email());
        PlayerAccount player = players.findByEmailIgnoreCase(email).orElse(null);
        if (player == null || player.verified) {
            return genericCodeResponse();
        }
        CodeDelivery delivery = createVerificationCode(player);
        return new MessageResponse(
                "Verification code sent to " + maskEmail(email),
                delivery.expiresAt(),
                exposeDevelopmentCode ? delivery.code() : null);
    }

    @Transactional
    MessageResponse requestPasswordReset(EmailRequest request) {
        String email = normalizeEmail(request.email());
        PlayerAccount player = players.findByEmailIgnoreCase(email).orElse(null);
        if (player == null || !player.verified) {
            return genericCodeResponse();
        }

        PasswordReset recent = passwordResets
                .findFirstByPlayerIdAndConsumedAtIsNullOrderByCreatedAtDesc(player.id)
                .orElse(null);
        enforceCooldown(recent == null ? null : recent.createdAt);

        String code = newCode();
        Instant expiresAt = Instant.now().plus(otpExpiry);
        passwordResets.save(new PasswordReset(player, passwordEncoder.encode(code), expiresAt));
        otpDelivery.sendPasswordResetCode(player.email, player.displayName, code);
        return new MessageResponse(
                "If an eligible account exists, a reset code has been sent.",
                expiresAt,
                exposeDevelopmentCode ? code : null);
    }

    @Transactional(noRollbackFor = AuthException.class)
    MessageResponse resetPassword(ResetPasswordRequest request) {
        String email = normalizeEmail(request.email());
        PlayerAccount player = players.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new AuthException(HttpStatus.BAD_REQUEST, "Invalid or expired reset request."));
        PasswordReset reset = passwordResets
                .findFirstByPlayerIdAndConsumedAtIsNullOrderByCreatedAtDesc(player.id)
                .orElseThrow(() -> new AuthException(HttpStatus.BAD_REQUEST, "Invalid or expired reset request."));

        if (reset.expiresAt.isBefore(Instant.now())) {
            throw new AuthException(HttpStatus.GONE, "Reset code expired. Request a new code.");
        }
        if (reset.attempts >= MAX_OTP_ATTEMPTS) {
            throw new AuthException(HttpStatus.TOO_MANY_REQUESTS, "Too many attempts. Request a new reset code.");
        }
        reset.attempts++;
        if (!passwordEncoder.matches(request.code(), reset.codeHash)) {
            passwordResets.save(reset);
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Incorrect reset code.");
        }

        reset.consumedAt = Instant.now();
        player.passwordHash = passwordEncoder.encode(request.newPassword());
        player.failedLoginAttempts = 0;
        player.lockedUntil = null;
        player.updatedAt = Instant.now();
        passwordResets.save(reset);
        players.save(player);
        sessions.deleteByPlayerId(player.id);
        return new MessageResponse("Password updated. Sign in with your new password.", null, null);
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

    @Transactional(noRollbackFor = AuthException.class)
    AuthResponse login(LoginRequest request) {
        String identity = request.identity().trim();
        PlayerAccount player = (identity.contains("@")
                ? players.findByEmailIgnoreCase(identity)
                : players.findByUsernameIgnoreCase(identity))
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED, "Invalid user id or password."));

        if (!player.verified) {
            throw new AuthException(HttpStatus.FORBIDDEN, "Verify your account before signing in.");
        }
        Instant now = Instant.now();
        if (player.lockedUntil != null && player.lockedUntil.isAfter(now)) {
            throw new AuthException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Account temporarily locked. Try again later or reset your password.");
        }
        if (player.lockedUntil != null) {
            player.lockedUntil = null;
            player.failedLoginAttempts = 0;
        }
        if (!passwordEncoder.matches(request.password(), player.passwordHash)) {
            player.failedLoginAttempts++;
            if (player.failedLoginAttempts >= MAX_LOGIN_ATTEMPTS) {
                player.lockedUntil = now.plus(loginLockout);
            }
            player.updatedAt = now;
            players.save(player);
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Invalid user id or password.");
        }
        player.failedLoginAttempts = 0;
        player.lockedUntil = null;
        player.updatedAt = now;
        players.save(player);
        return createSession(player);
    }

    @Transactional
    PlayerResponse currentPlayer(String token) {
        String tokenHash = sha256(token);
        AuthSession session = sessions.findByTokenHash(tokenHash)
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED, "Your session is invalid."));
        if (session.expiresAt.isBefore(Instant.now())) {
            sessions.delete(session);
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Your session has expired.");
        }
        return PlayerResponse.from(session.player);
    }

    @Transactional
    void logout(String token) {
        sessions.deleteByTokenHash(sha256(token));
    }

    private AuthResponse createSession(PlayerAccount player) {
        String token = UUID.randomUUID() + "." + UUID.randomUUID();
        Instant expiresAt = Instant.now().plus(sessionExpiry);
        sessions.save(new AuthSession(player, sha256(token), expiresAt));
        return new AuthResponse(token, expiresAt, PlayerResponse.from(player));
    }

    private CodeDelivery createVerificationCode(PlayerAccount player) {
        EmailVerification recent = verifications
                .findFirstByPlayerIdAndConsumedAtIsNullOrderByCreatedAtDesc(player.id)
                .orElse(null);
        enforceCooldown(recent == null ? null : recent.createdAt);

        String code = newCode();
        Instant expiresAt = Instant.now().plus(otpExpiry);
        verifications.save(new EmailVerification(player, passwordEncoder.encode(code), expiresAt));
        otpDelivery.sendVerificationCode(player.email, player.displayName, code);
        return new CodeDelivery(code, expiresAt);
    }

    private void enforceCooldown(Instant mostRecentRequest) {
        if (mostRecentRequest != null && mostRecentRequest.isAfter(Instant.now().minus(resendCooldown))) {
            throw new AuthException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Please wait before requesting another code.");
        }
    }

    private MessageResponse genericCodeResponse() {
        return new MessageResponse(
                "If an eligible account exists, a code has been sent.",
                Instant.now().plus(otpExpiry),
                null);
    }

    private String newCode() {
        return "%06d".formatted(random.nextInt(1_000_000));
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
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

    private record CodeDelivery(String code, Instant expiresAt) {
    }
}

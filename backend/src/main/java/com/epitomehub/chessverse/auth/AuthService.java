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
import org.springframework.jdbc.core.JdbcTemplate;
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
    private final OAuthIdentityRepository oauthIdentities;
    private final GuestInstallationRepository guestInstallations;
    private final GoogleIdentityVerifier googleIdentityVerifier;
    private final FacebookIdentityVerifier facebookIdentityVerifier;
    private final OtpDelivery otpDelivery;
    private final JdbcTemplate jdbcTemplate;
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
            OAuthIdentityRepository oauthIdentities,
            GuestInstallationRepository guestInstallations,
            GoogleIdentityVerifier googleIdentityVerifier,
            FacebookIdentityVerifier facebookIdentityVerifier,
            OtpDelivery otpDelivery,
            JdbcTemplate jdbcTemplate,
            @Value("${chessverse.auth.otp-expiry-minutes:10}") long otpExpiryMinutes,
            @Value("${chessverse.auth.session-expiry-days:30}") long sessionExpiryDays,
            @Value("${chessverse.auth.login-lockout-minutes:15}") long loginLockoutMinutes,
            @Value("${chessverse.auth.resend-cooldown-seconds:60}") long resendCooldownSeconds,
            @Value("${chessverse.auth.expose-development-code:false}") boolean exposeDevelopmentCode) {
        this.players = players;
        this.verifications = verifications;
        this.passwordResets = passwordResets;
        this.sessions = sessions;
        this.oauthIdentities = oauthIdentities;
        this.guestInstallations = guestInstallations;
        this.googleIdentityVerifier = googleIdentityVerifier;
        this.facebookIdentityVerifier = facebookIdentityVerifier;
        this.otpDelivery = otpDelivery;
        this.jdbcTemplate = jdbcTemplate;
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
            if (oauthIdentities.existsByProviderAndPlayer_Id("google", player.id)) {
                throw new AuthException(
                        HttpStatus.CONFLICT,
                        "This email already uses Google sign-in. Continue with Google, or use Forgot password to create a ChessVerseAI password.");
            }
            throw new AuthException(HttpStatus.CONFLICT, "An account already exists for this email. Open Login instead.");
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
    AuthResponse googleLogin(GoogleLoginRequest request) {
        GoogleIdentityVerifier.VerifiedGoogleIdentity google =
                googleIdentityVerifier.verify(request.idToken());
        OAuthIdentity existingIdentity =
                oauthIdentities.findByProviderAndSubject("google", google.subject()).orElse(null);
        if (existingIdentity != null) {
            existingIdentity.player.photoUrl = google.photoUrl();
            existingIdentity.player.updatedAt = Instant.now();
            players.save(existingIdentity.player);
            return createSession(existingIdentity.player);
        }

        String email = normalizeEmail(google.email());
        PlayerAccount player = players.findByEmailIgnoreCase(email).orElse(null);
        if (player == null) {
            String displayName = google.displayName() == null || google.displayName().isBlank()
                    ? email.substring(0, email.indexOf('@'))
                    : google.displayName().trim();
            player = new PlayerAccount(
                    availableGoogleUsername(email),
                    displayName.substring(0, Math.min(displayName.length(), 80)),
                    email,
                    passwordEncoder.encode(UUID.randomUUID().toString()));
        }
        player.verified = true;
        player.failedLoginAttempts = 0;
        player.lockedUntil = null;
        player.photoUrl = google.photoUrl();
        player.updatedAt = Instant.now();
        players.save(player);
        oauthIdentities.save(new OAuthIdentity("google", google.subject(), player));
        return createSession(player);
    }

    @Transactional
    AuthResponse upgradeGuestWithGoogle(String token, GoogleLoginRequest request) {
        AuthSession session = requireSession(token);
        PlayerAccount guest = session.player;
        if (!guest.guestAccount) {
            throw new AuthException(HttpStatus.CONFLICT, "This ChessVerseAI account is already secured.");
        }

        GoogleIdentityVerifier.VerifiedGoogleIdentity google =
                googleIdentityVerifier.verify(request.idToken());
        OAuthIdentity identity =
                oauthIdentities.findByProviderAndSubject("google", google.subject()).orElse(null);
        if (identity != null && !java.util.Objects.equals(identity.player.id, guest.id)) {
            // The secure-account screen is itself a Google sign-in surface. If
            // the selected Google identity already owns an account, complete
            // that sign-in instead of trapping the user on the guest-upgrade
            // page. The numbered guest remains attached to the installation,
            // so none of its progress is overwritten or deleted.
            identity.player.photoUrl = google.photoUrl();
            identity.player.updatedAt = Instant.now();
            players.save(identity.player);
            return createSession(identity.player);
        }

        String email = normalizeEmail(google.email());
        PlayerAccount emailOwner = players.findByEmailIgnoreCase(email).orElse(null);
        if (emailOwner != null && !emailOwner.id.equals(guest.id)) {
            throw new AuthException(
                    HttpStatus.CONFLICT,
                    "That email already has a ChessVerseAI account. Sign in to that account; your guest progress remains safe on this device.");
        }

        String displayName = google.displayName() == null || google.displayName().isBlank()
                ? email.substring(0, email.indexOf('@'))
                : google.displayName().trim();
        guest.username = availableGoogleUsername(email);
        guest.displayName = displayName.substring(0, Math.min(displayName.length(), 80));
        guest.email = email;
        guest.photoUrl = google.photoUrl();
        guest.guestAccount = false;
        guest.verified = true;
        guest.failedLoginAttempts = 0;
        guest.lockedUntil = null;
        guest.updatedAt = Instant.now();
        players.save(guest);
        if (identity == null) {
            oauthIdentities.save(new OAuthIdentity("google", google.subject(), guest));
        }
        sessions.deleteByPlayerId(guest.id);
        return createSession(guest);
    }

    @Transactional
    AuthResponse facebookLogin(FacebookLoginRequest request) {
        FacebookIdentityVerifier.VerifiedFacebookIdentity facebook =
                facebookIdentityVerifier.verify(request.accessToken());
        return oauthLogin(
                "facebook",
                facebook.subject(),
                facebook.email(),
                facebook.displayName(),
                facebook.photoUrl());
    }

    @Transactional
    AuthResponse upgradeGuestWithFacebook(String token, FacebookLoginRequest request) {
        FacebookIdentityVerifier.VerifiedFacebookIdentity facebook =
                facebookIdentityVerifier.verify(request.accessToken());
        return upgradeGuestWithOAuth(
                token,
                "facebook",
                facebook.subject(),
                facebook.email(),
                facebook.displayName(),
                facebook.photoUrl());
    }

    private AuthResponse oauthLogin(
            String provider,
            String subject,
            String rawEmail,
            String rawDisplayName,
            String photoUrl) {
        OAuthIdentity existingIdentity =
                oauthIdentities.findByProviderAndSubject(provider, subject).orElse(null);
        if (existingIdentity != null) {
            existingIdentity.player.photoUrl = photoUrl;
            existingIdentity.player.updatedAt = Instant.now();
            players.save(existingIdentity.player);
            return createSession(existingIdentity.player);
        }

        String email = normalizeEmail(rawEmail);
        PlayerAccount player = players.findByEmailIgnoreCase(email).orElse(null);
        if (player == null) {
            String displayName = oauthDisplayName(rawDisplayName, email);
            player = new PlayerAccount(
                    availableGoogleUsername(email),
                    displayName,
                    email,
                    passwordEncoder.encode(UUID.randomUUID().toString()));
        }
        player.verified = true;
        player.failedLoginAttempts = 0;
        player.lockedUntil = null;
        player.photoUrl = photoUrl;
        player.updatedAt = Instant.now();
        players.save(player);
        oauthIdentities.save(new OAuthIdentity(provider, subject, player));
        return createSession(player);
    }

    private AuthResponse upgradeGuestWithOAuth(
            String token,
            String provider,
            String subject,
            String rawEmail,
            String rawDisplayName,
            String photoUrl) {
        AuthSession session = requireSession(token);
        PlayerAccount guest = session.player;
        if (!guest.guestAccount) {
            throw new AuthException(HttpStatus.CONFLICT, "This ChessVerseAI account is already secured.");
        }
        OAuthIdentity identity =
                oauthIdentities.findByProviderAndSubject(provider, subject).orElse(null);
        if (identity != null && !java.util.Objects.equals(identity.player.id, guest.id)) {
            identity.player.photoUrl = photoUrl;
            identity.player.updatedAt = Instant.now();
            players.save(identity.player);
            return createSession(identity.player);
        }

        String email = normalizeEmail(rawEmail);
        PlayerAccount emailOwner = players.findByEmailIgnoreCase(email).orElse(null);
        if (emailOwner != null && !emailOwner.id.equals(guest.id)) {
            throw new AuthException(
                    HttpStatus.CONFLICT,
                    "That email already has a ChessVerseAI account. Sign in to that account; your guest progress remains safe on this device.");
        }
        guest.username = availableGoogleUsername(email);
        guest.displayName = oauthDisplayName(rawDisplayName, email);
        guest.email = email;
        guest.photoUrl = photoUrl;
        guest.guestAccount = false;
        guest.verified = true;
        guest.failedLoginAttempts = 0;
        guest.lockedUntil = null;
        guest.updatedAt = Instant.now();
        players.save(guest);
        if (identity == null) oauthIdentities.save(new OAuthIdentity(provider, subject, guest));
        sessions.deleteByPlayerId(guest.id);
        return createSession(guest);
    }

    private String oauthDisplayName(String rawDisplayName, String email) {
        String displayName = rawDisplayName == null || rawDisplayName.isBlank()
                ? email.substring(0, email.indexOf('@'))
                : rawDisplayName.trim();
        return displayName.substring(0, Math.min(displayName.length(), 80));
    }

    @Transactional
    AuthResponse guestLogin(GuestLoginRequest request) {
        String installationHash = sha256(
                UUID.fromString(request.installationId()).toString().toLowerCase(Locale.ROOT));
        GuestInstallation installation = guestInstallations
                .findWithPlayerByInstallationHash(installationHash)
                .orElse(null);
        PlayerAccount player;
        if (installation == null) {
            String number = availableGuestNumber();
            player = new PlayerAccount(
                    "guest_" + number,
                    "Guest " + number,
                    null,
                    passwordEncoder.encode(UUID.randomUUID().toString()));
            player.verified = true;
            player.guestAccount = true;
            players.save(player);
            installation = new GuestInstallation(installationHash, player);
        } else {
            player = installation.player;
            installation.lastSeenAt = Instant.now();
        }
        guestInstallations.save(installation);
        sessions.deleteByPlayerId(player.id);
        return createSession(player);
    }

    @Transactional
    PlayerResponse currentPlayer(String token) {
        return PlayerResponse.from(requireSession(token).player);
    }

    @Transactional
    void logout(String token) {
        sessions.deleteByTokenHash(sha256(token));
    }

    @Transactional
    void deleteAccount(String token) {
        PlayerAccount player = requireSession(token).player;
        // Remove managed sessions first. Otherwise Hibernate can flush the
        // authenticated session after its player has already been deleted.
        sessions.deleteByPlayerId(player.id);
        sessions.flush();
        jdbcTemplate.update(
                "delete from online_match where white_player_id = ? or black_player_id = ?",
                player.id,
                player.id);
        jdbcTemplate.update("delete from player_completed_puzzle where player_id = ?", player.id);
        jdbcTemplate.update("delete from player_completed_daily_challenge where player_id = ?", player.id);
        jdbcTemplate.update("delete from player_cloud_progress where player_id = ?", player.id);
        jdbcTemplate.update("delete from online_player_rating where player_id = ?", player.id);
        jdbcTemplate.update("delete from guest_installation where player_id = ?", player.id);
        jdbcTemplate.update("delete from oauth_identity where player_id = ?", player.id);
        jdbcTemplate.update("delete from password_reset where player_id = ?", player.id);
        jdbcTemplate.update("delete from email_verification where player_id = ?", player.id);
        players.delete(player);
        players.flush();
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

    private String availableGoogleUsername(String email) {
        String base = email.substring(0, email.indexOf('@'))
                .replaceAll("[^A-Za-z0-9_.-]", "_");
        if (base.length() < 3) {
            base = "player_" + base;
        }
        base = base.substring(0, Math.min(base.length(), 32));
        String candidate = base;
        int suffix = 1;
        while (players.findByUsernameIgnoreCase(candidate).isPresent()) {
            candidate = base + "_" + suffix++;
        }
        return candidate;
    }

    private AuthSession requireSession(String token) {
        AuthSession session = sessions.findByTokenHash(sha256(token))
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED, "Your session is invalid."));
        if (session.expiresAt.isBefore(Instant.now())) {
            sessions.delete(session);
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Your session has expired.");
        }
        return session;
    }

    private String availableGuestNumber() {
        for (int attempt = 0; attempt < 100; attempt++) {
            String number = "%06d".formatted(random.nextInt(1_000_000));
            if (players.findByUsernameIgnoreCase("guest_" + number).isEmpty()) {
                return number;
            }
        }
        return UUID.randomUUID().toString().replace("-", "").substring(0, 10);
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

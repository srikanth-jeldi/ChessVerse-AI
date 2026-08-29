package com.epitomehub.chessverse.auth;

import static com.epitomehub.chessverse.auth.AuthDtos.*;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
class AuthController {
    private final AuthService authService;

    AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.ACCEPTED)
    MessageResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/verify-email")
    AuthResponse verify(@Valid @RequestBody VerifyRequest request) {
        return authService.verify(request);
    }

    @PostMapping("/resend-verification")
    @ResponseStatus(HttpStatus.ACCEPTED)
    MessageResponse resendVerification(@Valid @RequestBody EmailRequest request) {
        return authService.resendVerification(request);
    }

    @PostMapping("/login")
    AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/refresh")
    AuthResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return authService.refresh(request);
    }

    @PostMapping("/google")
    AuthResponse googleLogin(@Valid @RequestBody GoogleLoginRequest request) {
        return authService.googleLogin(request);
    }

    @PostMapping("/google/upgrade")
    AuthResponse upgradeGuestWithGoogle(
            @RequestHeader(name = "Authorization", required = false) String authorization,
            @Valid @RequestBody GoogleLoginRequest request) {
        return authService.upgradeGuestWithGoogle(bearerToken(authorization), request);
    }

    @PostMapping("/facebook")
    AuthResponse facebookLogin(@Valid @RequestBody FacebookLoginRequest request) {
        return authService.facebookLogin(request);
    }

    @PostMapping("/facebook/upgrade")
    AuthResponse upgradeGuestWithFacebook(
            @RequestHeader(name = "Authorization", required = false) String authorization,
            @Valid @RequestBody FacebookLoginRequest request) {
        return authService.upgradeGuestWithFacebook(bearerToken(authorization), request);
    }

    @PostMapping("/guest")
    AuthResponse guestLogin(@Valid @RequestBody GuestLoginRequest request) {
        return authService.guestLogin(request);
    }

    @PostMapping("/password/forgot")
    @ResponseStatus(HttpStatus.ACCEPTED)
    MessageResponse forgotPassword(@Valid @RequestBody EmailRequest request) {
        return authService.requestPasswordReset(request);
    }

    @PostMapping("/password/reset")
    MessageResponse resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        return authService.resetPassword(request);
    }

    @GetMapping("/me")
    PlayerResponse currentPlayer(@RequestHeader(name = "Authorization", required = false) String authorization) {
        return authService.currentPlayer(bearerToken(authorization));
    }

    @PostMapping("/profile")
    PlayerResponse updateProfile(
            @RequestHeader(name = "Authorization", required = false) String authorization,
            @Valid @RequestBody UpdateProfileRequest request) {
        return authService.updateProfile(bearerToken(authorization), request);
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void logout(@RequestHeader(name = "Authorization", required = false) String authorization) {
        authService.logout(bearerToken(authorization));
    }

    @GetMapping("/sessions")
    List<DeviceSessionResponse> sessions(
            @RequestHeader(name = "Authorization", required = false) String authorization) {
        return authService.deviceSessions(bearerToken(authorization));
    }

    @DeleteMapping("/sessions/{sessionId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void revokeSession(
            @RequestHeader(name = "Authorization", required = false) String authorization,
            @PathVariable UUID sessionId) {
        authService.revokeDeviceSession(bearerToken(authorization), sessionId);
    }

    @PostMapping("/logout-all")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void logoutAll(@RequestHeader(name = "Authorization", required = false) String authorization) {
        authService.logoutAll(bearerToken(authorization));
    }

    @DeleteMapping("/account")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void deleteAccount(@RequestHeader(name = "Authorization", required = false) String authorization) {
        authService.deleteAccount(bearerToken(authorization));
    }

    // Keep the REST DELETE route above for existing clients, and offer a POST
    // variant for mobile networks/proxies that reject DELETE requests.
    @PostMapping("/account/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void deleteAccountFromMobile(
            @RequestHeader(name = "Authorization", required = false) String authorization) {
        authService.deleteAccount(bearerToken(authorization));
    }

    private String bearerToken(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Sign in to continue.");
        }
        String token = authorization.substring("Bearer ".length()).trim();
        if (token.isEmpty()) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "Sign in to continue.");
        }
        return token;
    }
}

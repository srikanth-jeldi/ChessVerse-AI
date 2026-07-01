package com.epitomehub.chessverse.auth;

import static com.epitomehub.chessverse.auth.AuthDtos.*;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

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

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void logout(@RequestHeader(name = "Authorization", required = false) String authorization) {
        authService.logout(bearerToken(authorization));
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

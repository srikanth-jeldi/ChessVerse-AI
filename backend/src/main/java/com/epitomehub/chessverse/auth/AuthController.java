package com.epitomehub.chessverse.auth;

import static com.epitomehub.chessverse.auth.AuthDtos.*;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
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

    @PostMapping("/register-phone")
    @ResponseStatus(HttpStatus.ACCEPTED)
    MessageResponse registerPhone(@Valid @RequestBody RegisterPhoneRequest request) {
        return authService.registerPhone(request);
    }

    @PostMapping("/verify-email")
    AuthResponse verify(@Valid @RequestBody VerifyRequest request) {
        return authService.verify(request);
    }

    @PostMapping("/verify-phone")
    AuthResponse verifyPhone(@Valid @RequestBody VerifyPhoneRequest request) {
        return authService.verifyPhone(request);
    }

    @PostMapping("/login")
    AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/oauth")
    AuthResponse oauthLogin(@Valid @RequestBody OAuthLoginRequest request) {
        return authService.oauthLogin(request);
    }
}

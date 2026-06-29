package com.epitomehub.chessverse.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

final class AuthDtos {
    private AuthDtos() {
    }

    record RegisterRequest(
            @NotBlank @Size(min = 3, max = 40)
            @Pattern(regexp = "^[A-Za-z0-9_.-]+$", message = "use letters, numbers, dot, dash or underscore")
            String username,
            @NotBlank @Size(min = 2, max = 80) String displayName,
            @NotBlank @Email @Size(max = 254) String email,
            @NotBlank @Size(min = 8, max = 72) String password) {
    }

    record VerifyRequest(
            @NotBlank @Email String email,
            @NotBlank @Pattern(regexp = "^\\d{6}$") String code) {
    }

    record LoginRequest(
            @NotBlank String identity,
            @NotBlank @Size(max = 72) String password) {
    }

    record MessageResponse(String message, Instant expiresAt, String developmentCode) {
    }

    record AuthResponse(String token, Instant expiresAt, PlayerResponse player) {
    }

    record PlayerResponse(
            UUID id,
            String username,
            String displayName,
            String email) {
        static PlayerResponse from(PlayerAccount player) {
            return new PlayerResponse(
                    player.id,
                    player.username,
                    player.displayName,
                    player.email);
        }
    }
}

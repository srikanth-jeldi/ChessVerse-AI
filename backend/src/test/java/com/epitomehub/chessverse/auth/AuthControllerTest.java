package com.epitomehub.chessverse.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerTest {
    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    TestOtpDelivery otpDelivery;

    @Test
    void registrationCreatesPendingAccountAndSendsOtp() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "srikanth",
                                  "displayName": "Srikanth",
                                  "email": "player@example.com",
                                  "password": "StrongPass123"
                                }
                                """))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").value("Verification code sent to p***@example.com"))
                .andExpect(jsonPath("$.expiresAt").exists());

    }

    @Test
    void loginRejectsUnknownAccount() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "identity": "missing",
                                  "password": "StrongPass123"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid user id or password."));
    }

    @Test
    void verifiedSessionCanBeRestoredAndLoggedOut() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "session_player",
                                  "displayName": "Session Player",
                                  "email": "session@example.com",
                                  "password": "StrongPass123"
                                }
                                """))
                .andExpect(status().isAccepted());

        MvcResult verification = mockMvc.perform(post("/api/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "session@example.com",
                                  "code": "%s"
                                }
                                """.formatted(otpDelivery.latestVerificationCode)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.player.displayName").value("Session Player"))
                .andReturn();

        String token = objectMapper.readTree(verification.getResponse().getContentAsString())
                .path("token")
                .asText();

        mockMvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("session_player"));

        mockMvc.perform(post("/api/auth/logout").header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void passwordResetRevokesExistingPasswordAndAcceptsNewPassword() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "reset_player",
                                  "displayName": "Reset Player",
                                  "email": "reset@example.com",
                                  "password": "StrongPass123"
                                }
                                """))
                .andExpect(status().isAccepted());

        mockMvc.perform(post("/api/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "reset@example.com",
                                  "code": "%s"
                                }
                                """.formatted(otpDelivery.latestVerificationCode)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/password/forgot")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"reset@example.com\"}"))
                .andExpect(status().isAccepted());

        mockMvc.perform(post("/api/auth/password/reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "reset@example.com",
                                  "code": "%s",
                                  "newPassword": "NewStrongPass456"
                                }
                                """.formatted(otpDelivery.latestResetCode)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Password updated. Sign in with your new password."));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identity\":\"reset_player\",\"password\":\"StrongPass123\"}"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identity\":\"reset_player\",\"password\":\"NewStrongPass456\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void repeatedLoginFailuresTemporarilyLockAccount() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "locked_player",
                                  "displayName": "Locked Player",
                                  "email": "locked@example.com",
                                  "password": "StrongPass123"
                                }
                                """))
                .andExpect(status().isAccepted());

        mockMvc.perform(post("/api/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "locked@example.com",
                                  "code": "%s"
                                }
                                """.formatted(otpDelivery.latestVerificationCode)))
                .andExpect(status().isOk());

        for (int attempt = 0; attempt < 5; attempt++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"identity\":\"locked_player\",\"password\":\"WrongPass123\"}"))
                    .andExpect(status().isUnauthorized());
        }

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"identity\":\"locked_player\",\"password\":\"StrongPass123\"}"))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.message").value(
                        "Account temporarily locked. Try again later or reset your password."));
    }

    @TestConfiguration
    static class TestOtpConfiguration {
        @Bean
        @Primary
        TestOtpDelivery testOtpDelivery() {
            return new TestOtpDelivery();
        }
    }

    static class TestOtpDelivery implements OtpDelivery {
        String latestVerificationCode;
        String latestResetCode;

        @Override
        public void sendVerificationCode(String email, String displayName, String code) {
            if (!code.matches("\\d{6}")) {
                throw new AssertionError("OTP must contain six digits");
            }
            latestVerificationCode = code;
        }

        @Override
        public void sendPasswordResetCode(String email, String displayName, String code) {
            if (!code.matches("\\d{6}")) {
                throw new AssertionError("OTP must contain six digits");
            }
            latestResetCode = code;
        }
    }
}

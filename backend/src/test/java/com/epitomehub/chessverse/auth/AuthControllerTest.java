package com.epitomehub.chessverse.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerTest {
    @Autowired
    MockMvc mockMvc;

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
    void phoneRegistrationUsesSmsDelivery() throws Exception {
        mockMvc.perform(post("/api/auth/register-phone")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "username": "phone_player",
                                  "displayName": "Phone Player",
                                  "phone": "+919876543210",
                                  "password": "StrongPass123"
                                }
                                """))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").value("Verification code sent to +91****3210"))
                .andExpect(jsonPath("$.expiresAt").exists())
                .andExpect(jsonPath("$.developmentCode").doesNotExist());
    }

    @Test
    void oauthLoginRequiresConfiguredProviderClientIds() throws Exception {
        mockMvc.perform(post("/api/auth/oauth")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "provider": "google",
                                  "idToken": "not-a-real-token",
                                  "displayName": "Google Player"
                                }
                                """))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.message").value(
                        "Google login is not configured on this server."));
    }

    @TestConfiguration
    static class TestOtpConfiguration {
        @Bean
        @Primary
        OtpDelivery testOtpDelivery() {
            return (email, displayName, code) -> {
                if (!code.matches("\\d{6}")) {
                    throw new AssertionError("OTP must contain six digits");
                }
            };
        }

        @Bean
        @Primary
        SmsOtpDelivery testSmsOtpDelivery() {
            return (phone, displayName, code) -> {
                if (!phone.startsWith("+") || !code.matches("\\d{6}")) {
                    throw new AssertionError("SMS OTP payload is invalid");
                }
            };
        }
    }
}

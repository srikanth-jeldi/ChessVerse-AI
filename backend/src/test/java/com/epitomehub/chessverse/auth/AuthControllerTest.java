package com.epitomehub.chessverse.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.mockito.Mockito.when;

import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
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

    @MockitoBean
    GoogleIdentityVerifier googleIdentityVerifier;

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
    void guestInstallationRestoresSameNumberedPlayerAndSession() throws Exception {
        String request = "{\"installationId\":\"550e8400-e29b-41d4-a716-446655440000\"}";
        MvcResult first = mockMvc.perform(post("/api/auth/guest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.player.guest").value(true))
                .andExpect(jsonPath("$.player.username").value(org.hamcrest.Matchers.matchesPattern("guest_[0-9]{6}")))
                .andReturn();
        String firstPlayerId = objectMapper.readTree(first.getResponse().getContentAsString())
                .path("player").path("id").asText();

        mockMvc.perform(post("/api/auth/guest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.player.id").value(firstPlayerId));
    }

    @Test
    void guestUpgradeKeepsPlayerIdAndMakesInstallationPermanent() throws Exception {
        String request = "{\"installationId\":\"9b2b103d-8d66-4bf5-9e91-ef5578f20c0a\"}";
        MvcResult guestLogin = mockMvc.perform(post("/api/auth/guest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isOk())
                .andReturn();
        var guestJson = objectMapper.readTree(guestLogin.getResponse().getContentAsString());
        String playerId = guestJson.path("player").path("id").asText();
        String guestToken = guestJson.path("token").asText();
        when(googleIdentityVerifier.verify("verified-google-token"))
                .thenReturn(new GoogleIdentityVerifier.VerifiedGoogleIdentity(
                        "google-subject-upgrade",
                        "permanent@example.com",
                        "Permanent Player",
                        "https://example.com/avatar.png"));

        mockMvc.perform(post("/api/auth/google/upgrade")
                        .header("Authorization", "Bearer " + guestToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"verified-google-token\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.player.id").value(playerId))
                .andExpect(jsonPath("$.player.guest").value(false))
                .andExpect(jsonPath("$.player.email").value("permanent@example.com"))
                .andExpect(jsonPath("$.player.displayName").value("Permanent Player"));

        mockMvc.perform(post("/api/auth/guest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.player.id").value(playerId))
                .andExpect(jsonPath("$.player.guest").value(false));
    }

    @Test
    void guestUpgradeWithExistingGoogleIdentitySignsIntoExistingAccount() throws Exception {
        when(googleIdentityVerifier.verify("existing-google-token"))
                .thenReturn(new GoogleIdentityVerifier.VerifiedGoogleIdentity(
                        "existing-google-subject",
                        "existing-google@example.com",
                        "Existing Google Player",
                        "https://example.com/existing-avatar.png"));

        MvcResult googleLogin = mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"existing-google-token\"}"))
                .andExpect(status().isOk())
                .andReturn();
        String existingUsername = objectMapper.readTree(googleLogin.getResponse().getContentAsString())
                .path("player").path("username").asText();

        MvcResult guestLogin = mockMvc.perform(post("/api/auth/guest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"installationId\":\"c533df6b-55b6-40e5-a132-4d691a170501\"}"))
                .andExpect(status().isOk())
                .andReturn();
        String guestToken = objectMapper.readTree(guestLogin.getResponse().getContentAsString())
                .path("token").asText();

        mockMvc.perform(post("/api/auth/google/upgrade")
                        .header("Authorization", "Bearer " + guestToken)
                        .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"existing-google-token\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.player.username").value(existingUsername))
                .andExpect(jsonPath("$.player.guest").value(false))
                .andExpect(jsonPath("$.player.email").value("existing-google@example.com"));
    }

    @Test
    void cloudProgressMergeUnionsPuzzleAndDailyProgressAcrossDevices() throws Exception {
        MvcResult guestLogin = mockMvc.perform(post("/api/auth/guest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"installationId\":\"35e69b70-f69a-4b78-84b6-6dc337e7905f\"}"))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(guestLogin.getResponse().getContentAsString())
                .path("token").asText();

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/api/v1/progress")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "profileUsername":"cloud_player",
                                  "country":"India",
                                  "chessLevel":2,
                                  "avatar":3,
                                  "profileUpdatedAt":"2026-07-30T09:00:00Z",
                                  "dailyStreak":4,
                                  "lastDailyCompletedAt":"2026-07-30T10:00:00Z",
                                  "completedPuzzleIds":["easy-1"],
                                  "completedDailyChallengeIds":["daily-2026-07-30"]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completedPuzzleIds[0]").value("easy-1"));

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/api/v1/progress")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "profileUsername":"cloud_player",
                                  "country":"India",
                                  "chessLevel":2,
                                  "avatar":3,
                                  "profileUpdatedAt":"2026-07-29T09:00:00Z",
                                  "dailyStreak":2,
                                  "lastDailyCompletedAt":"2026-07-29T10:00:00Z",
                                  "completedPuzzleIds":["medium-2"],
                                  "completedDailyChallengeIds":["daily-2026-07-29"]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dailyStreak").value(4))
                .andExpect(jsonPath("$.completedPuzzleIds.length()").value(2))
                .andExpect(jsonPath("$.completedDailyChallengeIds.length()").value(2))
                .andExpect(jsonPath("$.lastDailyCompletedAt").value("2026-07-30T10:00:00Z"));
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

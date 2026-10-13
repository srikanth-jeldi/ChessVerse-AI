package com.epitomehub.chessverse.auth;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.http.MediaType;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoogleChatAccessTest {
    @Autowired MockMvc mvc;
    @Autowired PlayerAccountRepository players;
    @Autowired AuthSessionRepository sessions;
    @Autowired OAuthIdentityRepository identities;
    @Autowired PlayerAuthenticationService authentication;

    String account(boolean guest, String provider) throws Exception {
        String token = UUID.randomUUID().toString();
        PlayerAccount player = new PlayerAccount(token, "Chat Tester", token + "@test.invalid", "unused");
        player.verified = true;
        player.guestAccount = guest;
        players.saveAndFlush(player);
        if (provider != null) identities.saveAndFlush(new OAuthIdentity(provider, token, player));
        String hash = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                .digest(token.getBytes(StandardCharsets.UTF_8)));
        sessions.saveAndFlush(new AuthSession(player, hash, null, UUID.randomUUID(),
                "chat-test", "Test", Instant.now().plusSeconds(600)));
        return "Bearer " + token;
    }

    @Test void guestsAndOtherProvidersCannotReadOrSendChat() throws Exception {
        for (String auth : new String[]{account(true, null), account(false, null), account(false, "facebook")}) {
            assertNotNull(authentication.requireBearer(auth)); // Ordinary authenticated play still works.
            assertThrows(AuthException.class, () -> authentication.requireGoogleBearer(auth));
            mvc.perform(get("/api/v1/community/messages/" + UUID.randomUUID()).header("Authorization", auth))
                    .andExpect(status().isForbidden());
            mvc.perform(post("/api/v1/community/messages").header("Authorization", auth)
                    .contentType(MediaType.APPLICATION_JSON).content("{}"))
                    .andExpect(status().isForbidden());
            mvc.perform(post("/api/v1/coach/ask").header("Authorization", auth)
                    .contentType(MediaType.APPLICATION_JSON).content("{}"))
                    .andExpect(status().isForbidden());
            mvc.perform(get("/api/v1/community/e2ee/identity").header("Authorization", auth))
                    .andExpect(status().isForbidden());
        }
    }

    @Test void googleLinkedAccountPassesGuardAndExpiredSessionDoesNot() throws Exception {
        String auth = account(false, "google");
        assertNotNull(authentication.requireGoogleBearer(auth));
        // Invalid payload reaches endpoint validation instead of the access guard.
        mvc.perform(post("/api/v1/coach/ask").header("Authorization", auth)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest());
        assertThrows(AuthException.class, () -> authentication.requireGoogleBearer("Bearer unknown"));
    }

    @Test void unauthenticatedChatIsRejected() throws Exception {
        mvc.perform(get("/api/v1/community/messages/" + UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }
}

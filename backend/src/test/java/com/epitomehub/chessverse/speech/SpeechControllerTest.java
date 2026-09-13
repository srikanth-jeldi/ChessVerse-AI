package com.epitomehub.chessverse.speech;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;

class SpeechControllerTest {
    @Test
    void requiresBearerBeforeSynthesizingAndReturnsPrivateAudio() {
        PlayerAuthenticationService authentication = mock(PlayerAuthenticationService.class);
        when(authentication.requireBearer("Bearer session-token"))
                .thenReturn(new AuthenticatedPlayer(UUID.randomUUID(), "guest", "Guest", null));
        AzureSpeechGateway gateway = ssml -> new byte[] {1, 2, 3};
        SpeechController controller = new SpeechController(
                authentication, new SpeechSynthesisService(gateway));

        var response = controller.synthesize(
                "Bearer session-token", new SpeechController.SpeechRequest("Castle early", "en"));

        verify(authentication).requireBearer("Bearer session-token");
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertArrayEquals(new byte[] {1, 2, 3}, response.getBody());
        assertEquals("audio/mpeg", response.getHeaders().getContentType().toString());
        assertEquals("no-store", response.getHeaders().getCacheControl());
        assertEquals(HttpHeaders.AUTHORIZATION, response.getHeaders().getFirst(HttpHeaders.VARY));
        assertNull(response.getHeaders().getFirst("Ocp-Apim-Subscription-Key"));
    }
}

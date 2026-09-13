package com.epitomehub.chessverse.speech;

import static org.junit.jupiter.api.Assertions.*;

import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class SpeechSynthesisServiceTest {
    @Test
    void escapesSsmlAndCachesIdenticalNarration() {
        AtomicInteger calls = new AtomicInteger();
        StringBuilder captured = new StringBuilder();
        AzureSpeechGateway gateway = ssml -> {
            calls.incrementAndGet();
            captured.append(ssml);
            return "audio".getBytes(StandardCharsets.UTF_8);
        };
        SpeechSynthesisService service = new SpeechSynthesisService(gateway);

        var first = service.synthesize("King < Queen & Rook", "te-IN");
        var second = service.synthesize("King < Queen & Rook", "te");

        assertEquals(1, calls.get());
        assertFalse(first.cacheHit());
        assertTrue(second.cacheHit());
        assertEquals("te-IN-ShrutiNeural", first.voice());
        assertTrue(captured.toString().contains("King &lt; Queen &amp; Rook"));
        assertFalse(captured.toString().contains("King < Queen"));
    }

    @Test
    void rejectsUnsupportedLanguageAndOversizedTextBeforeCallingAzure() {
        AtomicInteger calls = new AtomicInteger();
        SpeechSynthesisService service = new SpeechSynthesisService(ssml -> {
            calls.incrementAndGet();
            return new byte[] {1};
        });

        SpeechException unsupported = assertThrows(SpeechException.class,
                () -> service.synthesize("hello", "xx-XX"));
        SpeechException oversized = assertThrows(SpeechException.class,
                () -> service.synthesize("x".repeat(2401), "en"));

        assertEquals(HttpStatus.BAD_REQUEST, unsupported.status());
        assertEquals(HttpStatus.BAD_REQUEST, oversized.status());
        assertEquals(0, calls.get());
    }

    @Test
    void everyAppLanguageHasAnExplicitNeuralVoice() {
        String[] languages = {"en", "te", "hi", "ta", "kn", "ml", "mr", "bn", "gu", "pa", "ur",
                "ar", "es", "fr", "de", "it", "pt", "ru", "uk", "tr", "fa", "zh", "ja", "ko",
                "id", "ms", "th", "vi", "pl", "nl", "sv", "el", "he", "sw"};
        for (String language : languages) {
            var voice = SpeechVoiceCatalog.resolve(language);
            assertNotNull(voice, language);
            assertTrue(voice.name().endsWith("Neural"), language);
        }
    }
}

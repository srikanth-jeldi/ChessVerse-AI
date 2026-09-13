package com.epitomehub.chessverse.speech;

import static org.junit.jupiter.api.Assertions.*;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class SpeechSecretBoundaryTest {
    @Test
    void azureCredentialNamesNeverEnterFlutterSources() throws IOException {
        Path mobileSources = Path.of("..", "mobile", "lib");
        if (!Files.isDirectory(mobileSources)) return;
        try (var paths = Files.walk(mobileSources)) {
            for (Path path : paths.filter(value -> value.toString().endsWith(".dart")).toList()) {
                String source = Files.readString(path);
                assertFalse(source.contains("AZURE_SPEECH_KEY"), path.toString());
                assertFalse(source.contains("Ocp-Apim-Subscription-Key"), path.toString());
                assertFalse(source.contains("tts.speech.microsoft.com"), path.toString());
            }
        }
    }
}

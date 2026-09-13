package com.epitomehub.chessverse.speech;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
class SpeechSynthesisService {
    static final int MAX_TEXT_LENGTH = 2400;
    private final AzureSpeechGateway gateway;
    private final Cache<String, SpeechAudio> cache = Caffeine.newBuilder()
            .maximumWeight(96 * 1024 * 1024)
            .weigher((String ignored, SpeechAudio audio) -> audio.bytes().length)
            .expireAfterAccess(Duration.ofHours(24))
            .build();

    SpeechSynthesisService(AzureSpeechGateway gateway) {
        this.gateway = gateway;
    }

    SpeechAudio synthesize(String text, String language) {
        String cleanText = text == null ? "" : text.strip();
        if (cleanText.isEmpty()) throw new SpeechException(HttpStatus.BAD_REQUEST, "Narration text is required.");
        if (cleanText.length() > MAX_TEXT_LENGTH) {
            throw new SpeechException(HttpStatus.BAD_REQUEST, "Narration text must be 2,400 characters or fewer.");
        }
        SpeechVoiceCatalog.Voice voice = SpeechVoiceCatalog.resolve(language);
        if (voice == null) throw new SpeechException(HttpStatus.BAD_REQUEST, "This narration language is not supported.");
        String cacheKey = sha256(voice.name() + '\n' + cleanText);
        SpeechAudio cached = cache.getIfPresent(cacheKey);
        if (cached != null) return cached.withCacheHit(true);
        byte[] bytes = gateway.synthesize(ssml(cleanText, voice));
        SpeechAudio created = new SpeechAudio(bytes, voice.locale(), voice.name(), cacheKey, false);
        cache.put(cacheKey, created);
        return created;
    }

    private String ssml(String text, SpeechVoiceCatalog.Voice voice) {
        return "<speak version=\"1.0\" xmlns=\"http://www.w3.org/2001/10/synthesis\" xml:lang=\""
                + voice.locale() + "\"><voice name=\"" + voice.name() + "\"><prosody rate=\"-5%\">"
                + escapeXml(text) + "</prosody></voice></speak>";
    }

    private String escapeXml(String value) {
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&apos;");
    }

    private String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    record SpeechAudio(byte[] bytes, String locale, String voice, String etag, boolean cacheHit) {
        SpeechAudio withCacheHit(boolean value) {
            return new SpeechAudio(bytes, locale, voice, etag, value);
        }
    }
}

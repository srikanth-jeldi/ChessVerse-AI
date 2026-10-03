package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.*;

import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.DeserializationFeature;

class OnlineQueueRequestTest {
    private final JsonMapper mapper = JsonMapper.builder()
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES).build();

    @Test void legacyClientWithoutCoinPreferenceUsesDefaultStake() {
        var request = mapper.readValue("""
                {"timeControlMinutes":10,"region":"WORLDWIDE","ratingRange":0}
                """, OnlineDtos.QueueRequest.class);
        assertEquals(100, request.entryCoins());
        assertEquals("STANDARD", request.connectionQuality());
    }

    @Test void emptyAndNullPreferencesUseSafeDefaults() {
        for (String json : new String[]{"{}", """
                {"timeControlMinutes":null,"ratingRange":null,"entryCoins":null}
                """}) {
            var request = mapper.readValue(json, OnlineDtos.QueueRequest.class);
            assertEquals(10, request.timeControlMinutes());
            assertEquals(0, request.ratingRange());
            assertEquals(100, request.entryCoins());
            assertEquals("WORLDWIDE", request.region());
        }
    }

    @Test void currentClientPreferencesArePreserved() {
        var request = mapper.readValue("""
                {"timeControlMinutes":5,"region":"COUNTRY","ratingRange":200,
                 "entryCoins":500,"connectionQuality":"EXCELLENT"}
                """, OnlineDtos.QueueRequest.class);
        assertEquals(5, request.timeControlMinutes());
        assertEquals(200, request.ratingRange());
        assertEquals(500, request.entryCoins());
        assertEquals("EXCELLENT", request.connectionQuality());
    }

    @Test void negativePreferencesStillFailValidation() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var request = mapper.readValue("""
                    {"timeControlMinutes":-1,"ratingRange":-1,"entryCoins":-1}
                    """, OnlineDtos.QueueRequest.class);
            assertFalse(factory.getValidator().validate(request).isEmpty());
        }
    }
}

package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class MessageEncryptionServiceTest {
    private static final String KEY = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=";

    @Test
    void encryptsAtRestAndReadsLegacyPlaintext() {
        var encryption = new MessageEncryptionService(KEY);
        String encrypted = encryption.encrypt("private chess plan", "message-1");
        assertNotEquals("private chess plan", encrypted);
        assertEquals("private chess plan", encryption.decrypt(encrypted, "message-1"));
        assertEquals("old message", encryption.decrypt("old message", "message-1"));
    }

    @Test
    void ciphertextCannotMoveBetweenMessageRows() {
        var encryption = new MessageEncryptionService(KEY);
        String encrypted = encryption.encrypt("private", "message-1");
        assertThrows(IllegalStateException.class,
                () -> encryption.decrypt(encrypted, "message-2"));
    }
}

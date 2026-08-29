package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import org.junit.jupiter.api.Test;

class AttachmentEncryptionServiceTest {
    private static final String KEY = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=";

    @Test
    void encryptsAndAuthenticatesAttachmentBytes() {
        var encryption = new AttachmentEncryptionService(KEY);
        byte[] plaintext = "private chess attachment".getBytes(StandardCharsets.UTF_8);
        byte[] context = "message-id".getBytes(StandardCharsets.UTF_8);
        byte[] encrypted = encryption.encrypt(plaintext, context);
        assertFalse(Arrays.equals(plaintext, encrypted));
        assertArrayEquals(plaintext, encryption.decrypt(encrypted, context));
        encrypted[encrypted.length - 1] ^= 1;
        assertThrows(IllegalStateException.class, () -> encryption.decrypt(encrypted, context));
    }

    @Test
    void ciphertextIsBoundToItsMessageId() {
        var encryption = new AttachmentEncryptionService(KEY);
        byte[] encrypted = encryption.encrypt("file".getBytes(StandardCharsets.UTF_8),
                "first".getBytes(StandardCharsets.UTF_8));
        assertThrows(IllegalStateException.class, () -> encryption.decrypt(encrypted,
                "second".getBytes(StandardCharsets.UTF_8)));
    }
}

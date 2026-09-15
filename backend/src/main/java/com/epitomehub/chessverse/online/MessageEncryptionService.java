package com.epitomehub.chessverse.online;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/** Transparent authenticated encryption for chat bodies stored in Postgres. */
@Service
class MessageEncryptionService {
    private static final String PREFIX = "cvm1:";
    private static final int NONCE_BYTES = 12;
    private final SecretKeySpec key;
    private final SecureRandom random = new SecureRandom();

    MessageEncryptionService(@Value("${chessverse.messages.encryption-key:}") String encodedKey) {
        if (encodedKey == null || encodedKey.isBlank()) {
            key = null;
            return;
        }
        byte[] decoded;
        try { decoded = Base64.getDecoder().decode(encodedKey); }
        catch (IllegalArgumentException error) { throw new IllegalStateException("Message encryption key must be Base64.", error); }
        if (decoded.length != 32) throw new IllegalStateException("Message encryption key must contain exactly 32 bytes.");
        key = new SecretKeySpec(decoded, "AES");
    }

    String encrypt(String plaintext, String messageId) {
        requireKey();
        byte[] nonce = new byte[NONCE_BYTES];
        random.nextBytes(nonce);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, nonce));
            cipher.updateAAD(messageId.getBytes(StandardCharsets.UTF_8));
            byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            byte[] envelope = ByteBuffer.allocate(nonce.length + ciphertext.length)
                    .put(nonce).put(ciphertext).array();
            return PREFIX + Base64.getUrlEncoder().withoutPadding().encodeToString(envelope);
        } catch (GeneralSecurityException error) {
            throw new IllegalStateException("Message encryption failed.", error);
        }
    }

    String decrypt(String stored, String messageId) {
        if (stored == null || !stored.startsWith(PREFIX)) return stored;
        requireKey();
        try {
            byte[] envelope = Base64.getUrlDecoder().decode(stored.substring(PREFIX.length()));
            if (envelope.length < NONCE_BYTES + 16) throw new GeneralSecurityException("Invalid envelope");
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key,
                    new GCMParameterSpec(128, envelope, 0, NONCE_BYTES));
            cipher.updateAAD(messageId.getBytes(StandardCharsets.UTF_8));
            return new String(cipher.doFinal(envelope, NONCE_BYTES,
                    envelope.length - NONCE_BYTES), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException | GeneralSecurityException error) {
            throw new IllegalStateException("Message authentication failed.", error);
        }
    }

    private void requireKey() {
        if (key == null) throw new IllegalStateException("Message encryption is not configured.");
    }
}

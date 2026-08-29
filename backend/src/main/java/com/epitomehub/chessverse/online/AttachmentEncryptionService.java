package com.epitomehub.chessverse.online;

import java.nio.ByteBuffer;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
class AttachmentEncryptionService {
    private static final byte[] MAGIC = {'C', 'V', 'A', '1'};
    private static final int NONCE_BYTES = 12;
    private final SecretKeySpec key;
    private final SecureRandom random = new SecureRandom();

    AttachmentEncryptionService(@Value("${chessverse.attachments.encryption-key:}") String encodedKey) {
        if (encodedKey == null || encodedKey.isBlank()) {
            key = null;
            return;
        }
        byte[] decoded;
        try { decoded = Base64.getDecoder().decode(encodedKey); }
        catch (IllegalArgumentException error) { throw new IllegalStateException("Attachment encryption key must be Base64.", error); }
        if (decoded.length != 32) throw new IllegalStateException("Attachment encryption key must contain exactly 32 bytes.");
        key = new SecretKeySpec(decoded, "AES");
    }

    byte[] encrypt(byte[] plaintext, byte[] context) {
        requireKey();
        byte[] nonce = new byte[NONCE_BYTES];
        random.nextBytes(nonce);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, nonce));
            cipher.updateAAD(context);
            byte[] ciphertext = cipher.doFinal(plaintext);
            return ByteBuffer.allocate(MAGIC.length + nonce.length + ciphertext.length)
                    .put(MAGIC).put(nonce).put(ciphertext).array();
        } catch (GeneralSecurityException error) {
            throw new IllegalStateException("Attachment encryption failed.", error);
        }
    }

    byte[] decrypt(byte[] stored, byte[] context) {
        requireKey();
        if (stored.length < MAGIC.length + NONCE_BYTES + 16 ||
                !Arrays.equals(Arrays.copyOf(stored, MAGIC.length), MAGIC)) {
            throw new IllegalStateException("Attachment is not encrypted or is corrupt.");
        }
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key,
                    new GCMParameterSpec(128, stored, MAGIC.length, NONCE_BYTES));
            cipher.updateAAD(context);
            return cipher.doFinal(stored, MAGIC.length + NONCE_BYTES,
                    stored.length - MAGIC.length - NONCE_BYTES);
        } catch (GeneralSecurityException error) {
            throw new IllegalStateException("Attachment authentication failed.", error);
        }
    }

    boolean isEncrypted(byte[] stored) {
        return stored.length >= MAGIC.length &&
                Arrays.equals(Arrays.copyOf(stored, MAGIC.length), MAGIC);
    }

    boolean isConfigured() { return key != null; }

    private void requireKey() {
        if (key == null) throw new IllegalStateException("Attachment encryption is not configured.");
    }
}

package com.epitomehub.chessverse.online;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class AttachmentPolicyTest {
    @Test
    void ignoresClientExtensionAndUsesDetectedPngType() {
        byte[] png = png(320, 200);
        var accepted = AttachmentPolicy.inspect(png, "../../board.html");
        assertEquals("board.png", accepted.filename());
        assertEquals("image/png", accepted.mediaType());
        assertEquals(".png", accepted.extension());
    }

    @Test
    void rejectsHtmlEvenWhenNamedAsImage() {
        OnlineMatchException error = assertThrows(OnlineMatchException.class,
                () -> AttachmentPolicy.inspect("<html><script>alert(1)</script>".getBytes(StandardCharsets.UTF_8), "photo.png"));
        assertEquals(HttpStatus.UNSUPPORTED_MEDIA_TYPE, error.status());
    }

    @Test
    void rejectsSvgActiveContent() {
        assertThrows(OnlineMatchException.class,
                () -> AttachmentPolicy.inspect("<svg onload='alert(1)'></svg>".getBytes(StandardCharsets.UTF_8), "image.svg"));
    }

    @Test
    void rejectsImageBombDimensions() {
        assertThrows(OnlineMatchException.class, () -> AttachmentPolicy.inspect(png(50_000, 50_000), "huge.png"));
    }

    @Test
    void acceptsPdfBySignatureAndNormalizesName() {
        var accepted = AttachmentPolicy.inspect("%PDF-1.7\n%%EOF".getBytes(StandardCharsets.US_ASCII), "notes.exe");
        assertEquals("notes.pdf", accepted.filename());
        assertEquals("application/pdf", accepted.mediaType());
    }

    private static byte[] png(int width, int height) {
        byte[] bytes = new byte[24];
        byte[] signature = {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        System.arraycopy(signature, 0, bytes, 0, signature.length);
        System.arraycopy("IHDR".getBytes(StandardCharsets.US_ASCII), 0, bytes, 12, 4);
        putInt(bytes, 16, width); putInt(bytes, 20, height);
        return bytes;
    }

    private static void putInt(byte[] bytes, int offset, int value) {
        bytes[offset] = (byte) (value >>> 24); bytes[offset + 1] = (byte) (value >>> 16);
        bytes[offset + 2] = (byte) (value >>> 8); bytes[offset + 3] = (byte) value;
    }
}

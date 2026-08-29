package com.epitomehub.chessverse.online;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Locale;
import org.springframework.http.HttpStatus;

final class AttachmentPolicy {
    static final long MAX_BYTES = 10L * 1024 * 1024;
    private static final int MAX_IMAGE_WIDTH = 12_000;
    private static final int MAX_IMAGE_HEIGHT = 12_000;
    private static final long MAX_IMAGE_PIXELS = 40_000_000L;

    private AttachmentPolicy() {}

    static AcceptedAttachment inspect(byte[] bytes, String originalFilename) {
        if (bytes == null || bytes.length == 0) {
            throw rejected("Choose a file to attach.");
        }
        if (bytes.length > MAX_BYTES) {
            throw new OnlineMatchException(HttpStatus.PAYLOAD_TOO_LARGE,
                    "Attachments must be 10 MB or smaller.");
        }

        FileKind kind = detect(bytes);
        if (kind == null) {
            throw rejected("Only JPEG, PNG, WebP, and PDF attachments are supported.");
        }
        if (kind.image) validateImageDimensions(bytes, kind);

        String safeName = safeFilename(originalFilename, kind.extension);
        return new AcceptedAttachment(safeName, kind.mediaType, kind.extension, bytes);
    }

    private static FileKind detect(byte[] bytes) {
        if (startsWith(bytes, new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF})) return FileKind.JPEG;
        if (startsWith(bytes, new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A})) return FileKind.PNG;
        if (bytes.length >= 12 && ascii(bytes, 0, 4).equals("RIFF") && ascii(bytes, 8, 4).equals("WEBP")) return FileKind.WEBP;
        if (bytes.length >= 5 && ascii(bytes, 0, 5).equals("%PDF-")) return FileKind.PDF;
        return null;
    }

    private static void validateImageDimensions(byte[] bytes, FileKind kind) {
        ImageSize size = switch (kind) {
            case PNG -> pngSize(bytes);
            case JPEG -> jpegSize(bytes);
            case WEBP -> webpSize(bytes);
            default -> null;
        };
        if (size == null || size.width <= 0 || size.height <= 0) {
            throw rejected("The image is malformed or unsupported.");
        }
        if (size.width > MAX_IMAGE_WIDTH || size.height > MAX_IMAGE_HEIGHT
                || (long) size.width * size.height > MAX_IMAGE_PIXELS) {
            throw rejected("The image dimensions are too large.");
        }
    }

    private static ImageSize pngSize(byte[] bytes) {
        if (bytes.length < 24 || !ascii(bytes, 12, 4).equals("IHDR")) return null;
        return new ImageSize(int32be(bytes, 16), int32be(bytes, 20));
    }

    private static ImageSize jpegSize(byte[] bytes) {
        int offset = 2;
        while (offset + 9 < bytes.length) {
            if ((bytes[offset] & 0xFF) != 0xFF) return null;
            int marker = bytes[offset + 1] & 0xFF;
            offset += 2;
            if (marker == 0xD8 || marker == 0xD9) continue;
            if (marker == 0xDA) return null;
            if (offset + 2 > bytes.length) return null;
            int length = uint16be(bytes, offset);
            if (length < 2 || offset + length > bytes.length) return null;
            if (isStartOfFrame(marker) && length >= 7) {
                return new ImageSize(uint16be(bytes, offset + 5), uint16be(bytes, offset + 3));
            }
            offset += length;
        }
        return null;
    }

    private static ImageSize webpSize(byte[] bytes) {
        if (bytes.length < 30) return null;
        String chunk = ascii(bytes, 12, 4);
        if (chunk.equals("VP8X") && bytes.length >= 30) {
            return new ImageSize(1 + uint24le(bytes, 24), 1 + uint24le(bytes, 27));
        }
        if (chunk.equals("VP8 ") && bytes.length >= 30
                && (bytes[23] & 0xFF) == 0x9D && (bytes[24] & 0xFF) == 0x01 && (bytes[25] & 0xFF) == 0x2A) {
            return new ImageSize(uint16le(bytes, 26) & 0x3FFF, uint16le(bytes, 28) & 0x3FFF);
        }
        if (chunk.equals("VP8L") && bytes.length >= 25 && (bytes[20] & 0xFF) == 0x2F) {
            int bits = (bytes[21] & 0xFF) | ((bytes[22] & 0xFF) << 8)
                    | ((bytes[23] & 0xFF) << 16) | ((bytes[24] & 0xFF) << 24);
            return new ImageSize((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
        }
        return null;
    }

    private static String safeFilename(String supplied, String requiredExtension) {
        String name = supplied == null ? "attachment" : supplied;
        name = name.replace('\\', '/');
        name = name.substring(name.lastIndexOf('/') + 1)
                .replaceAll("[\\p{Cntrl}]", "")
                .replaceAll("[^\\p{L}\\p{N}._() -]", "_")
                .trim();
        if (name.isBlank() || name.equals(".") || name.equals("..")) name = "attachment";
        if (name.length() > 120) name = name.substring(0, 120);
        String lower = name.toLowerCase(Locale.ROOT);
        if (!lower.endsWith(requiredExtension)) {
            int dot = name.lastIndexOf('.');
            if (dot > 0) name = name.substring(0, dot);
            name += requiredExtension;
        }
        return name;
    }

    private static boolean startsWith(byte[] bytes, byte[] prefix) {
        return bytes.length >= prefix.length && Arrays.equals(Arrays.copyOf(bytes, prefix.length), prefix);
    }

    private static String ascii(byte[] bytes, int offset, int length) {
        return new String(bytes, offset, length, StandardCharsets.US_ASCII);
    }

    private static int int32be(byte[] b, int o) {
        return (b[o] & 0xFF) << 24 | (b[o + 1] & 0xFF) << 16 | (b[o + 2] & 0xFF) << 8 | (b[o + 3] & 0xFF);
    }

    private static int uint16be(byte[] b, int o) { return (b[o] & 0xFF) << 8 | (b[o + 1] & 0xFF); }
    private static int uint16le(byte[] b, int o) { return (b[o] & 0xFF) | (b[o + 1] & 0xFF) << 8; }
    private static int uint24le(byte[] b, int o) { return (b[o] & 0xFF) | (b[o + 1] & 0xFF) << 8 | (b[o + 2] & 0xFF) << 16; }
    private static boolean isStartOfFrame(int marker) {
        return marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
    }

    private static OnlineMatchException rejected(String message) {
        return new OnlineMatchException(HttpStatus.UNSUPPORTED_MEDIA_TYPE, message);
    }

    record AcceptedAttachment(String filename, String mediaType, String extension, byte[] bytes) {}
    private record ImageSize(int width, int height) {}
    private enum FileKind {
        JPEG("image/jpeg", ".jpg", true), PNG("image/png", ".png", true),
        WEBP("image/webp", ".webp", true), PDF("application/pdf", ".pdf", false);
        final String mediaType;
        final String extension;
        final boolean image;
        FileKind(String mediaType, String extension, boolean image) {
            this.mediaType = mediaType; this.extension = extension; this.image = image;
        }
    }
}

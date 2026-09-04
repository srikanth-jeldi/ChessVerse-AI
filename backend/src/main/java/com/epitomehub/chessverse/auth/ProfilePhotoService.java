package com.epitomehub.chessverse.auth;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
class ProfilePhotoService {
    private static final long MAX_BYTES = 5L * 1024 * 1024;
    private final PlayerAuthenticationService authentication;
    private final PlayerAccountRepository players;
    private final Path root;
    private final String publicApiBase;

    ProfilePhotoService(PlayerAuthenticationService authentication,
            PlayerAccountRepository players,
            @Value("${chessverse.profile-photo-root:/app/data/profile-photos}") String root,
            @Value("${chessverse.public-api-base-url:https://api.chessverseai.com}") String publicApiBase) {
        this.authentication = authentication;
        this.players = players;
        this.root = Path.of(root).toAbsolutePath().normalize();
        this.publicApiBase = publicApiBase.replaceAll("/+$", "");
    }

    @Transactional
    AuthDtos.PlayerResponse upload(String authorization, MultipartFile file) {
        AuthenticatedPlayer authenticated = authentication.requireBearer(authorization);
        if (file == null || file.isEmpty() || file.getSize() > MAX_BYTES) {
            throw new AuthException(HttpStatus.BAD_REQUEST, "Choose a JPG, PNG or WebP image up to 5 MB.");
        }
        String extension = extension(file);
        PlayerAccount player = players.findById(authenticated.id())
                .orElseThrow(() -> new AuthException(HttpStatus.NOT_FOUND, "Player was not found."));
        try {
            Files.createDirectories(root);
            for (String old : new String[]{"jpg", "png", "webp"}) {
                Files.deleteIfExists(root.resolve(player.id + "." + old));
            }
            Path destination = root.resolve(player.id + "." + extension).normalize();
            if (!destination.getParent().equals(root)) throw new IOException("Invalid destination");
            Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException exception) {
            throw new AuthException(HttpStatus.INTERNAL_SERVER_ERROR, "Profile photo could not be saved.");
        }
        player.photoUrl = publicApiBase + "/api/auth/profile-photo/" + player.id
                + "?v=" + Instant.now().toEpochMilli();
        player.updatedAt = Instant.now();
        players.save(player);
        return AuthDtos.PlayerResponse.from(player);
    }

    Resource load(UUID playerId) {
        for (String extension : new String[]{"jpg", "png", "webp"}) {
            Path candidate = root.resolve(playerId + "." + extension);
            if (Files.isRegularFile(candidate)) {
                try { return new UrlResource(candidate.toUri()); }
                catch (IOException ignored) { break; }
            }
        }
        throw new AuthException(HttpStatus.NOT_FOUND, "Profile photo was not found.");
    }

    private String extension(MultipartFile file) {
        String type = file.getContentType() == null ? "" : file.getContentType().toLowerCase(Locale.ROOT);
        return switch (type) {
            case "image/jpeg", "image/jpg" -> "jpg";
            case "image/png" -> "png";
            case "image/webp" -> "webp";
            default -> throw new AuthException(HttpStatus.BAD_REQUEST, "Only JPG, PNG and WebP profile photos are supported.");
        };
    }
}

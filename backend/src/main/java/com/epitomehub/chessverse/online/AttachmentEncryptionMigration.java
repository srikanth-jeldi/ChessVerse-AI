package com.epitomehub.chessverse.online;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.io.IOException;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
class AttachmentEncryptionMigration implements ApplicationRunner {
    private final JdbcTemplate jdbc;
    private final AttachmentEncryptionService encryption;
    private final Path root;

    AttachmentEncryptionMigration(JdbcTemplate jdbc, AttachmentEncryptionService encryption,
            @Value("${chessverse.attachments.directory:./data/chat-attachments}") String directory) {
        this.jdbc = jdbc;
        this.encryption = encryption;
        this.root = Path.of(directory).toAbsolutePath().normalize();
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!encryption.isConfigured() || !Files.isDirectory(root)) return;
        jdbc.query("select id, attachment_path from direct_message where attachment_path is not null", rs -> {
            UUID messageId = rs.getObject("id", UUID.class);
            Path path = root.resolve(rs.getString("attachment_path")).normalize();
            try { migrate(messageId, path); }
            catch (IOException error) { throw new IllegalStateException("Attachment encryption migration failed.", error); }
        });
    }

    private void migrate(UUID messageId, Path path) throws IOException {
        if (!path.startsWith(root) || !Files.isRegularFile(path)) return;
        byte[] stored = Files.readAllBytes(path);
        if (encryption.isEncrypted(stored)) return;
        byte[] encrypted = encryption.encrypt(stored,
                messageId.toString().getBytes(StandardCharsets.UTF_8));
        Path temporary = Files.createTempFile(root, messageId.toString(), ".encrypting");
        try {
            Files.write(temporary, encrypted);
            Files.move(temporary, path, StandardCopyOption.ATOMIC_MOVE,
                    StandardCopyOption.REPLACE_EXISTING);
        } finally {
            Files.deleteIfExists(temporary);
        }
    }
}

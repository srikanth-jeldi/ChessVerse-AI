package com.epitomehub.chessverse.auth;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface PasswordResetRepository extends JpaRepository<PasswordReset, UUID> {
    Optional<PasswordReset> findFirstByPlayerIdAndConsumedAtIsNullOrderByCreatedAtDesc(UUID playerId);
}

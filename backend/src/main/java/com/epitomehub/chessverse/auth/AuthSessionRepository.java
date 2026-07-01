package com.epitomehub.chessverse.auth;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface AuthSessionRepository extends JpaRepository<AuthSession, UUID> {
    @Query("select session from AuthSession session join fetch session.player where session.tokenHash = :tokenHash")
    Optional<AuthSession> findByTokenHash(@Param("tokenHash") String tokenHash);

    void deleteByTokenHash(String tokenHash);

    void deleteByPlayerId(UUID playerId);
}

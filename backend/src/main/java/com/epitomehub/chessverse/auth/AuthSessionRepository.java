package com.epitomehub.chessverse.auth;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;

interface AuthSessionRepository extends JpaRepository<AuthSession, UUID> {
    @Query("select session from AuthSession session join fetch session.player where session.tokenHash = :tokenHash")
    Optional<AuthSession> findByTokenHash(@Param("tokenHash") String tokenHash);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select session from AuthSession session join fetch session.player where session.refreshTokenHash = :tokenHash")
    Optional<AuthSession> findByRefreshTokenHash(@Param("tokenHash") String tokenHash);

    java.util.List<AuthSession> findAllByPlayerIdOrderByLastUsedAtDesc(UUID playerId);

    Optional<AuthSession> findByIdAndPlayerId(UUID id, UUID playerId);

    void deleteByTokenFamilyId(UUID tokenFamilyId);

    void deleteByTokenHash(String tokenHash);

    void deleteByPlayerId(UUID playerId);
}

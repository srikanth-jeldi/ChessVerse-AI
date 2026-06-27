package com.epitomehub.chessverse.auth;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface AuthSessionRepository extends JpaRepository<AuthSession, UUID> {
}

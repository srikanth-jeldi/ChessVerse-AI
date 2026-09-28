package com.epitomehub.chessverse.auth;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface AuthActivityEventRepository extends JpaRepository<AuthActivityEvent, UUID> {}


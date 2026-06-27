package com.epitomehub.chessverse.auth;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface PlayerAccountRepository extends JpaRepository<PlayerAccount, UUID> {
    Optional<PlayerAccount> findByEmailIgnoreCase(String email);

    Optional<PlayerAccount> findByPhone(String phone);

    Optional<PlayerAccount> findByUsernameIgnoreCase(String username);
}

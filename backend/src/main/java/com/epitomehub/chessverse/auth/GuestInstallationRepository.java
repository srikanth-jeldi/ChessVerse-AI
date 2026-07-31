package com.epitomehub.chessverse.auth;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface GuestInstallationRepository extends JpaRepository<GuestInstallation, String> {
    @Query("""
            select installation from GuestInstallation installation
            join fetch installation.player
            where installation.installationHash = :installationHash
            """)
    Optional<GuestInstallation> findWithPlayerByInstallationHash(
            @Param("installationHash") String installationHash);
}

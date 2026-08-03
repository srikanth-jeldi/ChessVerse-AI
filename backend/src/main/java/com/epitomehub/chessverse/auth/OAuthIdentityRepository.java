package com.epitomehub.chessverse.auth;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface OAuthIdentityRepository extends JpaRepository<OAuthIdentity, UUID> {
    @Query("select identity from OAuthIdentity identity join fetch identity.player "
            + "where identity.provider = :provider and identity.subject = :subject")
    Optional<OAuthIdentity> findByProviderAndSubject(
            @Param("provider") String provider,
            @Param("subject") String subject);

    boolean existsByProviderAndPlayer_Id(String provider, UUID playerId);
}

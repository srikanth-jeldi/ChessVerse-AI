package com.epitomehub.chessverse.online;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface SocialChallengeRepository extends JpaRepository<SocialChallenge, UUID> {
    @Query("""
            select challenge from SocialChallenge challenge
            where challenge.challengerId = :playerId or challenge.challengedId = :playerId
            order by challenge.createdAt desc
            """)
    List<SocialChallenge> recentFor(@Param("playerId") UUID playerId);
}

package com.epitomehub.chessverse.online;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import java.util.List;
import java.time.Instant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface OnlineMatchRepository extends JpaRepository<OnlineMatch, UUID> {
    Optional<OnlineMatch> findByRoomCodeIgnoreCase(String roomCode);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select match from OnlineMatch match where match.id = :matchId")
    Optional<OnlineMatch> lockById(@Param("matchId") UUID matchId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select match from OnlineMatch match
            where match.randomQueue = true and match.status = 'WAITING'
              and match.whitePlayerId <> :playerId
              and match.updatedAt >= :activeAfter
              and match.timeControlMinutes = :timeControlMinutes
              and match.entryCoins = :entryCoins
              and match.queueRegion = :region
              and (:region = 'WORLDWIDE' or match.queueCountry = :country)
              and (:ratingRange = 0 or abs(match.queueRating - :rating) <= :ratingRange)
              and (match.ratingRange = 0 or abs(match.queueRating - :rating) <= match.ratingRange)
            order by match.createdAt
            limit 1
            """)
    Optional<OnlineMatch> lockOldestRandomOpponent(
            @Param("playerId") UUID playerId,
            @Param("activeAfter") Instant activeAfter,
            @Param("timeControlMinutes") int timeControlMinutes,
            @Param("entryCoins") int entryCoins,
            @Param("region") String region,
            @Param("country") String country,
            @Param("rating") int rating,
            @Param("ratingRange") int ratingRange);

    @Query("""
            select count(match) from OnlineMatch match
            where match.randomQueue = true and match.status = 'WAITING'
              and match.updatedAt >= :activeAfter
            """)
    long countFreshRandomQueue(@Param("activeAfter") Instant activeAfter);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select match from OnlineMatch match
            where match.randomQueue = true and match.status = 'WAITING'
              and match.updatedAt < :cutoff
            """)
    List<OnlineMatch> lockExpiredRandomQueue(@Param("cutoff") Instant cutoff);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select match from OnlineMatch match
            where (match.whitePlayerId = :playerId or match.blackPlayerId = :playerId)
              and match.status in ('WAITING', 'ACTIVE')
            order by match.updatedAt desc
            limit 1
            """)
    Optional<OnlineMatch> findCurrentForPlayer(@Param("playerId") UUID playerId);

    @Query("""
            select match from OnlineMatch match
            where (match.whitePlayerId = :playerId or match.blackPlayerId = :playerId)
              and match.status = 'FINISHED'
            order by match.finishedAt desc, match.updatedAt desc
            limit 50
            """)
    List<OnlineMatch> findRecentForPlayer(@Param("playerId") UUID playerId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select match from OnlineMatch match
            where match.status = 'ACTIVE'
              and (match.whiteDisconnectedAt <= :cutoff or match.blackDisconnectedAt <= :cutoff)
            """)
    List<OnlineMatch> lockExpiredDisconnects(@Param("cutoff") Instant cutoff);
}

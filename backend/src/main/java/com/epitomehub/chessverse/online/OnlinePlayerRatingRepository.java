package com.epitomehub.chessverse.online;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface OnlinePlayerRatingRepository extends JpaRepository<OnlinePlayerRating, UUID> {
    @Modifying
    @Query(value = """
            insert into online_player_rating (
                player_id, display_name, country, rating, peak_rating,
                games_played, wins, draws, losses, created_at, updated_at
            ) values (:playerId, :displayName, 'Unknown', 1200, 1200, 0, 0, 0, 0, now(), now())
            on conflict (player_id) do nothing
            """, nativeQuery = true)
    void ensureExists(
            @Param("playerId") UUID playerId,
            @Param("displayName") String displayName);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select rating from OnlinePlayerRating rating where rating.playerId = :playerId")
    Optional<OnlinePlayerRating> lockByPlayerId(@Param("playerId") UUID playerId);

    @Query("""
            select rating from OnlinePlayerRating rating
            where rating.gamesPlayed > 0
            order by rating.rating desc, rating.wins desc, rating.gamesPlayed desc, rating.playerId
            """)
    Page<OnlinePlayerRating> global(Pageable pageable);

    @Query("""
            select rating from OnlinePlayerRating rating
            where rating.gamesPlayed > 0 and lower(rating.country) = lower(:country)
            order by rating.rating desc, rating.wins desc, rating.gamesPlayed desc, rating.playerId
            """)
    Page<OnlinePlayerRating> byCountry(@Param("country") String country, Pageable pageable);

    long countByGamesPlayedGreaterThanAndRatingGreaterThan(int gamesPlayed, int rating);

    long countByCountryIgnoreCaseAndGamesPlayedGreaterThanAndRatingGreaterThan(
            String country, int gamesPlayed, int rating);
}

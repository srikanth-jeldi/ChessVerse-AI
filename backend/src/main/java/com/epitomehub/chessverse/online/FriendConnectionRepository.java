package com.epitomehub.chessverse.online;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface FriendConnectionRepository extends JpaRepository<FriendConnection, UUID> {
    @Query("""
            select link from FriendConnection link
            where (link.requesterId = :playerId or link.addresseeId = :playerId)
              and link.status in ('PENDING', 'ACCEPTED', 'DECLINED')
            order by link.updatedAt desc
            """)
    List<FriendConnection> activeFor(@Param("playerId") UUID playerId);

    @Query("""
            select link from FriendConnection link
            where (link.requesterId = :first and link.addresseeId = :second)
               or (link.requesterId = :second and link.addresseeId = :first)
            """)
    Optional<FriendConnection> between(
            @Param("first") UUID first, @Param("second") UUID second);
}

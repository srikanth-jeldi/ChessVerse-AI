package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class SocialService {
    private final FriendConnectionRepository friends;
    private final SocialChallengeRepository challenges;
    private final OnlineMatchService matches;
    private final OnlinePlayerRatingRepository ratings;
    private final OnlinePresenceService presence;
    private final JdbcTemplate jdbc;
    private final PlayerNotificationService notifications;

    SocialService(FriendConnectionRepository friends, SocialChallengeRepository challenges,
                  OnlineMatchService matches, OnlinePlayerRatingRepository ratings,
                  OnlinePresenceService presence, JdbcTemplate jdbc,
                  PlayerNotificationService notifications) {
        this.friends = friends;
        this.challenges = challenges;
        this.matches = matches;
        this.ratings = ratings;
        this.presence = presence;
        this.jdbc = jdbc;
        this.notifications = notifications;
    }

    @Transactional
    SocialDtos.SocialHubDto hub(AuthenticatedPlayer player) {
        normalizeChallenges(player.id(), false);
        List<SocialDtos.PlayerDto> accepted = new ArrayList<>();
        List<SocialDtos.PlayerDto> incoming = new ArrayList<>();
        List<SocialDtos.PlayerDto> outgoing = new ArrayList<>();
        for (FriendConnection link : friends.activeFor(player.id())) {
            UUID other = link.other(player.id());
            if ("ACCEPTED".equals(link.status)) accepted.add(player(link.id, other, "FRIEND"));
            else if (link.addresseeId.equals(player.id())) incoming.add(player(link.id, other, "INCOMING"));
            else outgoing.add(player(link.id, other, "OUTGOING"));
        }
        List<SocialDtos.ChallengeDto> challengeDtos = challenges.recentFor(player.id()).stream()
                .limit(20).map(value -> challenge(value, player.id())).toList();
        return new SocialDtos.SocialHubDto(accepted, incoming, outgoing, challengeDtos);
    }

    @Transactional
    SocialDtos.SocialHubDto request(AuthenticatedPlayer player, String rawUsername) {
        PlayerRow target = findByUsername(rawUsername.trim());
        if (target.id.equals(player.id())) {
            throw new OnlineMatchException(HttpStatus.UNPROCESSABLE_ENTITY, "You cannot add yourself.");
        }
        FriendConnection existing = friends.between(player.id(), target.id).orElse(null);
        if (existing == null) {
            FriendConnection created = friends.save(new FriendConnection(player.id(), target.id));
            notifications.create(target.id, "FRIEND_REQUEST", "New friend request",
                    player.displayName() + " wants to connect with you.", "FRIEND_REQUEST", created.id);
        }
        else if ("DECLINED".equals(existing.status)) {
            existing.requesterId = player.id(); existing.addresseeId = target.id;
            existing.status = "PENDING"; existing.updatedAt = Instant.now(); friends.save(existing);
        } else if ("PENDING".equals(existing.status) && existing.addresseeId.equals(player.id())) {
            existing.status = "ACCEPTED"; existing.updatedAt = Instant.now(); friends.save(existing);
        }
        return hub(player);
    }

    @Transactional
    SocialDtos.SocialHubDto respond(AuthenticatedPlayer player, UUID connectionId, boolean accept) {
        FriendConnection link = friends.findById(connectionId)
                .orElseThrow(() -> new OnlineMatchException(HttpStatus.NOT_FOUND, "Friend request was not found."));
        if (!link.addresseeId.equals(player.id()) || !"PENDING".equals(link.status)) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "This friend request cannot be changed.");
        }
        link.status = accept ? "ACCEPTED" : "DECLINED";
        link.updatedAt = Instant.now(); friends.save(link);
        notifications.create(link.requesterId, accept ? "FRIEND_ACCEPTED" : "FRIEND_DECLINED",
                accept ? "Friend request accepted" : "Friend request declined",
                player.displayName() + (accept ? " is now your ChessVerseAI friend." : " declined your friend request."),
                "COMMUNITY", link.id);
        return hub(player);
    }

    @Transactional
    SocialDtos.SocialHubDto remove(AuthenticatedPlayer player, UUID friendId) {
        FriendConnection link = friends.between(player.id(), friendId)
                .orElseThrow(() -> new OnlineMatchException(HttpStatus.NOT_FOUND, "Friend was not found."));
        friends.delete(link);
        return hub(player);
    }

    @Transactional
    SocialDtos.ChallengeDto challenge(AuthenticatedPlayer player, UUID friendId, int minutes) {
        FriendConnection link = friends.between(player.id(), friendId).orElse(null);
        if (link == null || !"ACCEPTED".equals(link.status)) {
            throw new OnlineMatchException(HttpStatus.FORBIDDEN, "Add this player as a friend before challenging them.");
        }
        int supported = switch (minutes) { case 3, 5, 10, 15 -> minutes; default -> 10; };
        SocialChallenge pendingBetween = challenges.recentFor(player.id()).stream()
                .filter(value -> "PENDING".equals(value.status) && value.expiresAt.isAfter(Instant.now()))
                .filter(value -> (value.challengerId.equals(player.id()) && value.challengedId.equals(friendId))
                        || (value.challengerId.equals(friendId) && value.challengedId.equals(player.id())))
                .findFirst().orElse(null);
        if (pendingBetween != null) {
            if (pendingBetween.challengerId.equals(player.id())) return challenge(pendingBetween, player.id());
            throw new OnlineMatchException(HttpStatus.CONFLICT,
                    "This player already challenged you. Accept their pending challenge.");
        }
        normalizeChallenges(player.id(), true);
        OnlineDtos.MatchDto room = matches.createChallengeRoom(player, supported);
        SocialChallenge value = challenges.save(
                new SocialChallenge(player.id(), friendId, room.id(), room.roomCode(), supported));
        notifications.create(friendId, "CHALLENGE_RECEIVED", "New chess challenge",
                player.displayName() + " challenged you to a " + supported + " minute match.",
                "CHALLENGE", value.id);
        return challenge(value, player.id());
    }

    @Transactional
    OnlineDtos.MatchDto acceptChallenge(AuthenticatedPlayer player, UUID challengeId) {
        SocialChallenge value = challenges.findById(challengeId)
                .orElseThrow(() -> new OnlineMatchException(HttpStatus.NOT_FOUND, "Challenge was not found."));
        if (!value.challengedId.equals(player.id()) || !"PENDING".equals(value.status)) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "This challenge cannot be accepted.");
        }
        if (!value.expiresAt.isAfter(Instant.now())) {
            value.status = "EXPIRED"; value.updatedAt = Instant.now(); challenges.save(value);
            throw new OnlineMatchException(HttpStatus.GONE, "This challenge has expired.");
        }
        matches.prepareForChallengeAcceptance(player.id(), value.matchId);
        OnlineDtos.MatchDto match = matches.joinRoom(player, value.roomCode);
        value.status = "ACCEPTED"; value.updatedAt = Instant.now(); challenges.save(value);
        notifications.create(value.challengerId, "CHALLENGE_ACCEPTED", "Challenge accepted",
                player.displayName() + " accepted your challenge. The match is ready.",
                "MATCH", value.matchId);
        return match;
    }

    @Transactional
    SocialDtos.SocialHubDto declineChallenge(AuthenticatedPlayer player, UUID challengeId) {
        SocialChallenge value = challenges.findById(challengeId)
                .orElseThrow(() -> new OnlineMatchException(HttpStatus.NOT_FOUND, "Challenge was not found."));
        if (!value.challengedId.equals(player.id()) || !"PENDING".equals(value.status)) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "This challenge cannot be declined.");
        }
        value.status = "DECLINED";
        value.updatedAt = Instant.now();
        challenges.save(value);
        notifications.create(value.challengerId, "CHALLENGE_DECLINED", "Challenge declined",
                player.displayName() + " declined your challenge.", "COMMUNITY", value.id);
        matches.cancelChallengeRoom(value.challengerId, value.matchId);
        return hub(player);
    }

    private SocialDtos.ChallengeDto challenge(SocialChallenge value, UUID currentPlayer) {
        UUID other = value.challengerId.equals(currentPlayer) ? value.challengedId : value.challengerId;
        PlayerRow opponent = findById(other);
        String status = "PENDING".equals(value.status) && !value.expiresAt.isAfter(Instant.now())
                ? "EXPIRED" : value.status;
        return new SocialDtos.ChallengeDto(value.id, value.challengerId, value.challengedId,
                opponent.displayName, opponent.photoUrl, value.timeControlMinutes, value.roomCode,
                value.matchId, status, value.challengedId.equals(currentPlayer), value.expiresAt);
    }

    private void normalizeChallenges(UUID playerId, boolean cancelOutgoingPending) {
        Instant now = Instant.now();
        for (SocialChallenge value : challenges.recentFor(playerId)) {
            if (!"PENDING".equals(value.status)) continue;
            boolean expired = !value.expiresAt.isAfter(now);
            boolean replaceOutgoing = cancelOutgoingPending && value.challengerId.equals(playerId);
            if (!expired && !replaceOutgoing) continue;
            value.status = expired ? "EXPIRED" : "CANCELLED";
            value.updatedAt = now;
            challenges.save(value);
            matches.cancelChallengeRoom(value.challengerId, value.matchId);
        }
    }

    private SocialDtos.PlayerDto player(UUID connectionId, UUID id, String relationship) {
        PlayerRow row = findById(id);
        OnlinePlayerRating rating = ratings.findById(id).orElse(null);
        return new SocialDtos.PlayerDto(connectionId, id, row.username, row.displayName, row.photoUrl,
                rating == null ? "Unknown" : rating.country,
                rating == null ? 1200 : rating.rating,
                rating == null ? 0 : rating.gamesPlayed, rating == null ? 0 : rating.wins,
                rating == null ? 0 : rating.draws, rating == null ? 0 : rating.losses,
                rating == null ? 1200 : rating.peakRating, presence.isOnline(id), relationship);
    }

    private PlayerRow findByUsername(String username) {
        String identity = username.startsWith("@") ? username.substring(1).trim() : username;
        List<PlayerRow> rows = jdbc.query("select id, username, display_name, photo_url from player_account where lower(username)=lower(?)",
                this::mapPlayer, identity);
        if (!rows.isEmpty()) return rows.getFirst();
        rows = jdbc.query("select id, username, display_name, photo_url from player_account where lower(display_name)=lower(?) order by created_at limit 2",
                this::mapPlayer, identity);
        if (rows.isEmpty()) throw new OnlineMatchException(HttpStatus.NOT_FOUND,
                "Player not found. Check their ChessVerseAI @username.");
        if (rows.size() > 1) throw new OnlineMatchException(HttpStatus.CONFLICT,
                "More than one player has this display name. Enter the exact @username.");
        return rows.getFirst();
    }

    private PlayerRow findById(UUID id) {
        List<PlayerRow> rows = jdbc.query("select id, username, display_name, photo_url from player_account where id=?",
                this::mapPlayer, id);
        if (rows.isEmpty()) throw new OnlineMatchException(HttpStatus.NOT_FOUND, "ChessVerseAI player was not found.");
        return rows.getFirst();
    }

    private PlayerRow mapPlayer(ResultSet result, int row) throws SQLException {
        return new PlayerRow(result.getObject("id", UUID.class), result.getString("username"),
                result.getString("display_name"), result.getString("photo_url"));
    }

    private record PlayerRow(UUID id, String username, String displayName, String photoUrl) {}
}

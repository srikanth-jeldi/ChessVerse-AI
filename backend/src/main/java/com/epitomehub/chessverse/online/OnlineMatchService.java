package com.epitomehub.chessverse.online;

import static com.epitomehub.chessverse.online.OnlineDtos.*;

import com.epitomehub.chessverse.auth.AuthSessionResolver.AuthenticatedPlayer;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
class OnlineMatchService {
    private static final char[] ROOM_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();

    private final OnlineMatchRepository matches;
    private final OnlineMoveRepository moves;
    private final SecureRandom random = new SecureRandom();

    OnlineMatchService(OnlineMatchRepository matches, OnlineMoveRepository moves) {
        this.matches = matches;
        this.moves = moves;
    }

    @Transactional
    MatchResponse createRoom(AuthenticatedPlayer player) {
        OnlineMatch match = matches.save(new OnlineMatch(newRoomCode(), player.id(), player.displayName()));
        return response(match, player.id());
    }

    @Transactional
    MatchResponse joinRoom(String roomCode, AuthenticatedPlayer player) {
        OnlineMatch match = matches.findByRoomCodeIgnoreCase(roomCode.trim())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Room not found."));
        return join(match, player);
    }

    @Transactional
    MatchResponse randomMatch(AuthenticatedPlayer player) {
        OnlineMatch waiting = matches
                .findFirstByStatusAndWhitePlayerIdNotOrderByCreatedAtAsc("WAITING", player.id())
                .orElse(null);
        if (waiting == null) {
            return createRoom(player);
        }
        return join(waiting, player);
    }

    @Transactional(readOnly = true)
    MatchResponse get(UUID matchId, AuthenticatedPlayer player) {
        return response(requireMember(matchId, player.id()), player.id());
    }

    @Transactional(readOnly = true)
    MatchResponse reconnect(AuthenticatedPlayer player) {
        return matches.findTop10ByWhitePlayerIdOrBlackPlayerIdOrderByUpdatedAtDesc(player.id(), player.id())
                .stream()
                .filter(match -> !"FINISHED".equals(match.status))
                .findFirst()
                .map(match -> response(match, player.id()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No active online match."));
    }

    @Transactional
    MatchResponse submitMove(
            UUID matchId, SubmitMoveRequest request, AuthenticatedPlayer player) {
        OnlineMatch match = requireMember(matchId, player.id());
        if (!"ACTIVE".equals(match.status)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Waiting for an opponent.");
        }
        if (request.expectedPly() != match.plyCount) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Match changed. Refresh and try again.");
        }
        boolean whiteTurn = "WHITE".equals(match.activeColor);
        UUID expectedPlayer = whiteTurn ? match.whitePlayerId : match.blackPlayerId;
        if (!player.id().equals(expectedPlayer)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Wait for your opponent's move.");
        }

        String uci = request.uci().toLowerCase(Locale.ROOT);
        moves.save(new OnlineMove(match.id, match.plyCount, uci, player.id()));
        match.plyCount++;
        match.activeColor = whiteTurn ? "BLACK" : "WHITE";
        match.updatedAt = Instant.now();
        matches.save(match);
        return response(match, player.id());
    }

    private MatchResponse join(OnlineMatch match, AuthenticatedPlayer player) {
        if (player.id().equals(match.whitePlayerId)) {
            return response(match, player.id());
        }
        if (!"WAITING".equals(match.status) || match.blackPlayerId != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This room is already full.");
        }
        match.blackPlayerId = player.id();
        match.blackPlayerName = player.displayName();
        match.status = "ACTIVE";
        match.updatedAt = Instant.now();
        matches.save(match);
        return response(match, player.id());
    }

    private OnlineMatch requireMember(UUID matchId, UUID playerId) {
        OnlineMatch match = matches.findById(matchId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Match not found."));
        if (!playerId.equals(match.whitePlayerId) && !playerId.equals(match.blackPlayerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You are not part of this match.");
        }
        return match;
    }

    private MatchResponse response(OnlineMatch match, UUID playerId) {
        String color = playerId.equals(match.whitePlayerId) ? "WHITE" : "BLACK";
        List<MoveResponse> history = moves.findByMatchIdOrderByPlyAsc(match.id)
                .stream()
                .map(MoveResponse::from)
                .toList();
        return new MatchResponse(
                match.id,
                match.roomCode,
                match.status,
                color,
                match.activeColor,
                match.plyCount,
                match.whitePlayerName,
                match.blackPlayerName,
                history,
                match.updatedAt);
    }

    private String newRoomCode() {
        String code;
        do {
            StringBuilder value = new StringBuilder(6);
            for (int i = 0; i < 6; i++) {
                value.append(ROOM_ALPHABET[random.nextInt(ROOM_ALPHABET.length)]);
            }
            code = value.toString();
        } while (matches.findByRoomCodeIgnoreCase(code).isPresent());
        return code;
    }
}


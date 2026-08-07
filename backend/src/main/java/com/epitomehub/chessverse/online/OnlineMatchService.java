package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.github.bhlangonijr.chesslib.Board;
import com.github.bhlangonijr.chesslib.Side;
import com.github.bhlangonijr.chesslib.Square;
import com.github.bhlangonijr.chesslib.move.Move;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OnlineMatchService {
    private static final char[] CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
    private static final Duration RANDOM_QUEUE_LEASE = Duration.ofSeconds(8);
    // Mobile radios and app lifecycle transitions can take several seconds to
    // restore the websocket. Give a temporarily interrupted player a full
    // minute to reconnect before awarding the game to the opponent.
    static final Duration DISCONNECT_GRACE = Duration.ofSeconds(60);

    private final OnlineMatchRepository matches;
    private final OnlineRatingService ratings;
    private final SecureRandom random = new SecureRandom();

    public OnlineMatchService(
            OnlineMatchRepository matches, OnlineRatingService ratings) {
        this.matches = matches;
        this.ratings = ratings;
    }

    @Transactional
    public OnlineDtos.MatchDto createRoom(AuthenticatedPlayer player) {
        OnlineMatch current = current(player.id());
        if (current != null) {
            return OnlineDtos.MatchDto.from(current, player.id());
        }
        return OnlineDtos.MatchDto.from(createWaiting(player, false), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto randomMatch(AuthenticatedPlayer player) {
        OnlineMatch current = current(player.id());
        if (current != null) {
            if (current.status == OnlineMatchStatus.WAITING && current.randomQueue) {
                current.updatedAt = Instant.now();
                current = matches.save(current);
            }
            return OnlineDtos.MatchDto.from(current, player.id());
        }
        Instant now = Instant.now();
        OnlineMatch opponent = matches
                .lockOldestRandomOpponent(player.id(), now.minus(RANDOM_QUEUE_LEASE))
                .orElse(null);
        if (opponent == null) {
            return OnlineDtos.MatchDto.from(createWaiting(player, true), player.id());
        }
        activate(opponent, player);
        return OnlineDtos.MatchDto.from(matches.save(opponent), player.id());
    }

    @Transactional(readOnly = true)
    public long waitingRandomPlayerCount() {
        return matches.countFreshRandomQueue(Instant.now().minus(RANDOM_QUEUE_LEASE));
    }

    @Transactional
    public OnlineDtos.MatchDto joinRoom(AuthenticatedPlayer player, String rawCode) {
        OnlineMatch current = current(player.id());
        if (current != null) {
            return OnlineDtos.MatchDto.from(current, player.id());
        }
        String code = rawCode.trim().toUpperCase(Locale.ROOT);
        OnlineMatch match = matches.findByRoomCodeIgnoreCase(code)
                .orElseThrow(() -> new OnlineMatchException(HttpStatus.NOT_FOUND, "Room code was not found."));
        if (match.status != OnlineMatchStatus.WAITING) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "That room is no longer waiting for a player.");
        }
        if (match.whitePlayerId.equals(player.id())) {
            return OnlineDtos.MatchDto.from(match, player.id());
        }
        activate(match, player);
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto get(AuthenticatedPlayer player, UUID matchId) {
        OnlineMatch match = requireParticipant(player.id(), matchId);
        Instant now = Instant.now();
        reconcileClock(match, now);
        if (match.status == OnlineMatchStatus.WAITING && match.randomQueue) {
            // Polling is the random-queue heartbeat. A browser/app that leaves
            // this screen stops refreshing and cannot be paired after lease
            // expiry, even if its cancel request was lost.
            match.updatedAt = now;
        }
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto reconnect(AuthenticatedPlayer player) {
        OnlineMatch match = current(player.id());
        if (match == null) {
            throw new OnlineMatchException(HttpStatus.NOT_FOUND, "No unfinished online match was found.");
        }
        reconcileClock(match, Instant.now());
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional(readOnly = true)
    public List<OnlineDtos.MatchDto> history(AuthenticatedPlayer player) {
        return matches.findRecentForPlayer(player.id()).stream()
                .map(match -> OnlineDtos.MatchDto.from(match, player.id()))
                .toList();
    }

    @Transactional
    public OnlineDtos.MatchDto cancelWaiting(AuthenticatedPlayer player, UUID matchId) {
        OnlineMatch match = requireParticipant(player.id(), matchId);
        if (match.status != OnlineMatchStatus.WAITING) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "An active match cannot be cancelled from the lobby.");
        }
        match.status = OnlineMatchStatus.CANCELLED;
        match.updatedAt = Instant.now();
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto move(
            AuthenticatedPlayer player,
            UUID matchId,
            String rawUci,
            int expectedPly) {
        OnlineMatch match = requireParticipant(player.id(), matchId);
        reconcileClock(match, Instant.now());
        if (match.status != OnlineMatchStatus.ACTIVE) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "The match is not active.");
        }
        if (match.moves.size() != expectedPly) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "The board changed. Sync the match and try again.");
        }
        String playerColor = match.whitePlayerId.equals(player.id()) ? "white" : "black";
        if (!match.activeColor.equals(playerColor)) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "Wait for your opponent to move.");
        }

        String uci = rawUci.toLowerCase(Locale.ROOT);
        Board board = new Board();
        board.loadFromFen(match.fen);
        Move move;
        try {
            Square from = Square.valueOf(uci.substring(0, 2).toUpperCase(Locale.ROOT));
            Square to = Square.valueOf(uci.substring(2, 4).toUpperCase(Locale.ROOT));
            move = uci.length() == 5
                    ? new Move(from, to, promotion(uci.charAt(4), board.getSideToMove()))
                    : new Move(from, to);
        } catch (RuntimeException exception) {
            throw new OnlineMatchException(HttpStatus.BAD_REQUEST, "Move is not valid UCI notation.");
        }
        if (!board.legalMoves().contains(move)) {
            throw new OnlineMatchException(HttpStatus.UNPROCESSABLE_ENTITY, "That move is not legal in this position.");
        }
        board.doMove(move);
        match.moves.add(uci);
        match.fen = board.getFen();
        match.activeColor = board.getSideToMove() == Side.WHITE ? "white" : "black";
        match.updatedAt = Instant.now();
        match.turnStartedAt = match.updatedAt;
        match.drawOfferedBy = null;
        if (board.isMated() || board.isStaleMate() || board.isDraw()) {
            if (board.isMated()) {
                finish(match, playerColor.equals("white") ? "1-0" : "0-1", "CHECKMATE");
            } else {
                finish(match, "1/2-1/2", board.isStaleMate() ? "STALEMATE" : "DRAW");
            }
        }
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto resign(AuthenticatedPlayer player, UUID matchId) {
        OnlineMatch match = requireActive(player.id(), matchId);
        reconcileClock(match, Instant.now());
        if (match.status != OnlineMatchStatus.ACTIVE) {
            return OnlineDtos.MatchDto.from(matches.save(match), player.id());
        }
        boolean whiteResigned = match.whitePlayerId.equals(player.id());
        finish(match, whiteResigned ? "0-1" : "1-0", "RESIGNATION");
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto offerDraw(AuthenticatedPlayer player, UUID matchId) {
        OnlineMatch match = requireActive(player.id(), matchId);
        reconcileClock(match, Instant.now());
        if (match.status != OnlineMatchStatus.ACTIVE) {
            return OnlineDtos.MatchDto.from(matches.save(match), player.id());
        }
        if (match.drawOfferedBy != null) {
            String message = player.id().equals(match.drawOfferedBy)
                    ? "Your draw offer is already pending."
                    : "Answer your opponent's draw offer before making another offer.";
            throw new OnlineMatchException(HttpStatus.CONFLICT, message);
        }
        match.drawOfferedBy = player.id();
        match.updatedAt = Instant.now();
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto respondDraw(
            AuthenticatedPlayer player, UUID matchId, boolean accept) {
        OnlineMatch match = requireActive(player.id(), matchId);
        reconcileClock(match, Instant.now());
        if (match.status != OnlineMatchStatus.ACTIVE) {
            return OnlineDtos.MatchDto.from(matches.save(match), player.id());
        }
        if (match.drawOfferedBy == null || player.id().equals(match.drawOfferedBy)) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "There is no opponent draw offer to answer.");
        }
        if (accept) {
            finish(match, "1/2-1/2", "DRAW_AGREEMENT");
        } else {
            match.drawOfferedBy = null;
            match.updatedAt = Instant.now();
        }
        return OnlineDtos.MatchDto.from(matches.save(match), player.id());
    }

    @Transactional
    public OnlineDtos.MatchDto requestRematch(AuthenticatedPlayer player, UUID matchId) {
        OnlineMatch previous = requireParticipant(player.id(), matchId);
        if (previous.status != OnlineMatchStatus.FINISHED) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "Finish the current match before requesting a rematch.");
        }
        if (previous.rematchMatchId != null) {
            OnlineMatch rematch = matches.findById(previous.rematchMatchId)
                    .orElseThrow(() -> new OnlineMatchException(HttpStatus.NOT_FOUND, "Rematch was not found."));
            return OnlineDtos.MatchDto.from(rematch, player.id());
        }
        if (previous.rematchRequestedBy == null) {
            previous.rematchRequestedBy = player.id();
            previous.updatedAt = Instant.now();
            return OnlineDtos.MatchDto.from(matches.save(previous), player.id());
        }
        if (player.id().equals(previous.rematchRequestedBy)) {
            return OnlineDtos.MatchDto.from(previous, player.id());
        }

        OnlineMatch rematch = new OnlineMatch(
                UUID.randomUUID(),
                newRoomCode(),
                previous.blackPlayerId,
                previous.blackPlayerName,
                previous.blackPlayerPhotoUrl,
                false);
        rematch.blackPlayerId = previous.whitePlayerId;
        rematch.blackPlayerName = previous.whitePlayerName;
        rematch.blackPlayerPhotoUrl = previous.whitePlayerPhotoUrl;
        rematch.status = OnlineMatchStatus.ACTIVE;
        rematch.startedAt = Instant.now();
        rematch.turnStartedAt = rematch.startedAt;
        rematch.updatedAt = rematch.turnStartedAt;
        rematch = matches.save(rematch);
        previous.rematchMatchId = rematch.id;
        previous.updatedAt = Instant.now();
        matches.save(previous);
        return OnlineDtos.MatchDto.from(rematch, player.id());
    }

    @Transactional(readOnly = true)
    public boolean isParticipant(UUID playerId, UUID matchId) {
        return matches.findById(matchId).map(match -> match.contains(playerId)).orElse(false);
    }

    @Transactional
    public void markConnected(UUID matchId, UUID playerId) {
        OnlineMatch match = requireParticipant(playerId, matchId);
        if (match.status != OnlineMatchStatus.ACTIVE) return;
        if (match.whitePlayerId.equals(playerId)) {
            match.whiteDisconnectedAt = null;
        } else {
            match.blackDisconnectedAt = null;
        }
        match.updatedAt = Instant.now();
        matches.save(match);
    }

    @Transactional
    public void markDisconnected(UUID matchId, UUID playerId) {
        markDisconnected(matchId, playerId, Instant.now());
    }

    @Transactional
    public void markDisconnected(UUID matchId, UUID playerId, Instant disconnectedAt) {
        OnlineMatch match = requireParticipant(playerId, matchId);
        if (match.status != OnlineMatchStatus.ACTIVE) return;
        Instant now = Instant.now();
        reconcileClock(match, now);
        if (match.status != OnlineMatchStatus.ACTIVE) {
            matches.save(match);
            return;
        }
        if (match.whitePlayerId.equals(playerId)) {
            if (match.whiteDisconnectedAt == null) match.whiteDisconnectedAt = disconnectedAt;
        } else if (match.blackDisconnectedAt == null) {
            match.blackDisconnectedAt = disconnectedAt;
        }
        match.updatedAt = now;
        matches.save(match);
    }

    @Transactional
    public List<UUID> finishExpiredDisconnects() {
        Instant now = Instant.now();
        List<OnlineMatch> expired = matches.lockExpiredDisconnects(now.minus(DISCONNECT_GRACE));
        for (OnlineMatch match : expired) {
            reconcileClock(match, now);
            if (match.status != OnlineMatchStatus.ACTIVE) continue;
            boolean whiteExpired = match.whiteDisconnectedAt != null
                    && !match.whiteDisconnectedAt.plus(DISCONNECT_GRACE).isAfter(now);
            boolean blackExpired = match.blackDisconnectedAt != null
                    && !match.blackDisconnectedAt.plus(DISCONNECT_GRACE).isAfter(now);
            if (whiteExpired && blackExpired) {
                finish(match, "1/2-1/2", "BOTH_DISCONNECTED");
            } else if (whiteExpired) {
                finish(match, "0-1", "OPPONENT_LEFT");
            } else if (blackExpired) {
                finish(match, "1-0", "OPPONENT_LEFT");
            }
            matches.save(match);
        }
        return expired.stream().map(match -> match.id).toList();
    }

    private com.github.bhlangonijr.chesslib.Piece promotion(char code, Side side) {
        return switch (code) {
            case 'q' -> side == Side.WHITE
                    ? com.github.bhlangonijr.chesslib.Piece.WHITE_QUEEN
                    : com.github.bhlangonijr.chesslib.Piece.BLACK_QUEEN;
            case 'r' -> side == Side.WHITE
                    ? com.github.bhlangonijr.chesslib.Piece.WHITE_ROOK
                    : com.github.bhlangonijr.chesslib.Piece.BLACK_ROOK;
            case 'b' -> side == Side.WHITE
                    ? com.github.bhlangonijr.chesslib.Piece.WHITE_BISHOP
                    : com.github.bhlangonijr.chesslib.Piece.BLACK_BISHOP;
            case 'n' -> side == Side.WHITE
                    ? com.github.bhlangonijr.chesslib.Piece.WHITE_KNIGHT
                    : com.github.bhlangonijr.chesslib.Piece.BLACK_KNIGHT;
            default -> throw new OnlineMatchException(HttpStatus.BAD_REQUEST, "Invalid promotion piece.");
        };
    }

    private OnlineMatch requireParticipant(UUID playerId, UUID matchId) {
        OnlineMatch match = matches.lockById(matchId)
                .orElseThrow(() -> new OnlineMatchException(HttpStatus.NOT_FOUND, "Online match was not found."));
        if (!match.contains(playerId)) {
            throw new OnlineMatchException(HttpStatus.FORBIDDEN, "You are not a player in this match.");
        }
        return match;
    }

    private OnlineMatch requireActive(UUID playerId, UUID matchId) {
        OnlineMatch match = requireParticipant(playerId, matchId);
        if (match.status != OnlineMatchStatus.ACTIVE) {
            throw new OnlineMatchException(HttpStatus.CONFLICT, "The match is not active.");
        }
        return match;
    }

    private OnlineMatch current(UUID playerId) {
        return matches.findCurrentForPlayer(playerId).orElse(null);
    }

    private OnlineMatch createWaiting(AuthenticatedPlayer player, boolean randomQueue) {
        return matches.save(new OnlineMatch(
                UUID.randomUUID(),
                newRoomCode(),
                player.id(),
                player.displayName(),
                player.photoUrl(),
                randomQueue));
    }

    private void activate(OnlineMatch match, AuthenticatedPlayer player) {
        match.blackPlayerId = player.id();
        match.blackPlayerName = player.displayName();
        match.blackPlayerPhotoUrl = player.photoUrl();
        match.status = OnlineMatchStatus.ACTIVE;
        match.updatedAt = Instant.now();
        match.startedAt = match.updatedAt;
        match.turnStartedAt = match.updatedAt;
    }

    private String newRoomCode() {
        String code;
        do {
            StringBuilder builder = new StringBuilder("CV");
            for (int i = 0; i < 4; i++) {
                builder.append(CODE_ALPHABET[random.nextInt(CODE_ALPHABET.length)]);
            }
            code = builder.toString();
        } while (matches.findByRoomCodeIgnoreCase(code).isPresent());
        return code;
    }

    private void reconcileClock(OnlineMatch match, Instant now) {
        if (match.status != OnlineMatchStatus.ACTIVE || match.turnStartedAt == null) return;
        long elapsed = Math.max(0, Duration.between(match.turnStartedAt, now).toMillis());
        if ("white".equals(match.activeColor)) {
            match.whiteTimeMs = Math.max(0, match.whiteTimeMs - elapsed);
            if (match.whiteTimeMs == 0) finish(match, "0-1", "TIMEOUT");
        } else {
            match.blackTimeMs = Math.max(0, match.blackTimeMs - elapsed);
            if (match.blackTimeMs == 0) finish(match, "1-0", "TIMEOUT");
        }
        if (match.status == OnlineMatchStatus.ACTIVE) {
            match.turnStartedAt = now;
            match.updatedAt = now;
        }
    }

    private void finish(OnlineMatch match, String result, String reason) {
        match.status = OnlineMatchStatus.FINISHED;
        match.result = result;
        match.resultReason = reason;
        match.drawOfferedBy = null;
        match.turnStartedAt = null;
        match.whiteDisconnectedAt = null;
        match.blackDisconnectedAt = null;
        match.finishedAt = Instant.now();
        match.updatedAt = match.finishedAt;
        ratings.settle(match);
    }
}

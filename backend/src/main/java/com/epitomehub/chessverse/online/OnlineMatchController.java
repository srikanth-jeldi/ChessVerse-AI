package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import java.util.UUID;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/online")
public class OnlineMatchController {
    private final PlayerAuthenticationService authentication;
    private final OnlineMatchService matches;
    private final OnlineMatchSocketHandler socket;
    private final OnlinePresenceService presence;
    private final WebSocketTicketService tickets;

    public OnlineMatchController(
            PlayerAuthenticationService authentication,
            OnlineMatchService matches,
            OnlineMatchSocketHandler socket,
            OnlinePresenceService presence,
            WebSocketTicketService tickets) {
        this.authentication = authentication;
        this.matches = matches;
        this.socket = socket;
        this.presence = presence;
        this.tickets = tickets;
    }

    @PostMapping("/presence")
    OnlineDtos.PresenceDto presence(@RequestHeader("Authorization") String authorization) {
        AuthenticatedPlayer player = player(authorization);
        return new OnlineDtos.PresenceDto(presence.heartbeat(player.id()));
    }

    @GetMapping("/presence")
    OnlineDtos.PresenceDto legacyMatchmakingPresence() {
        return new OnlineDtos.PresenceDto(
                matches.waitingRandomPlayerCount() + socket.connectedPlayerCount());
    }

    @PostMapping("/queue")
    OnlineDtos.MatchDto queue(
            @RequestHeader("Authorization") String authorization,
            @Valid @RequestBody(required = false) OnlineDtos.QueueRequest request) {
        OnlineDtos.QueueRequest preferences = request == null
                ? new OnlineDtos.QueueRequest(10, "WORLDWIDE", 0, 100) : request;
        OnlineDtos.MatchDto match = matches.randomMatch(player(authorization), preferences);
        socket.publish(match.id());
        return match;
    }

    @PostMapping("/rooms")
    OnlineDtos.MatchDto createRoom(@RequestHeader("Authorization") String authorization) {
        return matches.createRoom(player(authorization));
    }

    @PostMapping("/rooms/join")
    OnlineDtos.MatchDto joinRoom(
            @RequestHeader("Authorization") String authorization,
            @Valid @RequestBody OnlineDtos.JoinRoomRequest request) {
        OnlineDtos.MatchDto match = matches.joinRoom(player(authorization), request.roomCode());
        socket.publish(match.id());
        return match;
    }

    @GetMapping("/matches/current")
    OnlineDtos.MatchDto reconnect(@RequestHeader("Authorization") String authorization) {
        return matches.reconnect(player(authorization));
    }

    @GetMapping("/matches/{matchId}")
    OnlineDtos.MatchDto get(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId) {
        return matches.get(player(authorization), matchId);
    }

    @PostMapping("/matches/{matchId}/ws-ticket")
    WebSocketTicketService.Ticket webSocketTicket(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId) {
        return tickets.issue(player(authorization), matchId);
    }

    @GetMapping("/matches/history")
    List<OnlineDtos.MatchDto> history(
            @RequestHeader("Authorization") String authorization) {
        return matches.history(player(authorization));
    }

    @DeleteMapping("/matches/{matchId}/waiting")
    OnlineDtos.MatchDto cancelWaiting(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId) {
        OnlineDtos.MatchDto match = matches.cancelWaiting(player(authorization), matchId);
        socket.publish(match.id());
        return match;
    }

    @PostMapping("/matches/{matchId}/moves")
    OnlineDtos.MatchDto move(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId,
            @Valid @RequestBody OnlineDtos.MoveRequest request) {
        OnlineDtos.MatchDto match = matches.move(
                player(authorization), matchId, request.uci(), request.expectedPly());
        socket.publish(match.id());
        return match;
    }

    @PostMapping("/matches/{matchId}/resign")
    OnlineDtos.MatchDto resign(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId) {
        OnlineDtos.MatchDto match = matches.resign(player(authorization), matchId);
        socket.publish(match.id());
        return match;
    }

    @PostMapping("/matches/{matchId}/draw")
    OnlineDtos.MatchDto offerDraw(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId) {
        OnlineDtos.MatchDto match = matches.offerDraw(player(authorization), matchId);
        socket.publish(match.id());
        return match;
    }

    @PostMapping("/matches/{matchId}/draw/respond")
    OnlineDtos.MatchDto respondDraw(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId,
            @RequestBody OnlineDtos.DrawResponseRequest request) {
        OnlineDtos.MatchDto match =
                matches.respondDraw(player(authorization), matchId, request.accept());
        socket.publish(match.id());
        return match;
    }

    @PostMapping("/matches/{matchId}/rematch")
    OnlineDtos.MatchDto rematch(
            @RequestHeader("Authorization") String authorization,
            @PathVariable UUID matchId) {
        OnlineDtos.MatchDto match = matches.requestRematch(player(authorization), matchId);
        socket.publish(matchId);
        socket.publish(match.id());
        return match;
    }

    private AuthenticatedPlayer player(String authorization) {
        return authentication.requireBearer(authorization);
    }
}

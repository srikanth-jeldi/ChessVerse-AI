package com.epitomehub.chessverse.online;

import static com.epitomehub.chessverse.online.OnlineDtos.*;

import com.epitomehub.chessverse.auth.AuthSessionResolver;
import com.epitomehub.chessverse.auth.AuthSessionResolver.AuthenticatedPlayer;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/online")
public class OnlineMatchController {
    private final AuthSessionResolver sessions;
    private final OnlineMatchService service;

    public OnlineMatchController(AuthSessionResolver sessions, OnlineMatchService service) {
        this.sessions = sessions;
        this.service = service;
    }

    @PostMapping("/rooms")
    MatchResponse createRoom(@RequestHeader(name = "Authorization", required = false) String authorization) {
        return service.createRoom(player(authorization));
    }

    @PostMapping("/rooms/join")
    MatchResponse joinRoom(
            @RequestHeader(name = "Authorization", required = false) String authorization,
            @Valid @RequestBody JoinRoomRequest request) {
        return service.joinRoom(request.roomCode(), player(authorization));
    }

    @PostMapping("/matchmaking/random")
    MatchResponse randomMatch(@RequestHeader(name = "Authorization", required = false) String authorization) {
        return service.randomMatch(player(authorization));
    }

    @GetMapping("/matches/{id}")
    MatchResponse get(
            @PathVariable UUID id,
            @RequestHeader(name = "Authorization", required = false) String authorization) {
        return service.get(id, player(authorization));
    }

    @GetMapping("/reconnect")
    MatchResponse reconnect(@RequestHeader(name = "Authorization", required = false) String authorization) {
        return service.reconnect(player(authorization));
    }

    @PostMapping("/matches/{id}/moves")
    MatchResponse move(
            @PathVariable UUID id,
            @RequestHeader(name = "Authorization", required = false) String authorization,
            @Valid @RequestBody SubmitMoveRequest request) {
        return service.submitMove(id, request, player(authorization));
    }

    private AuthenticatedPlayer player(String authorization) {
        return sessions.requirePlayer(authorization);
    }
}

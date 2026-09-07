package com.epitomehub.chessverse.progression;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/progression/missions")
class MissionController {
    private final PlayerAuthenticationService authentication;
    private final MissionService missions;

    MissionController(PlayerAuthenticationService authentication, MissionService missions) {
        this.authentication = authentication;
        this.missions = missions;
    }

    @GetMapping
    MissionDtos.MissionBoardDto board(@RequestHeader("Authorization") String authorization) {
        return missions.board(player(authorization));
    }

    @PostMapping("/{code}/claim")
    MissionDtos.ClaimDto claim(@RequestHeader("Authorization") String authorization,
                               @PathVariable String code) {
        return missions.claim(player(authorization), code);
    }

    private AuthenticatedPlayer player(String authorization) {
        return authentication.requireBearer(authorization);
    }
}

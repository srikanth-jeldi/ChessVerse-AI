package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/social")
class SocialController {
    private final PlayerAuthenticationService authentication;
    private final SocialService social;
    private final OnlineMatchSocketHandler socket;

    SocialController(PlayerAuthenticationService authentication, SocialService social,
                     OnlineMatchSocketHandler socket) {
        this.authentication = authentication; this.social = social; this.socket = socket;
    }

    @GetMapping SocialDtos.SocialHubDto hub(@RequestHeader("Authorization") String auth) {
        return social.hub(player(auth));
    }
    @PostMapping("/friends") SocialDtos.SocialHubDto request(@RequestHeader("Authorization") String auth,
            @Valid @RequestBody SocialDtos.FriendRequest request) {
        return social.request(player(auth), request.username());
    }
    @PutMapping("/friends/{id}") SocialDtos.SocialHubDto respond(@RequestHeader("Authorization") String auth,
            @PathVariable UUID id, @RequestParam boolean accept) {
        return social.respond(player(auth), id, accept);
    }
    @DeleteMapping("/friends/{friendId}") SocialDtos.SocialHubDto remove(
            @RequestHeader("Authorization") String auth, @PathVariable UUID friendId) {
        return social.remove(player(auth), friendId);
    }
    @PostMapping("/challenges") SocialDtos.ChallengeDto challenge(
            @RequestHeader("Authorization") String auth,
            @Valid @RequestBody SocialDtos.ChallengeRequest request) {
        return social.challenge(player(auth), request.friendId(), request.timeControlMinutes());
    }
    @PostMapping("/challenges/{id}/accept") OnlineDtos.MatchDto accept(
            @RequestHeader("Authorization") String auth, @PathVariable UUID id) {
        OnlineDtos.MatchDto match = social.acceptChallenge(player(auth), id);
        socket.publish(match.id());
        return match;
    }
    @PostMapping("/challenges/{id}/decline") SocialDtos.SocialHubDto decline(
            @RequestHeader("Authorization") String auth, @PathVariable UUID id) {
        return social.declineChallenge(player(auth), id);
    }
    private AuthenticatedPlayer player(String auth) { return authentication.requireBearer(auth); }
}

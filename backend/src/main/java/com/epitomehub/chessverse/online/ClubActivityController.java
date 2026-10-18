package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/community/clubs/{club}/activities")
class ClubActivityController {
    private final PlayerAuthenticationService auth;
    private final ClubActivityService activities;
    private final SocialService social;
    ClubActivityController(PlayerAuthenticationService auth, ClubActivityService activities, SocialService social) {
        this.auth=auth; this.activities=activities; this.social=social;
    }
    @GetMapping
    ClubActivityService.Detail detail(@RequestHeader("Authorization") String token,@PathVariable UUID club) {
        return activities.detail(auth.requireBearer(token),club);
    }
    record PuzzleRequest(@NotNull LocalDate day,@NotNull @Size(min=1,max=30) List<@NotNull @Pattern(regexp="[a-h][1-8][a-h][1-8][qrbn]?") String> moves) {}
    @PostMapping("/puzzle")
    ClubActivityService.Attempt puzzle(@RequestHeader("Authorization") String token,@PathVariable UUID club,@Valid @RequestBody PuzzleRequest request) {
        return activities.attempt(auth.requireBearer(token),club,request.day(),request.moves());
    }
    record HelpRequest(@NotNull LocalDate day,@NotNull @Size(max=30) List<@NotNull @Pattern(regexp="[a-h][1-8][a-h][1-8][qrbn]?") String> moves, boolean reveal) {}
    @PostMapping("/puzzle/help")
    ClubActivityService.Help help(@RequestHeader("Authorization") String token,@PathVariable UUID club,@Valid @RequestBody HelpRequest request) {
        return activities.help(auth.requireBearer(token),club,request.day(),request.moves(),request.reveal());
    }
    record ChallengeRequest(@NotNull UUID memberId,@Min(3) @Max(15) int minutes) {}
    @PostMapping("/challenge")
    SocialDtos.ChallengeDto challenge(@RequestHeader("Authorization") String token,@PathVariable UUID club,@Valid @RequestBody ChallengeRequest request) {
        return social.clubChallenge(auth.requireBearer(token),club,request.memberId(),request.minutes());
    }
}

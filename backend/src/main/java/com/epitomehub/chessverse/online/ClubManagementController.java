package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Map;
import java.util.UUID;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/community/clubs")
class ClubManagementController {
    private final PlayerAuthenticationService auth;
    private final ClubManagementService clubs;
    private final SocialService social;
    ClubManagementController(PlayerAuthenticationService auth, ClubManagementService clubs, SocialService social) {
        this.auth = auth; this.clubs = clubs; this.social = social;
    }
    record CreateRequest(@NotBlank @Size(max=80) String name, @Size(max=240) String description) {}
    record InviteRequest(@NotBlank @Size(max=254) String identity) {}
    @PostMapping
    CommunityDtos.ClubDto create(@RequestHeader("Authorization") String token, @Valid @RequestBody CreateRequest request) {
        return clubs.create(auth.requireBearer(token), request.name(), request.description() == null ? "" : request.description());
    }
    @PostMapping("/{clubId}/invites")
    Map<String, String> invite(@RequestHeader("Authorization") String token, @PathVariable UUID clubId,
                              @Valid @RequestBody InviteRequest request) {
        clubs.invite(auth.requireBearer(token), clubId, request.identity());
        return Map.of("status", "sent");
    }
    @GetMapping("/{clubId}/challenges")
    Map<String, Object> challenges(@RequestHeader("Authorization") String token, @PathVariable UUID clubId) {
        return Map.of("challenges", social.clubChallenges(auth.requireBearer(token), clubId));
    }
}

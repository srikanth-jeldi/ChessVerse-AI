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
    private final ClubEmailInvitationService emailInvitations;
    ClubManagementController(PlayerAuthenticationService auth, ClubManagementService clubs, SocialService social, ClubEmailInvitationService emailInvitations) {
        this.auth = auth; this.clubs = clubs; this.social = social; this.emailInvitations = emailInvitations;
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
        var player = auth.requireBearer(token);
        if (request.identity().trim().contains("@") && !request.identity().trim().startsWith("@")) {
            emailInvitations.invite(player, clubId, request.identity());
            return Map.of("status", "queued");
        }
        clubs.invite(player, clubId, request.identity());
        return Map.of("status", "sent");
    }
    @GetMapping("/invitations")
    Map<String, Object> invitations(@RequestHeader("Authorization") String token) {
        return Map.of("invitations", emailInvitations.incoming(auth.requireBearer(token)));
    }
    record RespondInvitation(boolean accept) {}
    @PostMapping("/invitations/{id}/respond")
    Map<String, Object> respondInvitation(@RequestHeader("Authorization") String token, @PathVariable UUID id,
                                         @RequestBody RespondInvitation request) {
        return Map.of("clubId", emailInvitations.respond(auth.requireBearer(token), id, request.accept()));
    }
    @GetMapping("/{clubId}/challenges")
    Map<String, Object> challenges(@RequestHeader("Authorization") String token, @PathVariable UUID clubId) {
        return Map.of("challenges", social.clubChallenges(auth.requireBearer(token), clubId));
    }
}

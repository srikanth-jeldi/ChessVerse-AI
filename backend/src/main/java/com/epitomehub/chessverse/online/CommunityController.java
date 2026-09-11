package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/community")
class CommunityController {
    private final PlayerAuthenticationService authentication; private final CommunityService community; private final TournamentService tournaments; private final GiphyMediaService media;
    CommunityController(PlayerAuthenticationService authentication,CommunityService community,TournamentService tournaments,GiphyMediaService media){this.authentication=authentication;this.community=community;this.tournaments=tournaments;this.media=media;}
    @GetMapping CommunityDtos.HubDto hub(@RequestHeader("Authorization")String auth){return community.hub(player(auth));}
    @PutMapping("/clubs/{id}") CommunityDtos.HubDto club(@RequestHeader("Authorization")String auth,@PathVariable UUID id,@RequestParam boolean join){return community.joinClub(player(auth),id,join);}
    @PostMapping("/clubs/{id}/tournaments") CommunityDtos.HubDto createClubTournament(
            @RequestHeader("Authorization") String auth, @PathVariable UUID id,
            @Valid @RequestBody CommunityDtos.CreateClubTournamentRequest request) {
        return community.createClubTournament(player(auth), id, request);
    }
    @PutMapping("/tournaments/{id}") CommunityDtos.HubDto tournament(@RequestHeader("Authorization")String auth,@PathVariable UUID id,@RequestParam boolean join){return community.joinTournament(player(auth),id,join);}
    @GetMapping("/tournaments/{id}") TournamentDtos.DetailDto tournamentDetail(@RequestHeader("Authorization")String auth,@PathVariable UUID id){return tournaments.detail(player(auth),id);}
    @GetMapping("/messages/{friendId}") List<CommunityDtos.MessageDto> messages(@RequestHeader("Authorization")String auth,@PathVariable UUID friendId){return community.messages(player(auth),friendId);}
    @PostMapping("/messages") CommunityDtos.MessageDto message(@RequestHeader("Authorization")String auth,@Valid @RequestBody CommunityDtos.MessageRequest request){return community.send(player(auth),request.recipientId(),request.body(),request.encrypted());}
    @GetMapping("/e2ee/identity") CommunityDtos.E2eeIdentityDto e2eeIdentity(@RequestHeader("Authorization") String auth) { return community.e2eeIdentity(player(auth)); }
    @PutMapping("/e2ee/identity") CommunityDtos.E2eeIdentityDto saveE2eeIdentity(@RequestHeader("Authorization") String auth, @Valid @RequestBody CommunityDtos.E2eeIdentityRequest request) { return community.saveE2eeIdentity(player(auth), request); }
    @GetMapping("/e2ee/public-key/{friendId}") CommunityDtos.E2eePublicKeyDto e2eePublicKey(@RequestHeader("Authorization") String auth, @PathVariable UUID friendId) { return community.e2eePublicKey(player(auth), friendId); }
    @PostMapping("/messages/delivered") void delivered(@RequestHeader("Authorization")String auth){community.markDelivered(player(auth));}
    @PostMapping(value="/messages/attachments",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    CommunityDtos.MessageDto attachment(@RequestHeader("Authorization")String auth,@RequestParam UUID recipientId,
                                         @RequestParam(required=false,defaultValue="") String body,
                                         @RequestParam(required=false,defaultValue="false") boolean encrypted,
                                         @RequestPart("file") MultipartFile file){return community.sendAttachment(player(auth),recipientId,body,file,encrypted);}
    @GetMapping("/messages/{messageId}/attachment")
    ResponseEntity<Resource> attachment(@RequestHeader("Authorization")String auth,@PathVariable UUID messageId){return community.attachment(player(auth),messageId);}
    @DeleteMapping("/messages/{messageId}")
    void deleteMessage(@RequestHeader("Authorization") String auth, @PathVariable UUID messageId,
                       @RequestParam(defaultValue="me") String scope) {
        community.deleteMessage(player(auth), messageId, scope);
    }
    @PutMapping("/messages/{messageId}/reaction")
    CommunityDtos.MessageDto react(@RequestHeader("Authorization") String auth,
                                   @PathVariable UUID messageId,
                                   @RequestParam(required=false) String emoji) {
        return community.react(player(auth), messageId, emoji);
    }
    @GetMapping("/media/search")
    List<GiphyMediaService.MediaResult> searchMedia(@RequestHeader("Authorization") String auth,
                                                   @RequestParam(defaultValue="chess") String q,
                                                   @RequestParam(defaultValue="gif") String kind,
                                                   @RequestParam(defaultValue="en_US") String locale,
                                                   @RequestParam(defaultValue="android") String platform) {
        player(auth);
        return media.search(q, kind, locale, platform);
    }
    private AuthenticatedPlayer player(String auth){return authentication.requireBearer(auth);}
}

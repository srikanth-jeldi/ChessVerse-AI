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
    private final PlayerAuthenticationService authentication; private final CommunityService community;
    CommunityController(PlayerAuthenticationService authentication,CommunityService community){this.authentication=authentication;this.community=community;}
    @GetMapping CommunityDtos.HubDto hub(@RequestHeader("Authorization")String auth){return community.hub(player(auth));}
    @PutMapping("/clubs/{id}") CommunityDtos.HubDto club(@RequestHeader("Authorization")String auth,@PathVariable UUID id,@RequestParam boolean join){return community.joinClub(player(auth),id,join);}
    @PutMapping("/tournaments/{id}") CommunityDtos.HubDto tournament(@RequestHeader("Authorization")String auth,@PathVariable UUID id,@RequestParam boolean join){return community.joinTournament(player(auth),id,join);}
    @GetMapping("/messages/{friendId}") List<CommunityDtos.MessageDto> messages(@RequestHeader("Authorization")String auth,@PathVariable UUID friendId){return community.messages(player(auth),friendId);}
    @PostMapping("/messages") CommunityDtos.MessageDto message(@RequestHeader("Authorization")String auth,@Valid @RequestBody CommunityDtos.MessageRequest request){return community.send(player(auth),request.recipientId(),request.body());}
    @PostMapping("/messages/delivered") void delivered(@RequestHeader("Authorization")String auth){community.markDelivered(player(auth));}
    @PostMapping(value="/messages/attachments",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    CommunityDtos.MessageDto attachment(@RequestHeader("Authorization")String auth,@RequestParam UUID recipientId,
                                         @RequestParam(required=false,defaultValue="") String body,
                                         @RequestPart("file") MultipartFile file){return community.sendAttachment(player(auth),recipientId,body,file);}
    @GetMapping("/messages/{messageId}/attachment")
    ResponseEntity<Resource> attachment(@RequestHeader("Authorization")String auth,@PathVariable UUID messageId){return community.attachment(player(auth),messageId);}
    private AuthenticatedPlayer player(String auth){return authentication.requireBearer(auth);}
}

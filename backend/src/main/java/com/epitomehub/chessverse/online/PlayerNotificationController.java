package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/notifications")
class PlayerNotificationController {
    private final PlayerAuthenticationService authentication;
    private final PlayerNotificationService notifications;
    private final PushDeviceService devices;
    PlayerNotificationController(PlayerAuthenticationService authentication, PlayerNotificationService notifications, PushDeviceService devices) {
        this.authentication = authentication; this.notifications = notifications; this.devices = devices;
    }
    @GetMapping PlayerNotificationDtos.InboxDto inbox(@RequestHeader("Authorization") String auth,
            @RequestParam(defaultValue = "50") int limit) { return notifications.inbox(player(auth), limit); }
    @PutMapping("/{id}/read") PlayerNotificationDtos.InboxDto read(@RequestHeader("Authorization") String auth,
            @PathVariable UUID id) { return notifications.read(player(auth), id); }
    @PutMapping("/read-all") PlayerNotificationDtos.InboxDto readAll(@RequestHeader("Authorization") String auth) {
        return notifications.readAll(player(auth));
    }
    @PostMapping("/devices") void register(@RequestHeader("Authorization") String auth,
            @RequestBody PlayerNotificationDtos.DeviceRequest request) {
        devices.register(player(auth), request.installationId(), request.token(), request.platform());
    }
    @DeleteMapping("/devices/{installationId}") void unregister(@RequestHeader("Authorization") String auth,
            @PathVariable String installationId) { devices.unregister(player(auth), installationId); }
    private AuthenticatedPlayer player(String auth) { return authentication.requireBearer(auth); }
}

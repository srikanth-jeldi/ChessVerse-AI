package com.epitomehub.chessverse.online;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class PlayerNotificationDtos {
    private PlayerNotificationDtos() {}
    record NotificationDto(UUID id, String type, String title, String body,
                           String actionType, UUID actionId, Instant createdAt, boolean read) {}
    record InboxDto(long unreadCount, List<NotificationDto> notifications) {}
    record DeviceRequest(String installationId, String token, String platform) {}
}

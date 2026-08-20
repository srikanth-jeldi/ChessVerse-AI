package com.epitomehub.chessverse.online;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class CommunityDtos {
    private CommunityDtos() {}
    record ClubDto(UUID id, String name, String description, int members,
                   int ratingRequirement, boolean joined) {}
    record TournamentDto(UUID id, String name, String description, int timeControlMinutes,
                         int players, int capacity, Instant startsAt, Instant endsAt,
                         String status, boolean joined) {}
    record ConversationDto(UUID playerId, String displayName, String photoUrl,
                           boolean online, String lastMessage, Instant sentAt, int unread) {}
    record MessageDto(UUID id, UUID senderId, UUID recipientId, String body,
                      Instant sentAt, boolean mine) {}
    record HubDto(List<ClubDto> clubs, List<TournamentDto> tournaments,
                  List<ConversationDto> conversations, int fairPlayScore) {}
    record MessageRequest(@NotNull UUID recipientId,
                          @NotBlank @Size(max = 500) String body) {}
}

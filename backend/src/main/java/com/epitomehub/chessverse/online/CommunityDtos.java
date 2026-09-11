package com.epitomehub.chessverse.online;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class CommunityDtos {
    private CommunityDtos() {}
    record ClubDto(UUID id, String name, String description, int members,
                   int ratingRequirement, boolean joined) {}
    record TournamentDto(UUID id, String name, String description, int timeControlMinutes,
                         int players, int capacity, Instant startsAt, Instant endsAt,
                         String status, boolean joined, int entryCoins, long prizePool,
                         int cadenceDays, int minimumPlayers, String badgeCode,
                         int championBonus, int runnerUpBonus, int participationBonus,
                         UUID clubId) {}
    record ConversationDto(UUID playerId, String displayName, String photoUrl,
                           boolean online, String lastMessage, Instant sentAt, int unread) {}
    record MessageDto(UUID id, UUID senderId, UUID recipientId, String body,
                      Instant sentAt, boolean mine, boolean delivered, boolean seen,
                      String attachmentName, String attachmentType, Long attachmentSize,
                      boolean deletedForEveryone, List<MessageReactionDto> reactions,
                      boolean encrypted) {}
    record MessageReactionDto(UUID playerId, String emoji, boolean mine) {}
    record HubDto(List<ClubDto> clubs, List<TournamentDto> tournaments,
                  List<ConversationDto> conversations, int fairPlayScore,
                  int circuitPoints) {}
    record MessageRequest(@NotNull UUID recipientId,
                          @NotBlank @Size(max = 4096) String body,
                          boolean encrypted) {}
    record E2eePublicKeyDto(UUID playerId, String publicKey, Instant updatedAt) {}
    record E2eeIdentityDto(UUID playerId, String publicKey, String encryptedPrivateKey,
                           String backupSalt, String backupNonce, int backupKdfIterations,
                           Instant updatedAt) {}
    record E2eeIdentityRequest(
            @NotBlank @Size(max = 128) String publicKey,
            @NotBlank @Size(max = 512) String encryptedPrivateKey,
            @NotBlank @Size(max = 128) String backupSalt,
            @NotBlank @Size(max = 128) String backupNonce,
            @Min(100000) @Max(2000000) int backupKdfIterations) {}
    record CreateClubTournamentRequest(
            @NotBlank @Size(max = 100) String name,
            @NotBlank @Size(max = 300) String description,
            @NotNull Instant startsAt,
            @Min(3) @Max(15) int timeControlMinutes,
            @Min(4) @Max(64) int capacity,
            @Min(100) @Max(500) int entryCoins) {}
}

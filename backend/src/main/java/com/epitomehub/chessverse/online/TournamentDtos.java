package com.epitomehub.chessverse.online;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class TournamentDtos {
    private TournamentDtos() {}
    record PlayerDto(UUID id, String displayName, String photoUrl) {}
    record PairingDto(UUID id, int board, PlayerDto white, PlayerDto black,
            UUID matchId, PlayerDto winner, String status) {}
    record RoundDto(int number, String status, List<PairingDto> pairings) {}
    record DetailDto(UUID id, String name, String description, int timeControlMinutes,
            int players, int capacity, Instant startsAt, Instant endsAt, String status,
            boolean joined, int entryCoins, long prizePool, int currentRound,
            int cadenceDays, int minimumPlayers, String badgeCode, int championBonus,
            int runnerUpBonus, int participationBonus, PlayerDto champion,
            PlayerDto runnerUp, List<RoundDto> rounds) {}
}

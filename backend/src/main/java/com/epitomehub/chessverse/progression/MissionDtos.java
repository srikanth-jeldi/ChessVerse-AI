package com.epitomehub.chessverse.progression;

import java.time.Instant;
import java.util.List;

final class MissionDtos {
    private MissionDtos() {}

    record MissionDto(String code, String cadence, String title, String description,
                      int progress, int target, int rewardCoins, boolean completed,
                      boolean claimed, Instant resetsAt) {}

    record MissionBoardDto(List<MissionDto> daily, List<MissionDto> weekly) {}

    record ClaimDto(String code, boolean claimed, int coinsGranted,
                    MissionBoardDto missions) {}
}

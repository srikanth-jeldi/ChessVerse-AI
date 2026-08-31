package com.epitomehub.chessverse.economy;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class EconomyDtos {
    private EconomyDtos() {}

    record WalletDto(long coins, long diamonds, Instant updatedAt) {}

    record TransactionDto(UUID id, String currency, long amount,
                          long balanceAfter, String type, String description,
                          Instant createdAt) {}

    record WalletHistoryDto(WalletDto wallet, List<TransactionDto> transactions) {}

    record RewardStatusDto(WalletDto wallet, boolean dailyAvailable,
                           Instant nextDailyAt, int rewardedAdsUsed,
                           int rewardedAdsRemaining, int dailyCoins,
                           int coinsPerAd) {}
}

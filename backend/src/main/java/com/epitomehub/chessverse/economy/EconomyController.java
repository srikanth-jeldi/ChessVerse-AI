package com.epitomehub.chessverse.economy;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;

@RestController
@RequestMapping("/api/v1/economy")
class EconomyController {
    private final PlayerAuthenticationService authentication;
    private final EconomyService economy;

    EconomyController(PlayerAuthenticationService authentication, EconomyService economy) {
        this.authentication = authentication;
        this.economy = economy;
    }

    @GetMapping("/wallet")
    EconomyDtos.WalletDto wallet(@RequestHeader("Authorization") String authorization) {
        return economy.wallet(player(authorization));
    }

    @GetMapping("/history")
    EconomyDtos.WalletHistoryDto history(@RequestHeader("Authorization") String authorization,
                                          @RequestParam(defaultValue = "30") int limit) {
        return economy.history(player(authorization), limit);
    }

    @GetMapping("/rewards")
    EconomyDtos.RewardStatusDto rewards(@RequestHeader("Authorization") String authorization) {
        return economy.rewardStatus(player(authorization));
    }

    @PostMapping("/daily-reward")
    EconomyDtos.RewardStatusDto claimDaily(@RequestHeader("Authorization") String authorization) {
        return economy.claimDaily(player(authorization));
    }

    private AuthenticatedPlayer player(String authorization) {
        return authentication.requireBearer(authorization);
    }
}

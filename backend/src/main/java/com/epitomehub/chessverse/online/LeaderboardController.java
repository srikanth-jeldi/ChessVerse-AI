package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/leaderboard")
public class LeaderboardController {
    private final PlayerAuthenticationService authentication;
    private final OnlineRatingService ratings;

    public LeaderboardController(
            PlayerAuthenticationService authentication, OnlineRatingService ratings) {
        this.authentication = authentication;
        this.ratings = ratings;
    }

    @GetMapping
    LeaderboardDtos.LeaderboardDto leaderboard(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(defaultValue = "global") String scope,
            @RequestParam(required = false) String country,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ratings.leaderboard(player(authorization), scope, country, page, size);
    }

    @GetMapping("/me")
    LeaderboardDtos.PlayerRatingDto me(
            @RequestHeader("Authorization") String authorization) {
        return ratings.profile(player(authorization));
    }

    @PutMapping("/me/country")
    LeaderboardDtos.PlayerRatingDto country(
            @RequestHeader("Authorization") String authorization,
            @Valid @RequestBody LeaderboardDtos.CountryRequest request) {
        return ratings.updateCountry(player(authorization), request.country());
    }

    private AuthenticatedPlayer player(String authorization) {
        return authentication.requireBearer(authorization);
    }
}

package com.epitomehub.chessverse.online;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import org.springframework.web.bind.annotation.*;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@RestController
@RequestMapping("/api/v1/leaderboard/coins")
class CoinLeagueController {
 private final PlayerAuthenticationService auth; private final CoinLeagueService league;
 CoinLeagueController(PlayerAuthenticationService auth,CoinLeagueService league){this.auth=auth;this.league=league;}
 @GetMapping CoinLeagueService.Board board(@RequestHeader("Authorization") String authorization,
     @RequestParam(defaultValue="weekly") String period){return league.board(auth.requireBearer(authorization).id(),period);}
}
@Component
@org.springframework.context.annotation.Profile("!test")
@org.springframework.boot.autoconfigure.condition.ConditionalOnExpression("'${chessverse.service.role:all}' == 'all' || '${chessverse.service.role:all}' == 'play'")
class CoinLeagueScheduler {
 private final CoinLeagueService league;
 CoinLeagueScheduler(CoinLeagueService league){this.league=league;}
 @Scheduled(fixedDelayString="${chessverse.coin-league.delay-ms:3600000}",initialDelay=60000)
 public void settle(){league.settleCompletedWeeks();}
}

package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.UUID;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/community/practice-cups")
class DailyPracticeCupController {
    private final PlayerAuthenticationService auth;
    private final DailyPracticeCup cups;

    DailyPracticeCupController(PlayerAuthenticationService auth, DailyPracticeCup cups) {
        this.auth = auth;
        this.cups = cups;
    }

    @PostMapping("/today")
    DailyPracticeCup.Cup join(@RequestHeader("Authorization") String token) {
        return cups.join(auth.requireBearer(token));
    }

    record Turn(String move, Integer ply) {}

    @GetMapping("/winners")
    java.util.List<DailyPracticeCup.Winner> winners(@RequestHeader("Authorization") String token) {
        auth.requireBearer(token);
        return cups.recentWinners();
    }

    @GetMapping("/{cup}")
    DailyPracticeCup.Cup standings(@RequestHeader("Authorization") String token, @PathVariable UUID cup) {
        return cups.standings(cup, auth.requireBearer(token).id());
    }

    @PostMapping("/{cup}/boards/{board}")
    DailyPracticeCup.Position board(@RequestHeader("Authorization") String token, @PathVariable UUID cup,
                                    @PathVariable int board, @RequestBody Turn turn) {
        return cups.enter(cup, board, auth.requireBearer(token).id(), turn.move(), turn.ply());
    }
}

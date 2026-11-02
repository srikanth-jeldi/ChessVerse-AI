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
        return forPlayer(cups.join(auth.requireBearer(token)));
    }

    // Standings use all results. Only the two participants receive the moves.
    private static DailyPracticeCup.Cup forPlayer(DailyPracticeCup.Cup cup) {
        var visible = cup.games().stream().map(game ->
                game.white() == cup.mySeat() || game.black() == cup.mySeat() ? game :
                new DailyPracticeCup.Game(game.number(), game.round(), game.white(), game.black(),
                        "", game.started(), game.result())).toList();
        return new DailyPracticeCup.Cup(cup.id(), cup.mySeat(), cup.seats(), visible, cup.lobbySeconds());
    }

    record Turn(String move, Integer ply) {}

    @GetMapping("/winners")
    java.util.List<DailyPracticeCup.Winner> winners(@RequestHeader("Authorization") String token) {
        auth.requireBearer(token);
        return cups.recentWinners();
    }

    @GetMapping("/{cup}")
    DailyPracticeCup.Cup standings(@RequestHeader("Authorization") String token, @PathVariable UUID cup) {
        return forPlayer(cups.standings(cup, auth.requireBearer(token).id()));
    }

    @PostMapping("/{cup}/boards/{board}")
    DailyPracticeCup.Position board(@RequestHeader("Authorization") String token, @PathVariable UUID cup,
                                    @PathVariable int board, @RequestBody Turn turn) {
        var position = cups.enter(cup, board, auth.requireBearer(token).id(), turn.move(), turn.ply());
        return new DailyPracticeCup.Position(forPlayer(position.cup()), position.board(),
                position.fen(), position.ply(), position.legal());
    }
}

package com.epitomehub.chessverse.online;

import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@Profile("!test")
class TournamentScheduler {
    private final TournamentService tournaments;
    TournamentScheduler(TournamentService tournaments) { this.tournaments = tournaments; }

    @Scheduled(fixedDelayString = "${chessverse.tournaments.scheduler-delay-ms:30000}")
    void startDue() { tournaments.startDueTournaments(); }
}

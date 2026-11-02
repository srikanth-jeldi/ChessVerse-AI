package com.epitomehub.chessverse.online;

import org.springframework.context.annotation.Profile;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@Profile("!test")
@ConditionalOnExpression("'${chessverse.service.role:all}' == 'all' || '${chessverse.service.role:all}' == 'play'")
class TournamentScheduler {
    private final TournamentService tournaments;
    private final DailyPracticeCup practiceCups;
    TournamentScheduler(TournamentService tournaments, DailyPracticeCup practiceCups) {
        this.tournaments = tournaments;
        this.practiceCups = practiceCups;
    }

    @Scheduled(fixedDelayString = "${chessverse.tournaments.scheduler-delay-ms:30000}")
    void startDue() {
        tournaments.startDueTournaments();
        tournaments.sendDueReminders();
        tournaments.scheduleNextOccurrences();
        practiceCups.finishReadyCups();
    }
}

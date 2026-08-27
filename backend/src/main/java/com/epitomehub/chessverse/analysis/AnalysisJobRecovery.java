package com.epitomehub.chessverse.analysis;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.scheduling.annotation.Scheduled;

@Component
class AnalysisJobRecovery {
    private final GameAnalysisService analysis;

    AnalysisJobRecovery(GameAnalysisService analysis) {
        this.analysis = analysis;
    }

    @EventListener(ApplicationReadyEvent.class)
    void recover() {
        analysis.recoverInterruptedJobs();
    }

    @Scheduled(fixedDelay = 60_000)
    void recoverPeriodically() {
        analysis.recoverInterruptedJobs();
    }
}

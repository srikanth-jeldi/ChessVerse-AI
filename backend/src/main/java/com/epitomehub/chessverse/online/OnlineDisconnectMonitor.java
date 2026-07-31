package com.epitomehub.chessverse.online;

import java.util.UUID;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
class OnlineDisconnectMonitor {
    private final OnlineMatchService matches;
    private final OnlineMatchSocketHandler socket;

    OnlineDisconnectMonitor(OnlineMatchService matches, OnlineMatchSocketHandler socket) {
        this.matches = matches;
        this.socket = socket;
    }

    @Scheduled(fixedDelay = 1000)
    void finishExpiredDisconnects() {
        for (UUID matchId : matches.finishExpiredDisconnects()) {
            socket.publish(matchId);
        }
    }
}

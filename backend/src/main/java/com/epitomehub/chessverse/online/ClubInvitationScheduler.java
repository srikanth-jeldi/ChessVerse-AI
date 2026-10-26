package com.epitomehub.chessverse.online;

import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import jakarta.annotation.PreDestroy;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
@Profile("!test")
@ConditionalOnExpression("'${chessverse.service.role:all}' == 'all' || '${chessverse.service.role:all}' == 'play'")
class ClubInvitationScheduler {
    private final ClubEmailInvitationService invitations;
    private final AtomicBoolean running = new AtomicBoolean();
    private final ExecutorService worker = Executors.newSingleThreadExecutor(
            Thread.ofPlatform().daemon().name("club-invitation-mail").factory());
    ClubInvitationScheduler(ClubEmailInvitationService invitations) { this.invitations = invitations; }
    @Scheduled(fixedDelayString="${chessverse.clubs.invitation-mail-delay-ms:30000}")
    void deliver() {
        if (!running.compareAndSet(false, true)) return;
        worker.execute(() -> {
            try { invitations.deliverPending(); }
            catch (RuntimeException failure) {
                org.slf4j.LoggerFactory.getLogger(ClubInvitationScheduler.class)
                        .warn("Club mail outbox temporarily unavailable: {}", failure.getClass().getSimpleName());
            } finally { running.set(false); }
        });
    }
    @PreDestroy void close() { worker.shutdownNow(); }
}

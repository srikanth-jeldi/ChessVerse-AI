package com.epitomehub.chessverse.auth;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
class AuthSecurityMetrics {
    private final Counter failedLogins;
    private final Counter lockedLogins;
    private final Counter accountLockouts;

    AuthSecurityMetrics(MeterRegistry registry) {
        failedLogins = Counter.builder("chessverse.auth.login.failures")
                .description("Rejected password-login attempts")
                .register(registry);
        lockedLogins = Counter.builder("chessverse.auth.login.locked")
                .description("Login attempts rejected because the account is locked")
                .register(registry);
        accountLockouts = Counter.builder("chessverse.auth.account.lockouts")
                .description("Accounts temporarily locked after repeated password failures")
                .register(registry);
    }

    void failedLogin() {
        failedLogins.increment();
    }

    void lockedLogin() {
        lockedLogins.increment();
    }

    void accountLocked() {
        accountLockouts.increment();
    }
}

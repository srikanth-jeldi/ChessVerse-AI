package com.epitomehub.chessverse.engine;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import java.util.concurrent.TimeUnit;
import org.springframework.stereotype.Component;

@Component
public class AiCoachMetrics {
    private final Counter requests;
    private final Counter quotaRejected;
    private final Counter cacheHits;
    private final Counter engineReviewCacheHits;
    private final Counter structuredFallbacks;
    private final Counter languageSuccesses;
    private final Counter languageFailures;
    private final Counter outcomesResolved;
    private final Timer languageLatency;

    public AiCoachMetrics(MeterRegistry registry) {
        requests = registry.counter("chessverse.ai.coach.requests");
        quotaRejected = registry.counter("chessverse.ai.coach.quota.rejected");
        cacheHits = registry.counter("chessverse.ai.coach.cache.hits");
        engineReviewCacheHits = registry.counter("chessverse.ai.coach.engine.review.cache.hits");
        structuredFallbacks = registry.counter("chessverse.ai.coach.structured.fallbacks");
        languageSuccesses = registry.counter("chessverse.ai.coach.language.successes");
        languageFailures = registry.counter("chessverse.ai.coach.language.failures");
        outcomesResolved = registry.counter("chessverse.ai.coach.outcomes.resolved");
        languageLatency = registry.timer("chessverse.ai.coach.language.latency");
    }

    void request() { requests.increment(); }
    void quotaRejected() { quotaRejected.increment(); }
    void cacheHit() { cacheHits.increment(); }
    void engineReviewCacheHit() { engineReviewCacheHits.increment(); }
    void structuredFallback() { structuredFallbacks.increment(); }
    void languageSuccess(long nanos) {
        languageSuccesses.increment();
        languageLatency.record(nanos, TimeUnit.NANOSECONDS);
    }
    void languageFailure(long nanos) {
        languageFailures.increment();
        languageLatency.record(nanos, TimeUnit.NANOSECONDS);
    }
    public void outcomesResolved(int count) { outcomesResolved.increment(Math.max(0, count)); }
}

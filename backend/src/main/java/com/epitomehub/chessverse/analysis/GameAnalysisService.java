package com.epitomehub.chessverse.analysis;

import static com.epitomehub.chessverse.analysis.GameAnalysisDtos.*;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.core.task.TaskRejectedException;
import org.springframework.dao.DataIntegrityViolationException;

@Service
class GameAnalysisService {
    private final GameAnalysisJobRepository jobs;
    private final GameAnalysisWorker worker;
    private final GameAnalysisPlyRepository plies;
    private final PlayerWeaknessEventRepository weaknessEvents;

    GameAnalysisService(GameAnalysisJobRepository jobs, GameAnalysisWorker worker,
            GameAnalysisPlyRepository plies, PlayerWeaknessEventRepository weaknessEvents) {
        this.jobs = jobs;
        this.worker = worker;
        this.plies = plies;
        this.weaknessEvents = weaknessEvents;
    }

    JobResponse create(UUID playerId, CreateRequest request) {
        GameAnalysisJob existing = jobs.findByPlayerIdAndClientRequestId(
                playerId, request.clientRequestId()).orElse(null);
        if (existing != null) return response(existing);
        GameAnalysisJob job;
        try {
            job = jobs.saveAndFlush(new GameAnalysisJob(
                    playerId,
                    request.clientRequestId(),
                    request.initialFen().trim(),
                    String.join(",", request.moves()).toLowerCase(),
                    request.depth(),
                    request.moves().size(),
                    request.playerColor() == null ? null : request.playerColor().toUpperCase(),
                    request.timeControl()));
        } catch (DataIntegrityViolationException duplicate) {
            job = jobs.findByPlayerIdAndClientRequestId(playerId, request.clientRequestId())
                    .orElseThrow(() -> duplicate);
            return response(job);
        }
        dispatch(job);
        return response(job);
    }

    @Transactional(readOnly = true)
    JobResponse get(UUID playerId, UUID id) {
        return response(requireOwned(playerId, id));
    }

    @Transactional(readOnly = true)
    JobDetailResponse details(UUID playerId, UUID id) {
        GameAnalysisJob job = requireOwned(playerId, id);
        return new JobDetailResponse(response(job),
                plies.findByJobIdOrderByPly(id).stream()
                        .map(GameAnalysisService::plyResponse).toList());
    }

    @Transactional(readOnly = true)
    List<JobResponse> list(UUID playerId, int limit) {
        return jobs.findByPlayerIdOrderByCreatedAtDesc(playerId, PageRequest.of(0, limit))
                .stream().map(GameAnalysisService::response).toList();
    }

    @Transactional(readOnly = true)
    WeaknessHistoryResponse weaknessHistory(UUID playerId, int limit) {
        List<PlayerWeaknessEvent> events = weaknessEvents
                .findByPlayerIdOrderByOccurredAtDesc(playerId, PageRequest.of(0, limit));
        java.util.Map<String, Integer> counts = new java.util.TreeMap<>();
        for (PlayerWeaknessEvent event : events) {
            counts.merge(event.category, 1, Integer::sum);
        }
        return new WeaknessHistoryResponse(events.size(), counts,
                events.stream().map(event -> new WeaknessEventResponse(
                        event.ply, event.category, event.severity, event.classification,
                        event.centipawnLoss, event.playedMove, event.bestMove,
                        event.playerColor, event.timeControl, event.openingEco,
                        event.occurredAt)).toList());
    }

    JobResponse retry(UUID playerId, UUID id) {
        GameAnalysisJob job = requireOwned(playerId, id);
        if (job.status != AnalysisJobStatus.FAILED) {
            throw new AnalysisJobException(HttpStatus.CONFLICT, "Only failed analysis jobs can be retried.");
        }
        if (job.attemptCount >= 3) {
            throw new AnalysisJobException(HttpStatus.CONFLICT, "This analysis reached the retry limit.");
        }
        job.queueForRetry();
        jobs.save(job);
        dispatch(job);
        return response(job);
    }

    void recoverInterruptedJobs() {
        Instant stale = Instant.now().minus(Duration.ofMinutes(10));
        for (GameAnalysisJob job : jobs.findByStatusInAndUpdatedAtBefore(
                List.of(AnalysisJobStatus.QUEUED, AnalysisJobStatus.ANALYZING), stale)) {
            if (job.attemptCount >= 3) {
                job.fail("RETRY_LIMIT", "Analysis could not be recovered after three attempts.");
            } else {
                job.queueForRetry();
                jobs.save(job);
                dispatch(job);
            }
        }
    }

    private GameAnalysisJob requireOwned(UUID playerId, UUID id) {
        return jobs.findByIdAndPlayerId(id, playerId)
                .orElseThrow(() -> new AnalysisJobException(HttpStatus.NOT_FOUND, "Analysis job was not found."));
    }

    private void dispatch(GameAnalysisJob job) {
        try {
            worker.process(job.id);
        } catch (TaskRejectedException exception) {
            job.fail("QUEUE_CAPACITY", "The analysis queue is full. Retry shortly.");
            jobs.save(job);
        }
    }

    private static JobResponse response(GameAnalysisJob job) {
        return new JobResponse(job.id, job.status, job.requestedDepth, job.totalPlies,
                job.analyzedPlies, job.attemptCount, job.errorCode, job.errorMessage,
                job.openingEco, job.openingName, job.bookPlies, job.firstDeviationPly,
                job.createdAt, job.startedAt, job.completedAt, job.updatedAt);
    }

    private static PlyResponse plyResponse(GameAnalysisPly ply) {
        return new PlyResponse(ply.ply, ply.fenBefore, ply.playedMove,
                ply.bestMove, ply.classification, ply.centipawnLoss,
                ply.coachingTheme,
                ply.evaluationBeforeCp, ply.evaluationAfterCp,
                ply.mateBefore, ply.mateAfter, ply.variation(), ply.depth);
    }
}

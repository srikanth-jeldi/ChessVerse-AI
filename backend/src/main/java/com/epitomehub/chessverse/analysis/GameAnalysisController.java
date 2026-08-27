package com.epitomehub.chessverse.analysis;

import static com.epitomehub.chessverse.analysis.GameAnalysisDtos.*;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/analysis/jobs")
class GameAnalysisController {
    private final PlayerAuthenticationService authentication;
    private final GameAnalysisService analysis;

    GameAnalysisController(PlayerAuthenticationService authentication, GameAnalysisService analysis) {
        this.authentication = authentication;
        this.analysis = analysis;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    JobResponse create(@RequestHeader("Authorization") String authorization,
            @Valid @RequestBody CreateRequest request) {
        return analysis.create(authentication.requireBearer(authorization).id(), request);
    }

    @GetMapping("/{id}")
    JobResponse get(@RequestHeader("Authorization") String authorization, @PathVariable UUID id) {
        return analysis.get(authentication.requireBearer(authorization).id(), id);
    }

    @GetMapping("/{id}/results")
    JobDetailResponse results(@RequestHeader("Authorization") String authorization, @PathVariable UUID id) {
        return analysis.details(authentication.requireBearer(authorization).id(), id);
    }

    @GetMapping
    List<JobResponse> list(@RequestHeader("Authorization") String authorization,
            @RequestParam(defaultValue = "20") @Min(1) @Max(50) int limit) {
        return analysis.list(authentication.requireBearer(authorization).id(), limit);
    }

    @GetMapping("/weakness-history")
    WeaknessHistoryResponse weaknessHistory(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(defaultValue = "100") @Min(1) @Max(500) int limit) {
        return analysis.weaknessHistory(authentication.requireBearer(authorization).id(), limit);
    }

    @PostMapping("/{id}/retry")
    @ResponseStatus(HttpStatus.ACCEPTED)
    JobResponse retry(@RequestHeader("Authorization") String authorization, @PathVariable UUID id) {
        return analysis.retry(authentication.requireBearer(authorization).id(), id);
    }
}

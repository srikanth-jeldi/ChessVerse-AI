package com.epitomehub.chessverse.engine;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/coach")
class AiCoachController {
    private final PlayerAuthenticationService authentication;
    private final AiCoachService coach;

    AiCoachController(PlayerAuthenticationService authentication, AiCoachService coach) {
        this.authentication = authentication;
        this.coach = coach;
    }

    @PostMapping("/ask")
    CoachResponse ask(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody CoachRequest request) {
        AuthenticatedPlayer player = authentication.requireBearer(authorization);
        return coach.ask(player.id(), request);
    }

    @PatchMapping("/interactions/{id}/feedback")
    void feedback(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @PathVariable UUID id,
            @Valid @RequestBody CoachFeedback feedback) {
        coach.feedback(authentication.requireBearer(authorization).id(), id, feedback.helpful());
    }

    @GetMapping("/impact")
    CoachImpact impact(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        return coach.impact(authentication.requireBearer(authorization).id());
    }

    record CoachRequest(
            @NotBlank @Size(max = 120) String fen,
            @NotBlank @Pattern(regexp = "^[a-h][1-8][a-h][1-8][qrbn]?$", flags = Pattern.Flag.CASE_INSENSITIVE)
            String playedMove,
            @NotBlank @Size(max = 500) String question,
            @Pattern(regexp = "^$|^[a-h][1-8][a-h][1-8][qrbn]?$", flags = Pattern.Flag.CASE_INSENSITIVE)
            String candidateMove) {}

    record CoachResponse(
            UUID interactionId,
            String answer,
            String classification,
            String bestMove,
            String candidateMove,
            int centipawnLoss,
            String opponentThreat,
            List<String> principalVariation,
            boolean cacheHit,
            int remainingToday) {}

    record CoachFeedback(boolean helpful) {}

    record CoachImpact(
            int analyzedGames,
            int measuredMoves,
            int recentAverageCentipawnLoss,
            int previousAverageCentipawnLoss,
            int improvementPercent,
            int feedbackCount,
            int helpfulPercent,
            boolean enoughEvidence,
            String evidenceMessage) {}
}

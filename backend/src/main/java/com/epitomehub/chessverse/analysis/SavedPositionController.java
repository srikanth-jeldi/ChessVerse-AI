package com.epitomehub.chessverse.analysis;

import static com.epitomehub.chessverse.analysis.SavedPositionDtos.*;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
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
@RequestMapping("/api/v1/positions")
class SavedPositionController {
    private final PlayerAuthenticationService authentication;
    private final SavedPositionService positions;

    SavedPositionController(PlayerAuthenticationService authentication, SavedPositionService positions) {
        this.authentication = authentication;
        this.positions = positions;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    SavedPositionResponse save(@RequestHeader("Authorization") String authorization,
            @Valid @RequestBody SavePositionRequest request) {
        return positions.save(authentication.requireBearer(authorization).id(), request);
    }

    @GetMapping
    List<SavedPositionResponse> list(@RequestHeader("Authorization") String authorization,
            @RequestParam(defaultValue = "100") @Min(1) @Max(500) int limit) {
        return positions.list(authentication.requireBearer(authorization).id(), limit);
    }

    @GetMapping(value = "/export", produces = MediaType.TEXT_PLAIN_VALUE)
    String export(@RequestHeader("Authorization") String authorization) {
        return positions.exportFen(authentication.requireBearer(authorization).id());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void delete(@RequestHeader("Authorization") String authorization, @PathVariable UUID id) {
        positions.delete(authentication.requireBearer(authorization).id(), id);
    }
}

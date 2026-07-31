package com.epitomehub.chessverse.progress;

import static com.epitomehub.chessverse.progress.CloudProgressDtos.*;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/progress")
class CloudProgressController {
    private final PlayerAuthenticationService authentication;
    private final CloudProgressService progress;

    CloudProgressController(PlayerAuthenticationService authentication, CloudProgressService progress) {
        this.authentication = authentication;
        this.progress = progress;
    }

    @GetMapping
    ProgressResponse get(@RequestHeader("Authorization") String authorization) {
        return progress.get(authentication.requireBearer(authorization).id());
    }

    @PutMapping
    ProgressResponse merge(
            @RequestHeader("Authorization") String authorization,
            @Valid @RequestBody MergeRequest request) {
        return progress.merge(authentication.requireBearer(authorization).id(), request);
    }
}

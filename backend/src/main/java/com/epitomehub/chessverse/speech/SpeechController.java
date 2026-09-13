package com.epitomehub.chessverse.speech;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/speech")
class SpeechController {
    private final PlayerAuthenticationService authentication;
    private final SpeechSynthesisService speech;

    SpeechController(PlayerAuthenticationService authentication, SpeechSynthesisService speech) {
        this.authentication = authentication;
        this.speech = speech;
    }

    @PostMapping(value = "/synthesize", produces = "audio/mpeg")
    ResponseEntity<byte[]> synthesize(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody SpeechRequest request) {
        authentication.requireBearer(authorization);
        SpeechSynthesisService.SpeechAudio audio = speech.synthesize(request.text(), request.language());
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("audio/mpeg"))
                .cacheControl(CacheControl.noStore())
                .header(HttpHeaders.VARY, HttpHeaders.AUTHORIZATION)
                .header(HttpHeaders.ETAG, '"' + audio.etag() + '"')
                .header("X-Speech-Locale", audio.locale())
                .header("X-Speech-Voice", audio.voice())
                .header("X-Speech-Cache", audio.cacheHit() ? "HIT" : "MISS")
                .body(audio.bytes());
    }

    record SpeechRequest(
            @NotBlank @Size(max = SpeechSynthesisService.MAX_TEXT_LENGTH) String text,
            @NotBlank @Pattern(regexp = "^[A-Za-z]{2,3}([_-][A-Za-z]{2,4})?$") String language) {}
}

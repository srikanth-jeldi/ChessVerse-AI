package com.epitomehub.chessverse.auth;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Exposes browser-safe OAuth identifiers only; provider secrets remain server-side. */
@RestController
@RequestMapping("/api/auth")
class PublicOAuthConfigController {
    private final String googleClientId;
    private final String facebookAppId;

    PublicOAuthConfigController(
            @Value("${chessverse.oauth.google-web-client-id:}") String googleClientId,
            @Value("${chessverse.oauth.facebook-app-id:}") String facebookAppId) {
        this.googleClientId = googleClientId.trim();
        this.facebookAppId = facebookAppId.trim();
    }

    @GetMapping("/oauth-config")
    Map<String,Object> config() {
        Map<String,Object> result = new LinkedHashMap<>();
        result.put("googleEnabled", usable(googleClientId));
        result.put("googleClientId", usable(googleClientId) ? googleClientId : "");
        result.put("facebookEnabled", usable(facebookAppId));
        result.put("facebookAppId", usable(facebookAppId) ? facebookAppId : "");
        return result;
    }

    private boolean usable(String value) {
        return !value.isBlank() && !value.startsWith("replace-");
    }
}

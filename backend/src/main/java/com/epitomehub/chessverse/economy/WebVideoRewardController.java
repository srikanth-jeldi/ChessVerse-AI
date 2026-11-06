package com.epitomehub.chessverse.economy;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
class WebVideoRewardController {
    private final EconomyService economy;
    private final String key;
    private final String slot;

    WebVideoRewardController(EconomyService economy, @Value("${AYET_PUBLISHER_KEY:}") String key,
                             @Value("${AYET_REWARDED_SLOT_ID:}") String slot) {
        this.economy = economy;
        this.key = key;
        this.slot = slot;
    }

    @GetMapping("/api/v1/economy/web-video/callback")
    void reward(@RequestParam("adslot_id") String adSlot,
                @RequestParam("external_identifier") UUID player,
                @RequestParam("transaction_id") String transaction,
                @RequestHeader("X-Ayetstudios-Security-Hash") String signature) throws GeneralSecurityException {
        if (key.isBlank() || slot.isBlank()) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE);
        if (!slot.equals(adSlot) || !adSlot.matches("[0-9]+") || !transaction.matches("[A-Za-z0-9_-]{1,100}")
                || !signature.matches("[A-Fa-f0-9]{64}")) throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        // This placement's callback URL has exactly these three URL-safe macros, in sorted key order.
        String message = "adslot_id=" + adSlot + "&external_identifier=" + player + "&transaction_id=" + transaction;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        if (!MessageDigest.isEqual(mac.doFinal(message.getBytes(StandardCharsets.UTF_8)), HexFormat.of().parseHex(signature))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        economy.grantVerifiedVideo(player, "ayet:" + transaction);
    }
}

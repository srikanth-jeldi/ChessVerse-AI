package com.epitomehub.chessverse.economy;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/purchases/webhooks")
class PurchaseWebhookController {
    private final PurchaseWebhookService webhooks;
    PurchaseWebhookController(PurchaseWebhookService webhooks) { this.webhooks = webhooks; }

    @PostMapping("/razorpay")
    ResponseEntity<Void> razorpay(
            @RequestHeader(name = "X-Razorpay-Event-Id", required = false) String eventId,
            @RequestHeader("X-Razorpay-Signature") String signature,
            @RequestBody String rawBody) {
        webhooks.razorpay(eventId, signature, rawBody);
        return ResponseEntity.noContent().build();
    }
}

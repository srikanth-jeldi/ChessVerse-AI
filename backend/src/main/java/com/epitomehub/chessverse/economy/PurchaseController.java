package com.epitomehub.chessverse.economy;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PathVariable;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/purchases")
class PurchaseController {
    private final PlayerAuthenticationService authentication;
    private final PurchaseService purchases;

    PurchaseController(PlayerAuthenticationService authentication, PurchaseService purchases) {
        this.authentication = authentication;
        this.purchases = purchases;
    }

    @GetMapping
    PurchaseDtos.PurchaseCenterDto center(@RequestHeader("Authorization") String authorization) {
        return purchases.center(player(authorization));
    }

    @PostMapping("/orders")
    PurchaseDtos.OrderDto create(@RequestHeader("Authorization") String authorization,
                                  @Valid @RequestBody PurchaseDtos.CreateOrderRequest request) {
        return purchases.create(player(authorization), request);
    }

    @PostMapping("/orders/{id}/google-play/verify")
    PurchaseDtos.OrderDto verifyGooglePlay(@RequestHeader("Authorization") String authorization,
                                           @PathVariable UUID id,
                                           @Valid @RequestBody PurchaseDtos.GooglePlayVerifyRequest request) {
        return purchases.verifyGooglePlay(player(authorization), id, request.purchaseToken());
    }

    @PostMapping("/orders/{id}/razorpay/checkout")
    PurchaseDtos.RazorpayCheckoutDto razorpayCheckout(@RequestHeader("Authorization") String authorization,
                                                       @PathVariable UUID id) {
        return purchases.razorpayCheckout(player(authorization), id);
    }

    @PostMapping("/orders/{id}/razorpay/verify")
    PurchaseDtos.OrderDto verifyRazorpay(@RequestHeader("Authorization") String authorization,
                                         @PathVariable UUID id,
                                         @Valid @RequestBody PurchaseDtos.RazorpayVerifyRequest request) {
        return purchases.verifyRazorpay(player(authorization), id, request);
    }

    private AuthenticatedPlayer player(String authorization) {
        return authentication.requireBearer(authorization);
    }
}

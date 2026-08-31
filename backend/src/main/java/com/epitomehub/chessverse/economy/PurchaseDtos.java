package com.epitomehub.chessverse.economy;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

final class PurchaseDtos {
    private PurchaseDtos() {}

    record ProductDto(UUID id, String sku, String name, String description,
                      String grantCurrency, long grantAmount, long priceMinor,
                      String priceCurrency) {}

    record CreateOrderRequest(
            @NotNull UUID productId,
            @NotNull UUID idempotencyKey,
            @NotBlank @Pattern(regexp = "GOOGLE_PLAY|APPLE_STOREKIT|RAZORPAY") String provider) {}

    record GooglePlayVerifyRequest(@NotBlank String purchaseToken) {}

    record RazorpayCheckoutDto(UUID orderId, String providerOrderId, String publicKeyId,
                               long amountMinor, String currency, String name,
                               String description) {}

    record RazorpayVerifyRequest(@NotBlank String razorpayOrderId,
                                 @NotBlank String razorpayPaymentId,
                                 @NotBlank String razorpaySignature) {}

    record OrderDto(UUID id, UUID productId, String sku, String productName,
                    String provider, String status, long priceMinor,
                    String priceCurrency, String grantCurrency, long grantAmount,
                    Instant createdAt, Instant updatedAt) {}

    record PurchaseCenterDto(List<ProductDto> products, List<OrderDto> orders,
                             boolean googlePlayAvailable, boolean appleStoreKitAvailable,
                             boolean webCheckoutAvailable,
                             String securityNotice) {}
}

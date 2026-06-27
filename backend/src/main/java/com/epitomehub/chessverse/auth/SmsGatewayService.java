package com.epitomehub.chessverse.auth;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
@ConditionalOnProperty(
        prefix = "chessverse.auth.sms",
        name = "mode",
        havingValue = "gateway",
        matchIfMissing = true)
class SmsGatewayService implements SmsOtpDelivery {
    private final RestClient restClient;
    private final String gatewayUrl;
    private final String gatewayToken;
    private final String sender;

    SmsGatewayService(
            RestClient.Builder restClientBuilder,
            @Value("${chessverse.auth.sms.gateway-url:}") String gatewayUrl,
            @Value("${chessverse.auth.sms.gateway-token:}") String gatewayToken,
            @Value("${chessverse.auth.sms.sender:ChessVerse}") String sender) {
        this.restClient = restClientBuilder.build();
        this.gatewayUrl = gatewayUrl;
        this.gatewayToken = gatewayToken;
        this.sender = sender;
    }

    @Override
    public void sendVerificationCode(String phone, String displayName, String code) {
        if (gatewayUrl.isBlank() || gatewayToken.isBlank()) {
            throw new AuthException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Phone verification is not configured on this server.");
        }

        try {
            restClient.post()
                    .uri(gatewayUrl)
                    .headers(headers -> headers.setBearerAuth(gatewayToken))
                    .body(Map.of(
                            "to", phone,
                            "from", sender,
                            "message", "Your ChessVerse verification code is " + code
                                    + ". It expires in 10 minutes."))
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientException exception) {
            throw new AuthException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Phone verification delivery failed. Try again shortly.");
        }
    }
}

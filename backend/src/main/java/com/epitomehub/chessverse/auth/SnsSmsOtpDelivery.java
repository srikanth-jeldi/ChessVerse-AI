package com.epitomehub.chessverse.auth;

import jakarta.annotation.PreDestroy;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.MessageAttributeValue;
import software.amazon.awssdk.services.sns.model.PublishRequest;
import software.amazon.awssdk.services.sns.model.PublishResponse;
import software.amazon.awssdk.services.sns.model.SnsException;

@Service
@ConditionalOnProperty(
        prefix = "chessverse.auth.sms",
        name = "mode",
        havingValue = "sns")
class SnsSmsOtpDelivery implements SmsOtpDelivery {
    private static final Logger log = LoggerFactory.getLogger(SnsSmsOtpDelivery.class);
    private static final String STRING_TYPE = "String";

    private final SnsClient snsClient;
    private final String senderId;
    private final String maxPrice;
    private final String entityId;
    private final String templateId;

    SnsSmsOtpDelivery(
            @Value("${chessverse.auth.sms.aws-region:ap-south-1}") String awsRegion,
            @Value("${chessverse.auth.sms.sender-id:}") String senderId,
            @Value("${chessverse.auth.sms.max-price:}") String maxPrice,
            @Value("${chessverse.auth.sms.india-entity-id:}") String entityId,
            @Value("${chessverse.auth.sms.india-template-id:}") String templateId) {
        this.snsClient = SnsClient.builder().region(Region.of(awsRegion)).build();
        this.senderId = senderId;
        this.maxPrice = maxPrice;
        this.entityId = entityId;
        this.templateId = templateId;
    }

    @Override
    public void sendVerificationCode(String phone, String displayName, String code) {
        String message = "Your ChessVerse verification code is " + code
                + ". It expires in 10 minutes.";
        try {
            PublishResponse response = snsClient.publish(createPublishRequest(
                    phone,
                    message,
                    senderId,
                    maxPrice,
                    entityId,
                    templateId));
            log.info(
                    "SNS accepted verification SMS for phone ending {} with message id {}",
                    phone.substring(Math.max(0, phone.length() - 4)),
                    response.messageId());
        } catch (SnsException | SdkClientException exception) {
            log.error("SNS verification SMS delivery failed: {}", exception.getMessage());
            throw new AuthException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Phone verification delivery failed. Try again shortly.");
        }
    }

    static PublishRequest createPublishRequest(
            String phone,
            String message,
            String senderId,
            String maxPrice,
            String entityId,
            String templateId) {
        Map<String, MessageAttributeValue> attributes = new LinkedHashMap<>();
        attributes.put("AWS.SNS.SMS.SMSType", stringAttribute("Transactional"));
        putIfPresent(attributes, "AWS.SNS.SMS.SenderID", senderId);
        putIfPresent(attributes, "AWS.SNS.SMS.MaxPrice", maxPrice);
        putIfPresent(attributes, "AWS.MM.SMS.EntityId", entityId);
        putIfPresent(attributes, "AWS.MM.SMS.TemplateId", templateId);
        return PublishRequest.builder()
                .phoneNumber(phone)
                .message(message)
                .messageAttributes(attributes)
                .build();
    }

    private static void putIfPresent(
            Map<String, MessageAttributeValue> attributes,
            String name,
            String value) {
        if (!value.isBlank()) {
            attributes.put(name, stringAttribute(value));
        }
    }

    private static MessageAttributeValue stringAttribute(String value) {
        return MessageAttributeValue.builder()
                .dataType(STRING_TYPE)
                .stringValue(value)
                .build();
    }

    @PreDestroy
    void close() {
        snsClient.close();
    }
}

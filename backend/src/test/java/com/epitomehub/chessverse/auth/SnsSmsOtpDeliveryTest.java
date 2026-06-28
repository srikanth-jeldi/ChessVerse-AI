package com.epitomehub.chessverse.auth;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;
import software.amazon.awssdk.services.sns.model.PublishRequest;

class SnsSmsOtpDeliveryTest {
    @Test
    void publishesTransactionalOtpWithIndiaAttributes() {
        PublishRequest request = SnsSmsOtpDelivery.createPublishRequest(
                "+919876543210",
                "Your ChessVerse verification code is 123456. It expires in 10 minutes.",
                "CHESSV",
                "0.10",
                "entity-123",
                "template-456");

        assertThat(request.phoneNumber()).isEqualTo("+919876543210");
        assertThat(request.message()).contains("123456");
        assertThat(request.messageAttributes())
                .containsKeys(
                        "AWS.SNS.SMS.SMSType",
                        "AWS.SNS.SMS.SenderID",
                        "AWS.SNS.SMS.MaxPrice",
                        "AWS.MM.SMS.EntityId",
                        "AWS.MM.SMS.TemplateId");
        assertThat(request.messageAttributes()
                        .get("AWS.SNS.SMS.SMSType")
                        .stringValue())
                .isEqualTo("Transactional");
    }
}

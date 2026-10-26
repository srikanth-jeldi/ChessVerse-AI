package com.epitomehub.chessverse.online;

import java.util.UUID;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ClubInvitationMailServiceTest {
    @Test void invitationContainsNavigationAndNoAutomaticJoinAndEscapesNames() throws Exception {
        var sender=mock(JavaMailSender.class);
        var message=new MimeMessage(Session.getInstance(new java.util.Properties()));
        when(sender.createMimeMessage()).thenReturn(message);
        var id=UUID.randomUUID();
        new ClubInvitationMailService(sender,"owner@example.com","https://chessverseai.com/play/")
                .send("future@example.com","<script>club</script>","Friend & Family",id);
        verify(sender).send(message);
        message.saveChanges();
        String text=body(message,"text/plain");
        String html=body(message,"text/html");
        assertTrue(text.contains("https://chessverseai.com/play/?clubInvite="+id));
        assertTrue(text.contains("only join after accepting"));
        assertTrue(text.contains("expires in 7 days"));
        assertTrue(html.contains("&lt;script&gt;"));
        assertFalse(html.contains("<script>"));
        assertTrue(html.contains("Friend &amp; Family"));
    }
    private String body(jakarta.mail.Part part, String type) throws Exception {
        if (part.isMimeType(type) && part.getContent() instanceof String content) return content;
        if (part.getContent() instanceof jakarta.mail.Multipart multipart) {
            for (int i=0;i<multipart.getCount();i++) {
                String value=body(multipart.getBodyPart(i),type);
                if (!value.isEmpty()) return value;
            }
        }
        return "";
    }
}

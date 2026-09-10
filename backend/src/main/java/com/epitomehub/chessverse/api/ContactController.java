package com.epitomehub.chessverse.api;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/contact")
class ContactController {
    private final JavaMailSender mailSender;
    private final String from;
    private final String recipient;

    ContactController(
            JavaMailSender mailSender,
            @Value("${chessverse.auth.mail-from:}") String from,
            @Value("${chessverse.contact.recipient:contactus@epitomehub.com}") String recipient) {
        this.mailSender = mailSender;
        this.from = from;
        this.recipient = recipient;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    Map<String, String> submit(@Valid @RequestBody ContactRequest request) {
        // Hidden field: silently accept bot submissions without sending mail.
        if (StringUtils.hasText(request.website())) {
            return Map.of("message", "Thank you. Your message has been received.");
        }
        if (!StringUtils.hasText(from)) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Contact email is temporarily unavailable.");
        }
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, StandardCharsets.UTF_8.name());
            helper.setFrom(from);
            helper.setTo(recipient);
            helper.setReplyTo(request.email().trim());
            helper.setSubject("[ChessVerseAI Contact] " + request.category() + " — " + request.name().trim());
            helper.setText("Name: " + request.name().trim() + "\nEmail: " + request.email().trim()
                    + "\nCategory: " + request.category() + "\n\nMessage:\n" + request.message().trim());
            mailSender.send(message);
            return Map.of("message", "Thank you. Your message has been sent to the ChessVerseAI team.");
        } catch (MessagingException exception) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Your message could not be sent. Please try again.");
        }
    }

    record ContactRequest(
            @NotBlank @Size(max = 80) String name,
            @NotBlank @Email @Size(max = 254) String email,
            @NotBlank @Pattern(regexp = "Product support|Account help|Bug report|Safety report|Business inquiry|Other") String category,
            @NotBlank @Size(min = 10, max = 3000) String message,
            @Size(max = 0) String website) {}
}

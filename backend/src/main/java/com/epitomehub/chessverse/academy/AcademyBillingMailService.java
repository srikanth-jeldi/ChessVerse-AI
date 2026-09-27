package com.epitomehub.chessverse.academy;

import jakarta.mail.internet.MimeMessage;
import java.nio.charset.StandardCharsets;
import org.slf4j.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.*;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
class AcademyBillingMailService {
    private static final Logger log=LoggerFactory.getLogger(AcademyBillingMailService.class);
    private final JavaMailSender sender; private final String from;
    AcademyBillingMailService(JavaMailSender sender,@Value("${chessverse.auth.mail-from:}")String from){this.sender=sender;this.from=from==null?"":from.trim();}
    boolean invoice(String to,String academy,String number,String amount){return send(to,"ChessVerseAI Academy invoice "+number,"Payment received",academy+" payment was confirmed. Invoice "+number+" · "+amount+". Sign in to the Academy portal to view the immutable billing record.");}
    boolean failed(String to,String academy,String reason){return send(to,"ChessVerseAI Academy payment needs attention","Payment was not completed",academy+" payment could not be completed. "+reason+" No academy access or invoice was created. You may safely retry from the portal.");}
    boolean renewal(String to,String academy,String date,int days){return send(to,"ChessVerseAI Academy renewal reminder","Academy renewal is approaching",academy+" renews on "+date+" ("+days+" day"+(days==1?"":"s")+" remaining). Review your plan, seats, and billing details in the Academy portal.");}
    private boolean send(String to,String subject,String heading,String body){if(!StringUtils.hasText(from)||!StringUtils.hasText(to))return false;try{MimeMessage m=sender.createMimeMessage();MimeMessageHelper h=new MimeMessageHelper(m,false,StandardCharsets.UTF_8.name());h.setFrom(from);h.setTo(to);h.setSubject(subject);h.setText(heading+"\n\n"+body,"<html><body style=\"font-family:Arial;background:#eef3f5;padding:24px\"><div style=\"max-width:560px;margin:auto;background:#fff;padding:32px;border-radius:14px\"><h1>"+esc(heading)+"</h1><p>"+esc(body)+"</p><hr><small>ChessVerseAI · EpitomeHub Technologies</small></div></body></html>");sender.send(m);return true;}catch(Exception e){log.warn("Academy billing email failed: {}",e.getClass().getSimpleName());return false;}}
    private static String esc(String v){return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}
}

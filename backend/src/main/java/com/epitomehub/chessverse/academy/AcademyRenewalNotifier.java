package com.epitomehub.chessverse.academy;

import java.time.LocalDate;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
class AcademyRenewalNotifier {
    private final JdbcTemplate db;private final AcademyBillingMailService mail;
    AcademyRenewalNotifier(JdbcTemplate db,AcademyBillingMailService mail){this.db=db;this.mail=mail;}
    @Scheduled(cron="0 30 2 * * *",zone="UTC") public void notifyDue(){for(int days:new int[]{7,1})notify(days);}
    void notify(int days){LocalDate date=LocalDate.now().plusDays(days);var rows=db.query("SELECT o.id,o.name,p.id account_id,p.email FROM academy_organization o JOIN academy_member m ON m.organization_id=o.id AND m.role='ORGANIZATION_ADMIN' AND m.active=TRUE JOIN player_account p ON p.id=m.account_id WHERE o.status='ACTIVE' AND o.renewal_date=? AND NOT EXISTS (SELECT 1 FROM academy_billing_notice n WHERE n.organization_id=o.id AND n.recipient_account_id=p.id AND n.notice_type=? AND n.renewal_date=o.renewal_date)",(r,n)->Map.of("id",r.getObject(1),"name",r.getString(2),"account",r.getObject(3),"email",r.getString(4)),date,"RENEWAL_"+days);
        for(var r:rows)if(mail.renewal(r.get("email").toString(),r.get("name").toString(),date.toString(),days))db.update("INSERT INTO academy_billing_notice(organization_id,recipient_account_id,notice_type,renewal_date) VALUES(?,?,?,?)",r.get("id"),r.get("account"),"RENEWAL_"+days,date);
    }
}

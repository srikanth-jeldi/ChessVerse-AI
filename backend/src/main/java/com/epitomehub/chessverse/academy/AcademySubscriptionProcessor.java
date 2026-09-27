package com.epitomehub.chessverse.academy;

import java.time.LocalDate;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
class AcademySubscriptionProcessor {
    private final JdbcTemplate db;
    AcademySubscriptionProcessor(JdbcTemplate db){this.db=db;}
    @Scheduled(cron="0 15 1 * * *",zone="UTC") @Transactional public void applyDue(){
        var ids=db.query("SELECT id FROM academy_subscription_request WHERE status='APPROVED' AND effective_on<=? ORDER BY created_at FOR UPDATE",(r,n)->UUID.fromString(r.getString(1)),LocalDate.now());
        ids.forEach(this::apply);
    }
    void apply(UUID id){
        var rows=db.query("SELECT * FROM academy_subscription_request WHERE id=? AND status='APPROVED' FOR UPDATE",(r,n)->{Map<String,Object> m=new HashMap<>();m.put("org",r.getObject("organization_id"));m.put("action",r.getString("action"));m.put("plan",r.getString("plan_code"));m.put("seats",r.getObject("seats"));m.put("date",r.getObject("effective_on"));return m;},id);
        if(rows.isEmpty())return;var r=rows.getFirst();LocalDate effective=r.get("date") instanceof java.sql.Date d?d.toLocalDate():LocalDate.parse(r.get("date").toString());if(effective.isAfter(LocalDate.now()))return;
        if("CANCEL".equals(r.get("action")))db.update("UPDATE academy_organization SET status='SUSPENDED' WHERE id=?",r.get("org"));
        else db.update("UPDATE academy_organization SET plan=?,seats=?,status='ACTIVE' WHERE id=?",r.get("plan"),r.get("seats"),r.get("org"));
        db.update("UPDATE academy_subscription_request SET status='APPLIED',processed_at=CURRENT_TIMESTAMP WHERE id=?",id);
    }
}

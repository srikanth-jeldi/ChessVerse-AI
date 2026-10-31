package com.epitomehub.chessverse.analytics;

import java.io.ByteArrayOutputStream;
import java.sql.Timestamp;
import java.time.*;
import java.util.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.javamail.*;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Account-level observed activity; login is not required again to appear. */
@Service
public class DailyPlayReportService {
    static final ZoneId ZONE = ZoneId.of("Asia/Kolkata");
    static final List<String> EVENTS=List.of("session_started","game_started","game_first_move","game_completed",
        "puzzle_first_move","puzzle_completed","club_puzzle_completed","imported_review_viewed",
        "saved_review_viewed","mistake_bank_viewed","mistake_practice_completed",
        "chat_opened","chat_message_sent","ai_coach_question","feature_opened",
        "puzzles_viewed","mistake_practice_started","import_completed","club_puzzle_viewed");
    private final JdbcTemplate db;
    private final JavaMailSender mail;
    private final String from,to;
    private final boolean enabled;
    public DailyPlayReportService(JdbcTemplate db,JavaMailSender mail,
        @Value("${chessverse.auth.mail-from:}") String from,
        @Value("${chessverse.play-report.recipient:${chessverse.auth.activity-report.recipient:chessverseai@gmail.com}}") String to,
        @Value("${chessverse.play-report.enabled:${chessverse.auth.activity-report.enabled:true}}") boolean enabled) {
        this.db=db;this.mail=mail;this.from=from;this.to=to;this.enabled=enabled;
    }
    // Full previous IST calendar day. First attempt 09:00, hourly retry until 23:00.
    @Scheduled(cron="${chessverse.play-report.cron:0 0 9-23 * * *}",zone="Asia/Kolkata")
    @Transactional
    public void sendDaily() throws Exception {
        if(!enabled||from.isBlank()||to.isBlank())return;
        LocalDate day=LocalDate.now(ZONE).minusDays(1);
        db.update("insert into daily_play_report_delivery(report_date) values(?) on conflict(report_date) do nothing",day);
        var sent=db.queryForObject("select sent_at from daily_play_report_delivery where report_date=? for update",
            (rs,n)->rs.getTimestamp(1),day);
        if(sent!=null)return;
        List<Activity> rows=activity(day);
        if(rows.isEmpty())return;
        var message=mail.createMimeMessage();
        var helper=new MimeMessageHelper(message,true,"UTF-8");
        helper.setFrom(from);helper.setTo(to);
        long playing=rows.stream().filter(a->a.counts.getOrDefault("game_first_move",0L)>0).count();
        helper.setSubject("ChessVerseAI daily play report • "+day+" • "+playing+" playing accounts");
        helper.setText("Full day: "+day+" 00:00–24:00 IST.\nObserved active accounts: "+rows.size()
            +"\nAccounts making a game move: "+playing
            +"\nSee the attached account and event breakdown. Re-login is not required.\n"
            +"Counts are client-reported events, not unique games or verified play time. Offline/failed telemetry and older builds may be missing. "
            +"First-move events count board visits/attempts; completion may belong to a game started on another day. "
            +"Guests without a real email are shown without an email. No passwords or tokens are included.");
        helper.addAttachment("chessverse-play-"+day+".xlsx",new ByteArrayResource(workbook(day,rows)));
        mail.send(message);
        db.update("update daily_play_report_delivery set sent_at=current_timestamp where report_date=?",day);
    }
    record Activity(UUID id,String name,String username,String email,Timestamp first,Timestamp last,Map<String,Long> counts) {}
    List<Activity> activity(LocalDate day) {
        Timestamp start=Timestamp.from(day.atStartOfDay(ZONE).toInstant());
        Timestamp end=Timestamp.from(day.plusDays(1).atStartOfDay(ZONE).toInstant());
        var result=new LinkedHashMap<UUID,Activity>();
        db.query("""
            select e.player_id,p.display_name,p.username,p.email,e.event_name,e.context_value,count(*) total,
                   min(e.occurred_at) first_at,max(e.occurred_at) last_at
            from product_analytics_event e join player_account p on p.id=e.player_id
            where e.occurred_at>=? and e.occurred_at<?
            group by e.player_id,p.display_name,p.username,p.email,e.event_name,e.context_value
            order by p.username,e.player_id,e.event_name
            """,rs->{
                UUID id=rs.getObject("player_id",UUID.class);
                var old=result.get(id);
                Timestamp first=rs.getTimestamp("first_at"),last=rs.getTimestamp("last_at");
                Map<String,Long> counts=old==null?new HashMap<>():old.counts;
                String event=rs.getString("event_name"),context=rs.getString("context_value");
                counts.merge(event,rs.getLong("total"),Long::sum);
                counts.merge(event+" / "+(context==null?"unspecified":context),rs.getLong("total"),Long::sum);
                if(old!=null){if(old.first.before(first))first=old.first;if(old.last.after(last))last=old.last;}
                result.put(id,new Activity(id,rs.getString("display_name"),rs.getString("username"),realEmail(rs.getString("email")),first,last,counts));
            },start,end);
        return new ArrayList<>(result.values());
    }
    static String realEmail(String email) {
        return email==null||email.endsWith(".invalid")||email.endsWith("@guest.chessverse.ai")?"":email;
    }
    byte[] workbook(LocalDate day,List<Activity> rows) throws Exception {
        try(var book=new XSSFWorkbook();var out=new ByteArrayOutputStream()) {
            var summary=book.createSheet("Summary");
            summary.createRow(0).createCell(0).setCellValue("Activity date (IST): "+day);
            var head=summary.createRow(1);head.createCell(0).setCellValue("Event");head.createCell(1).setCellValue("Accounts");head.createCell(2).setCellValue("Events");
            int r=2;for(String event:EVENTS){var row=summary.createRow(r++);row.createCell(0).setCellValue(event);
                row.createCell(1).setCellValue(rows.stream().filter(a->a.counts.getOrDefault(event,0L)>0).count());
                row.createCell(2).setCellValue(rows.stream().mapToLong(a->a.counts.getOrDefault(event,0L)).sum());}
            var sheet=book.createSheet("Player activity");sheet.createFreezePane(0,1);
            List<String> headers=new ArrayList<>(List.of("Account ID","Display name","Username","Email (if available)","First activity IST","Last activity IST"));headers.addAll(EVENTS);
            var h=sheet.createRow(0);for(int i=0;i<headers.size();i++)h.createCell(i).setCellValue(headers.get(i));
            r=1;for(Activity a:rows){var row=sheet.createRow(r++);
                String[] values={a.id.toString(),a.name,a.username,a.email,a.first.toInstant().atZone(ZONE).toLocalDateTime().toString(),a.last.toInstant().atZone(ZONE).toLocalDateTime().toString()};
                for(int c=0;c<values.length;c++)row.createCell(c).setCellValue(values[c]==null?"":values[c]);
                for(int c=0;c<EVENTS.size();c++)row.createCell(c+6).setCellValue(a.counts.getOrDefault(EVENTS.get(c),0L));}
            for(var s:List.of(summary,sheet))for(int c=0;c<(s==sheet?headers.size():3);c++){s.autoSizeColumn(c);s.setColumnWidth(c,Math.min(12000,s.getColumnWidth(c)+512));}
            var detail=book.createSheet("Feature breakdown");detail.createFreezePane(0,1);
            var dh=detail.createRow(0);String[] labels={"Account ID","Username","Event / feature","Count"};
            for(int c=0;c<labels.length;c++)dh.createCell(c).setCellValue(labels[c]);
            int dr=1;for(Activity a:rows)for(var entry:new TreeMap<>(a.counts).entrySet()) {
                if(!entry.getKey().contains(" / "))continue;
                var row=detail.createRow(dr++);row.createCell(0).setCellValue(a.id.toString());
                row.createCell(1).setCellValue(a.username);row.createCell(2).setCellValue(entry.getKey());row.createCell(3).setCellValue(entry.getValue());
            }
            for(int c=0;c<4;c++){detail.autoSizeColumn(c);detail.setColumnWidth(c,Math.min(12000,detail.getColumnWidth(c)+512));}
            book.write(out);return out.toByteArray();
        }
    }
}

package com.epitomehub.chessverse.analytics;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.sql.Timestamp;
import java.time.*;
import java.util.UUID;
import java.io.ByteArrayInputStream;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.mail.javamail.JavaMailSender;
class DailyPlayReportServiceTest {
 @Test void includesReturningPlayerWithoutLoginAndUsesIstBoundaries() throws Exception {
  var db=new JdbcTemplate(new DriverManagerDataSource("jdbc:h2:mem:"+UUID.randomUUID()+";DB_CLOSE_DELAY=-1","sa",""));
  db.execute("create table player_account(id uuid primary key,display_name varchar,username varchar,email varchar)");
  db.execute("create table product_analytics_event(player_id uuid,event_name varchar,occurred_at timestamp,context_value varchar)");
  var id=UUID.randomUUID();db.update("insert into player_account values(?,'Player','tester','test@example.com')",id);
  for(var time:new String[]{"2026-10-29T18:29:59Z","2026-10-29T18:30:00Z","2026-10-30T18:29:59Z","2026-10-30T18:30:00Z"})
   db.update("insert into product_analytics_event values(?,'game_first_move',?,'computer')",id,Timestamp.from(Instant.parse(time)));
  var service=new DailyPlayReportService(db,mock(JavaMailSender.class),"","",false);
  var day=LocalDate.of(2026,10,30);var rows=service.activity(day);
  assertEquals(1,rows.size());assertEquals(2L,rows.getFirst().counts().get("game_first_move"));
  assertFalse(rows.getFirst().counts().containsKey("session_started"));
  try(var book=new XSSFWorkbook(new ByteArrayInputStream(service.workbook(day,rows)))) {
   assertEquals(3,book.getNumberOfSheets());
   assertEquals("tester",book.getSheet("Player activity").getRow(1).getCell(2).getStringCellValue());
   assertEquals(2,book.getSheet("Player activity").getRow(1).getCell(8).getNumericCellValue());
  }
 }
 @Test void disabledReportingNeverSends() throws Exception {
  var mail=mock(JavaMailSender.class);
  new DailyPlayReportService(mock(JdbcTemplate.class),mail,"sender","recipient",false).sendDaily();
  verifyNoInteractions(mail);
  assertEquals("",DailyPlayReportService.realEmail("guest@identity.chessverse.invalid"));
 }
}


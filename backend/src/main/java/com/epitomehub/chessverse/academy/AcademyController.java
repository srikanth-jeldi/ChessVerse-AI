package com.epitomehub.chessverse.academy;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

/** All tenant selection is checked against server-side membership, never a client role. */
@RestController
@RequestMapping("/api/v1/academy")
@Transactional
public class AcademyController {
    private final JdbcTemplate db;
    private final PlayerAuthenticationService auth;
    private final ObjectMapper json;
    private final AcademyGuidanceService guidance;
    public AcademyController(JdbcTemplate db, PlayerAuthenticationService auth, ObjectMapper json, AcademyGuidanceService guidance) {
        this.db = db; this.auth = auth; this.json = json; this.guidance=guidance;
    }
    record Access(UUID account, UUID member, String role) {
        boolean admin() { return role.equals("ORGANIZATION_ADMIN"); }
        boolean trainer() { return admin() || role.equals("COACH"); }
    }
    public record OrganizationInput(@NotBlank @Size(max=100) String name,
        @Pattern(regexp="ACADEMY|SCHOOL") @NotNull String kind, @NotNull UUID adminAccountId) {}
    public record StudentInput(@NotBlank @Size(max=100) String name, @NotBlank @Email @Size(max=254) String email,
        UUID accountId, UUID batchId, UUID coachId, boolean active) {}
    public record ImportInput(@NotEmpty @Size(max=200) List<@Valid StudentInput> students) {}
    public record BatchInput(@NotBlank @Size(max=100) String name,
        @NotNull @Pattern(regexp="BEGINNER|INTERMEDIATE|ADVANCED") String level,
        @NotBlank @Size(max=200) String schedule, UUID coachId) {}
    public record MemberInput(@NotBlank @Email @Size(max=254) String email, @NotBlank @Size(max=100) String name,
        @NotNull @Pattern(regexp="ORGANIZATION_ADMIN|COACH|STUDENT|PARENT") String role, boolean active) {}
    public record ParentInput(@NotNull UUID memberId, @NotNull UUID studentId) {}
    public record AssignmentInput(@NotEmpty @Size(max=200) List<UUID> studentIds, @NotBlank @Size(max=150) String title,
        @NotNull @Pattern(regexp="PUZZLES|POSITIONS|OPENINGS|MASTER_GAMES") String kind,
        @NotBlank @Size(max=2000) String instructions, @NotNull LocalDate dueDate,
        @Pattern(regexp="(easy|medium|hard)-[0-9]{1,3}") String puzzleId,
        @Size(max=120) String positionFen, @Pattern(regexp="[a-h][1-8][a-h][1-8][qrbn]?") String bestMove) {
        public AssignmentInput(List<UUID> students,String title,String kind,String instructions,LocalDate dueDate) {this(students,title,kind,instructions,dueDate,null,null,null);}
    }
    public record AssignmentResultInput(@NotNull UUID id,@Min(1) @Max(1000) int attempts,boolean solved,@NotNull @Size(max=2000) String notes) {}
    public record ObservationInput(@NotNull UUID studentId, @NotNull @PastOrPresent LocalDate practicedOn,
        @Min(0) @Max(4000) int rating, @Min(0) @Max(100) int accuracy, @Min(1) @Max(1440) int minutes,
        @Min(0) @Max(10000) int tactics, @Min(0) @Max(1000) int blunders,
        @Min(0) @Max(1000) int openingErrors, @Min(0) @Max(1000) int middleErrors,
        @Min(0) @Max(1000) int endgameErrors, @Min(0) @Max(1000) int retryAttempts,
        @Min(0) @Max(1000) int retryFailures, @NotNull @Size(max=2000) String notes) {}
    public record BrandingInput(@NotBlank @Size(max=100) String name,
        @NotNull @Pattern(regexp="#[0-9a-fA-F]{6}") String color,
        @NotNull @Size(max=500) @Pattern(regexp="^$|^https://[^\\s]+$") String logoUrl, boolean whiteLabel) {}
    public record SeatInput(@Min(1) @Max(10000) int seats) {}
    public record SupportInput(@NotBlank @Size(max=200) String subject) {}
    public record LicenseInput(@NotBlank @Size(max=60) String plan, @Min(1) @Max(100000) int seats,
        @NotNull LocalDate renewalDate, @NotNull @Pattern(regexp="TRIAL|ACTIVE|SUSPENDED") String status,
        @NotNull @Size(max=1000) String featureFlags) {}
    public record ReportInput(@NotNull UUID studentId, @NotNull @Pattern(regexp="WEEKLY|MONTHLY") String period) {}

    private List<Map<String,Object>> rows(String sql, Object... args) {
        return db.query(sql, (rs,n) -> {
            Map<String,Object> row = new LinkedHashMap<>();
            for(int i=1;i<=rs.getMetaData().getColumnCount();i++) {
                Object value = rs.getObject(i);
                if (value instanceof java.sql.Date d) value = d.toLocalDate().toString();
                else if (value instanceof java.time.OffsetDateTime || value instanceof java.sql.Timestamp) value = value.toString();
                row.put(rs.getMetaData().getColumnLabel(i).toLowerCase(Locale.ROOT),value);
            }
            return row;
        }, args);
    }
    private long count(String sql, Object... args) { return db.queryForObject(sql,Long.class,args); }
    private void require(boolean allowed, HttpStatus status, String message) {
        if (!allowed) throw new ResponseStatusException(status,message);
    }
    private UUID uuid(Object o) { return UUID.fromString(o.toString()); }
    private Map<String,Object> organization(UUID org) {
        return rows("SELECT * FROM academy_organization WHERE id=?",org).stream().findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,"Organization not found"));
    }
    private Access access(String bearer, UUID org) {
        UUID account = auth.requireBearer(bearer).id();
        var member = rows("SELECT * FROM academy_member WHERE organization_id=? AND account_id=? AND active=TRUE",org,account);
        require(!member.isEmpty(),HttpStatus.FORBIDDEN,"No active membership in this organization");
        require(!organization(org).get("status").equals("SUSPENDED"),HttpStatus.FORBIDDEN,"Organization is suspended; contact EpitomeHub support");
        var license=organization(org);
        require(license.get("renewal_date")==null||LocalDate.parse(license.get("renewal_date").toString()).isAfter(LocalDate.now()),HttpStatus.PAYMENT_REQUIRED,"Your academy plan has expired. Ask your owner to renew.");
        return new Access(account,uuid(member.getFirst().get("id")),member.getFirst().get("role").toString());
    }
    private Access admin(String bearer, UUID org) {
        Access a=access(bearer,org); require(a.admin(),HttpStatus.FORBIDDEN,"Organization Admin required"); return a;
    }
    private Access trainer(String bearer, UUID org) {
        Access a=access(bearer,org); require(a.trainer(),HttpStatus.FORBIDDEN,"Coach access required"); return a;
    }
    private void superAdmin(String bearer) {
        UUID account=auth.requireBearer(bearer).id();
        require(count("SELECT COUNT(*) FROM academy_super_admin WHERE account_id=?",account)>0,HttpStatus.FORBIDDEN,"EpitomeHub Super Admin required");
    }
    private List<Map<String,Object>> students(UUID org, Access a) {
        if(a.admin()) return rows("SELECT * FROM academy_student WHERE organization_id=? ORDER BY name",org);
        if(a.role.equals("COACH")) return rows("SELECT * FROM academy_student WHERE organization_id=? AND coach_id=? ORDER BY name",org,a.member);
        if(a.role.equals("STUDENT")) return rows("SELECT * FROM academy_student WHERE organization_id=? AND account_id=? AND active=TRUE",org,a.account);
        return rows("SELECT s.* FROM academy_student s JOIN academy_parent_link p ON p.organization_id=s.organization_id AND p.student_id=s.id WHERE s.organization_id=? AND p.member_id=? AND s.active=TRUE",org,a.member);
    }
    private Map<String,Object> student(UUID org, UUID id, Access a) {
        return students(org,a).stream().filter(s -> uuid(s.get("id")).equals(id)).findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,"Student not found in your scope"));
    }
    private void coach(UUID org, UUID coach) {
        if(coach!=null) require(count("SELECT COUNT(*) FROM academy_member WHERE organization_id=? AND id=? AND role='COACH' AND active=TRUE",org,coach)==1,HttpStatus.BAD_REQUEST,"Choose an active coach in this organization");
    }
    private void lock(UUID org) { db.queryForObject("SELECT seats FROM academy_organization WHERE id=? FOR UPDATE",Integer.class,org); }
    private void capacity(UUID org, int added) {
        long used=count("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND active=TRUE",org);
        require(used+added<=((Number)organization(org).get("seats")).intValue(),HttpStatus.CONFLICT,"Seat limit reached. Request additional seats.");
    }
    private void account(UUID account) {
        require(count("SELECT COUNT(*) FROM player_account WHERE id=? AND verified=TRUE",account)==1,HttpStatus.BAD_REQUEST,"A verified ChessVerse account is required");
    }

    @GetMapping("/me")
    public Map<String,Object> me(@RequestHeader("Authorization") String bearer) {
        var p=auth.requireBearer(bearer);
        return Map.of("name",p.displayName(),"accountId",p.id(),"superAdmin",count("SELECT COUNT(*) FROM academy_super_admin WHERE account_id=?",p.id())>0,
            "organizations",rows("SELECT o.*,m.role FROM academy_organization o JOIN academy_member m ON m.organization_id=o.id WHERE m.account_id=? AND m.active=TRUE ORDER BY o.name",p.id()));
    }
    @GetMapping("/{org}/workspace")
    public Map<String,Object> workspace(@RequestHeader("Authorization") String bearer, @PathVariable UUID org) {
        Access a=access(bearer,org); var students=students(org,a);
        Set<UUID> ids=new HashSet<>(); students.forEach(s -> ids.add(uuid(s.get("id"))));
        Map<String,Object> result=new LinkedHashMap<>();
        result.put("organization",organization(org)); result.put("role",a.role); result.put("memberId",a.member);
        result.put("students",students);
        result.put("members",a.admin()?rows("SELECT m.*,p.email FROM academy_member m JOIN player_account p ON p.id=m.account_id WHERE m.organization_id=? ORDER BY m.name",org):rows("SELECT id,name,role,active FROM academy_member WHERE organization_id=? AND role='COACH' AND active=TRUE",org));
        var batches=rows("SELECT * FROM academy_batch WHERE organization_id=? ORDER BY name",org);
        if(!a.admin()) batches=batches.stream().filter(b -> (a.role.equals("COACH") && a.member.equals(b.get("coach_id"))) || students.stream().anyMatch(s -> b.get("id").equals(s.get("batch_id")))).toList();
        result.put("batches",batches);
        for(String table : List.of("assignment","observation","report","game")) {
            String columns=table.equals("game")?"id,organization_id,student_id,game_id,created_at":"*";
            result.put(table+"s",rows("SELECT "+columns+" FROM academy_"+table+" WHERE organization_id=? ORDER BY created_at DESC",org)
                .stream().filter(r -> ids.contains(uuid(r.get("student_id")))).toList());
        }
        result.put("assignmentResults",rows("SELECT * FROM academy_assignment_result WHERE organization_id=? ORDER BY created_at DESC",org).stream().filter(r->ids.contains(uuid(r.get("student_id")))).toList());
        result.put("invoices",a.admin()?rows("SELECT * FROM academy_invoice WHERE organization_id=? ORDER BY issued_on DESC",org):List.of());
        result.put("seatRequests",a.admin()?rows("SELECT * FROM academy_seat_request WHERE organization_id=? ORDER BY created_at DESC",org):List.of());
        result.put("support",a.admin()?rows("SELECT * FROM academy_support WHERE organization_id=? ORDER BY created_at DESC",org):List.of());
        result.put("parentLinks",a.admin()?rows("SELECT * FROM academy_parent_link WHERE organization_id=?",org):List.of());
        return result;
    }
    // Activity has its own bounded read endpoint; personal game bodies are never returned.
    @GetMapping("/{org}/app-activity")
    public Map<String,Object> appActivity(@RequestHeader("Authorization") String bearer,@PathVariable UUID org) {
        Access a=access(bearer,org);
        var visible=students(org,a).stream().filter(s->Boolean.TRUE.equals(s.get("active"))).map(s->uuid(s.get("id"))).toList();
        if(visible.isEmpty()) return Map.of("events",List.of(),"sharing",List.of(),"weaknesses",List.of(),"mistakeBank",List.of(),"checkedAt",java.time.Instant.now().toString());
        String placeholders=String.join(",",Collections.nCopies(visible.size(),"?"));
        List<Object> args=new ArrayList<>();args.add(org);args.addAll(visible);
        var query=activityQuery(org,visible);
        var events=rows(query.sql+" LIMIT 100",query.args.toArray());
        var sharing=rows("SELECT c.student_id,c.enabled,c.enabled_at,c.mistake_bank_enabled FROM academy_activity_sharing c JOIN academy_student s ON s.organization_id=c.organization_id AND s.id=c.student_id AND s.account_id=c.account_id WHERE c.organization_id=? AND c.student_id IN ("+placeholders+")",args.toArray());
        String eligible=" FROM academy_activity_sharing c JOIN academy_student s ON s.organization_id=c.organization_id AND s.id=c.student_id AND s.account_id=c.account_id JOIN academy_member m ON m.organization_id=s.organization_id AND m.account_id=s.account_id AND m.role='STUDENT' AND m.active=TRUE ";
        String scope=" c.organization_id=? AND s.id IN ("+placeholders+") AND s.active=TRUE AND c.enabled=TRUE ";
        List<Object> weaknessArgs=new ArrayList<>(args);weaknessArgs.add(java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(30L*86400)));
        var weaknesses=rows("SELECT s.id AS student_id,w.category,COUNT(*) AS mistakes,SUM(CASE WHEN w.classification='Blunder' THEN 1 ELSE 0 END) AS blunders"+eligible+"JOIN player_weakness_event w ON w.player_id=s.account_id WHERE "+scope+" AND w.occurred_at>=c.enabled_at AND w.occurred_at>=? GROUP BY s.id,w.category ORDER BY mistakes DESC LIMIT 100",weaknessArgs.toArray());
        LocalDate today=LocalDate.now(java.time.ZoneOffset.UTC);
        var assignmentResults=rows("SELECT r.*,a.title,a.kind FROM academy_assignment_result r JOIN academy_assignment a ON a.organization_id=r.organization_id AND a.id=r.assignment_id WHERE r.organization_id=? AND r.student_id IN ("+placeholders+") ORDER BY r.created_at DESC LIMIT 100",args.toArray());
        return Map.of("events",events,"sharing",sharing,"weaknesses",weaknesses,"daily",activityDaily(org,visible,today.minusDays(29),today),"assignmentResults",assignmentResults,"mistakeBank",sharedMistakes(org,a),"checkedAt",java.time.Instant.now().toString());
    }
    private List<Map<String,Object>> activityDaily(UUID org,List<UUID> ids,LocalDate from,LocalDate to) {
        if(ids.isEmpty())return List.of();
        var query=activityQuery(org,ids);var args=new ArrayList<>(query.args);
        args.add(java.sql.Timestamp.from(from.atStartOfDay(java.time.ZoneOffset.UTC).toInstant()));
        args.add(java.sql.Timestamp.from(to.plusDays(1).atStartOfDay(java.time.ZoneOffset.UTC).toInstant()));
        return rows("SELECT student_id,CAST(occurred_at AS DATE) AS \"day\",kind,COUNT(*) AS events,SUM(solved) AS solved,SUM(attempted) AS attempted,SUM(seconds) AS seconds FROM ("+query.sql+") history WHERE occurred_at>=? AND occurred_at<? GROUP BY student_id,CAST(occurred_at AS DATE),kind ORDER BY \"day\",kind",args.toArray());
    }
    private record ActivityQuery(String sql,List<Object> args) {}
    private ActivityQuery activityQuery(UUID org,List<UUID> visible) {
        String placeholders=String.join(",",Collections.nCopies(visible.size(),"?"));
        List<Object> args=new ArrayList<>();args.add(org);args.addAll(visible);
        String eligible=" FROM academy_activity_sharing c JOIN academy_student s ON s.organization_id=c.organization_id AND s.id=c.student_id AND s.account_id=c.account_id JOIN academy_member m ON m.organization_id=s.organization_id AND m.account_id=s.account_id AND m.role='STUDENT' AND m.active=TRUE ";
        String scope=" c.organization_id=? AND s.id IN ("+placeholders+") AND s.active=TRUE AND c.enabled=TRUE ";
        String games="SELECT s.id AS student_id, 'GAME_SAVED' AS kind, g.game_id AS source_id, g.created_at AS occurred_at, 0 AS solved, 0 AS attempted, 0 AS seconds"+eligible+"JOIN computer_game_history g ON g.player_id=s.account_id WHERE "+scope+" AND g.created_at>=c.enabled_at";
        String puzzles="SELECT s.id AS student_id, 'PUZZLE_SPRINT' AS kind, CAST(p.id AS VARCHAR(80)) AS source_id, p.played_at AS occurred_at, p.score AS solved, p.attempted, p.duration_seconds AS seconds"+eligible+"JOIN puzzle_sprint_result p ON p.player_id=s.account_id WHERE "+scope+" AND p.played_at>=c.enabled_at";
        String retries="SELECT s.id AS student_id, 'POSITION_RETRY' AS kind, CAST(p.id AS VARCHAR(80)) AS source_id, p.received_at AS occurred_at, CASE WHEN p.correct THEN 1 ELSE 0 END AS solved, 1 AS attempted, 0 AS seconds"+eligible+"JOIN player_position_retry p ON p.player_id=s.account_id WHERE "+scope+" AND p.received_at>=c.enabled_at";
        String online="SELECT s.id AS student_id, 'ONLINE_GAME' AS kind, CAST(g.id AS VARCHAR(80)) AS source_id, g.finished_at AS occurred_at, 0 AS solved, 0 AS attempted, 0 AS seconds"+eligible+"JOIN online_match g ON (g.white_player_id=s.account_id OR g.black_player_id=s.account_id) WHERE "+scope+" AND g.started_at IS NOT NULL AND g.finished_at>=c.enabled_at";
        String normal="SELECT s.id AS student_id, 'PUZZLE_COMPLETED' AS kind, p.puzzle_id AS source_id, p.received_at AS occurred_at, 1 AS solved, 1 AS attempted, 0 AS seconds"+eligible+"JOIN player_puzzle_completion p ON p.player_id=s.account_id WHERE "+scope+" AND p.received_at>=c.enabled_at";
        List<Object> both=new ArrayList<>(args);both.addAll(args);both.addAll(args);both.addAll(args);both.addAll(args);
        return new ActivityQuery("SELECT * FROM ("+games+" UNION ALL "+puzzles+" UNION ALL "+retries+" UNION ALL "+online+" UNION ALL "+normal+") activity ORDER BY occurred_at DESC,source_id DESC",both);
    }
    public record MistakeItem(@NotBlank @Size(max=100) String id,
        @NotBlank @Size(max=120) String fen, @NotNull @Pattern(regexp="[a-h][1-8][a-h][1-8][qrbn]?") String bestMove,
        @NotNull @Pattern(regexp="[a-h][1-8][a-h][1-8][qrbn]?") String playedMove,
        @NotNull @Pattern(regexp="(?i)inaccuracy|mistake|blunder") String classification,
        @Min(0) @Max(100000) int centipawnLoss, @Min(0) @Max(1000000) int attempts,
        @Min(0) @Max(1000000) int successes, @Min(0) @Max(5) int stage,
        @NotNull java.time.Instant nextReview, @NotNull java.time.Instant updatedAt) {}
    public record MistakeSync(@NotNull @Size(max=100) List<@NotNull @Valid MistakeItem> items) {}
    @PutMapping("/{org}/mistake-bank/sharing")
    public void mistakeSharing(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@RequestBody ActivitySharingInput input) {
        Access a=access(bearer,org);require(a.role.equals("STUDENT"),HttpStatus.FORBIDDEN,"Student access required");lock(org);
        var linked=students(org,a);require(linked.size()==1,HttpStatus.CONFLICT,"Link one active student profile first");
        UUID id=uuid(linked.getFirst().get("id"));
        require(count("SELECT COUNT(*) FROM academy_activity_sharing WHERE organization_id=? AND student_id=? AND account_id=? AND enabled=TRUE",org,id,a.account)==1,HttpStatus.CONFLICT,"Enable activity sharing first");
        db.update("UPDATE academy_activity_sharing SET mistake_bank_enabled=? WHERE organization_id=? AND student_id=?",input.enabled,org,id);
        if(!input.enabled)db.update("DELETE FROM academy_mistake_bank WHERE organization_id=? AND student_id=?",org,id);
    }
    @PostMapping("/{org}/mistake-bank/sync")
    public Map<String,Object> syncMistakes(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody MistakeSync input) {
        Access a=access(bearer,org);require(a.role.equals("STUDENT"),HttpStatus.FORBIDDEN,"Student access required");lock(org);
        var linked=students(org,a);require(linked.size()==1,HttpStatus.CONFLICT,"Link one active student profile first");UUID id=uuid(linked.getFirst().get("id"));
        require(count("SELECT COUNT(*) FROM academy_activity_sharing WHERE organization_id=? AND student_id=? AND account_id=? AND enabled=TRUE AND mistake_bank_enabled=TRUE",org,id,a.account)==1,HttpStatus.FORBIDDEN,"Mistake position sharing is not enabled");
        require(input.items.stream().map(MistakeItem::id).distinct().count()==input.items.size(),HttpStatus.BAD_REQUEST,"Duplicate mistake identifiers");
        for(var item:input.items){
            require(item.successes<=item.attempts,HttpStatus.BAD_REQUEST,"Successes cannot exceed attempts");
            require(!item.updatedAt.isAfter(java.time.Instant.now().plusSeconds(300)),HttpStatus.BAD_REQUEST,"Invalid review timestamp");
            require(item.fen.matches("[prnbqkPRNBQK1-8/]+ [wb] [-KQkq]+ (-|[a-h][36]) [0-9]+ [0-9]+"),HttpStatus.BAD_REQUEST,"Invalid position FEN");
        }
        // Replace a bounded snapshot atomically; empty banks remove stale shared positions.
        db.update("DELETE FROM academy_mistake_bank WHERE organization_id=? AND student_id=?",org,id);
        for(var item:input.items)db.update("INSERT INTO academy_mistake_bank(organization_id,student_id,mistake_id,account_id,snapshot) VALUES(?,?,?,?,?)",org,id,item.id,a.account,json.writeValueAsString(item));
        return Map.of("synced",input.items.size());
    }
    @GetMapping("/{org}/students/{id}/mistake-bank")
    public List<Map<String,Object>> studentMistakes(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id) {
        Access a=access(bearer,org);student(org,id,a);return sharedMistakes(org,a,id);
    }
    private List<Map<String,Object>> sharedMistakes(UUID org,Access a) {return sharedMistakes(org,a,null);}
    private List<Map<String,Object>> sharedMistakes(UUID org,Access a,UUID target) {
        var ids=students(org,a).stream().filter(s->Boolean.TRUE.equals(s.get("active"))&&(target==null||target.equals(uuid(s.get("id"))))).map(s->uuid(s.get("id"))).toList();
        if(ids.isEmpty())return List.of();
        var args=new ArrayList<Object>();args.add(org);args.addAll(ids);
        var records=rows("SELECT b.student_id,b.snapshot,b.updated_at FROM academy_mistake_bank b JOIN academy_student s ON s.organization_id=b.organization_id AND s.id=b.student_id AND s.account_id=b.account_id JOIN academy_activity_sharing c ON c.organization_id=b.organization_id AND c.student_id=b.student_id AND c.account_id=b.account_id JOIN academy_member m ON m.organization_id=b.organization_id AND m.account_id=b.account_id AND m.role='STUDENT' AND m.active=TRUE WHERE b.organization_id=? AND s.active=TRUE AND c.enabled=TRUE AND c.mistake_bank_enabled=TRUE AND b.student_id IN ("+String.join(",",Collections.nCopies(ids.size(),"?"))+") ORDER BY b.updated_at DESC,b.mistake_id LIMIT 300",args.toArray());
        for(var row:records)row.put("position",json.readTree(row.remove("snapshot").toString()));
        return records;
    }
    public record ActivitySharingInput(boolean enabled) {}
    @PutMapping("/{org}/app-activity/sharing")
    public void activitySharing(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@RequestBody ActivitySharingInput input) {
        Access a=access(bearer,org);
        require(a.role.equals("STUDENT"),HttpStatus.FORBIDDEN,"Only a student can change their own activity sharing");
        var own=students(org,a);
        require(own.size()==1,HttpStatus.CONFLICT,"Link an active student profile first");
        UUID id=uuid(own.getFirst().get("id"));
        db.queryForObject("SELECT id FROM academy_student WHERE organization_id=? AND id=? FOR UPDATE",UUID.class,org,id);
        var existing=rows("SELECT * FROM academy_activity_sharing WHERE organization_id=? AND student_id=?",org,id);
        if(!input.enabled || (!existing.isEmpty() && !Objects.equals(existing.getFirst().get("account_id"),a.account))){
            db.update("UPDATE academy_activity_sharing SET mistake_bank_enabled=FALSE WHERE organization_id=? AND student_id=?",org,id);
            db.update("DELETE FROM academy_mistake_bank WHERE organization_id=? AND student_id=?",org,id);
        }
        if(existing.isEmpty()) db.update("INSERT INTO academy_activity_sharing(organization_id,student_id,account_id,enabled) VALUES(?,?,?,?)",org,id,a.account,input.enabled);
        else if(!Objects.equals(existing.getFirst().get("enabled"),input.enabled)||!Objects.equals(existing.getFirst().get("account_id"),a.account))
            db.update("UPDATE academy_activity_sharing SET account_id=?,enabled=?,enabled_at=CURRENT_TIMESTAMP WHERE organization_id=? AND student_id=?",a.account,input.enabled,org,id);
    }
    @PostMapping("/{org}/students")
    public Map<String,Object> addStudent(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody StudentInput input) {
        admin(bearer,org); lock(org); return saveStudent(org,UUID.randomUUID(),input,false);
    }
    @PutMapping("/{org}/students/{id}")
    public Map<String,Object> editStudent(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id,@Valid @RequestBody StudentInput input) {
        Access a=admin(bearer,org); lock(org); student(org,id,a); return saveStudent(org,id,input,true);
    }
    private Map<String,Object> saveStudent(UUID org, UUID id, StudentInput i, boolean edit) {
        if(!edit && "Free trial".equals(organization(org).get("plan"))) {
            require(count("SELECT COUNT(*) FROM academy_student WHERE organization_id=?",org)<15,HttpStatus.CONFLICT,
                "Your free trial includes 15 student records, including inactive students. Choose a paid plan to add more. Growth supports 60 students and 5 coaches.");
        }
        coach(org,i.coachId);
        if(i.batchId!=null) require(count("SELECT COUNT(*) FROM academy_batch WHERE organization_id=? AND id=?",org,i.batchId)==1,HttpStatus.BAD_REQUEST,"Batch belongs to another organization or does not exist");
        if(i.accountId!=null) {
            account(i.accountId);
            require(count("SELECT COUNT(*) FROM academy_member WHERE organization_id=? AND account_id=? AND role='STUDENT' AND active=TRUE",org,i.accountId)==1,HttpStatus.BAD_REQUEST,"Link an active Student member account first");
        }
        String email=i.email.trim().toLowerCase(Locale.ROOT);
        require(count("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND id<>? AND (email=? OR account_id=?)",org,id,email,i.accountId)==0,HttpStatus.CONFLICT,"Student email or account already exists");
        boolean wasActive=edit && count("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND id=? AND active=TRUE",org,id)==1;
        if(i.active && !wasActive) capacity(org,1);
        if(edit) db.update("UPDATE academy_student SET name=?,email=?,account_id=?,batch_id=?,coach_id=?,active=? WHERE organization_id=? AND id=?",i.name.trim(),email,i.accountId,i.batchId,i.coachId,i.active,org,id);
        else db.update("INSERT INTO academy_student(id,organization_id,name,email,account_id,batch_id,coach_id,active) VALUES(?,?,?,?,?,?,?,?)",id,org,i.name.trim(),email,i.accountId,i.batchId,i.coachId,i.active);
        return Map.of("id",id);
    }
    @PostMapping("/{org}/students/import")
    public Map<String,Object> importStudents(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody ImportInput input) {
        admin(bearer,org); lock(org);
        input.students.forEach(i -> saveStudent(org,UUID.randomUUID(),i,false));
        return Map.of("imported",input.students.size());
    }
    public record StudentBatchInput(UUID batchId) {}
    @PutMapping("/{org}/students/{id}/batch")
    public void moveStudentBatch(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id,@RequestBody StudentBatchInput i) {
        Access a=trainer(bearer,org);lock(org);student(org,id,a);
        if(i.batchId!=null)require(count("SELECT COUNT(*) FROM academy_batch WHERE organization_id=? AND id=?"+(a.admin()?"":" AND coach_id=?"),a.admin()?new Object[]{org,i.batchId}:new Object[]{org,i.batchId,a.member})==1,HttpStatus.FORBIDDEN,"Choose a batch assigned to you in this academy");
        db.update("UPDATE academy_student SET batch_id=? WHERE organization_id=? AND id=?",i.batchId,org,id);
    }
    @PostMapping("/{org}/batches")
    public Map<String,Object> addBatch(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody BatchInput i) {
        Access a=trainer(bearer,org);lock(org);UUID assigned=a.admin()?i.coachId:a.member;coach(org,assigned);UUID id=UUID.randomUUID();
        db.update("INSERT INTO academy_batch(id,organization_id,name,level,schedule,coach_id) VALUES(?,?,?,?,?,?)",id,org,i.name,i.level,i.schedule,assigned);return Map.of("id",id);
    }
    @PutMapping("/{org}/batches/{id}")
    public void editBatch(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id,@Valid @RequestBody BatchInput i) {
        Access a=trainer(bearer,org);lock(org);UUID assigned=a.admin()?i.coachId:a.member;coach(org,assigned);
        if(!a.admin())require(count("SELECT COUNT(*) FROM academy_batch WHERE organization_id=? AND id=? AND coach_id=?",org,id,a.member)==1,HttpStatus.FORBIDDEN,"You can edit only your assigned batches");
        require(db.update("UPDATE academy_batch SET name=?,level=?,schedule=?,coach_id=? WHERE organization_id=? AND id=?",i.name,i.level,i.schedule,assigned,org,id)==1,HttpStatus.NOT_FOUND,"Batch not found");
    }
    @PostMapping("/{org}/members")
    public void member(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody MemberInput i) {
        Access a=admin(bearer,org); lock(org);
        var accounts=rows("SELECT id FROM player_account WHERE LOWER(email)=? AND verified=TRUE",i.email.trim().toLowerCase(Locale.ROOT));
        require(accounts.size()==1,HttpStatus.BAD_REQUEST,"Ask this person to register and verify their ChessVerse account first");
        UUID accountId=uuid(accounts.getFirst().get("id"));
        require(!a.account.equals(accountId) || (i.role.equals("ORGANIZATION_ADMIN") && i.active),HttpStatus.CONFLICT,"You cannot remove your own administrator access");
        if(i.active && "COACH".equals(i.role)) AcademyCoachLimits.adding(db,org,accountId);
        var old=rows("SELECT * FROM academy_member WHERE organization_id=? AND account_id=?",org,accountId);
        if(!old.isEmpty()) {
            UUID id=uuid(old.getFirst().get("id"));
            if(!i.role.equals("COACH") || !i.active) require(count("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND coach_id=?",org,id)+count("SELECT COUNT(*) FROM academy_batch WHERE organization_id=? AND coach_id=?",org,id)==0,HttpStatus.CONFLICT,"Reassign this coach's students and batches first");
            if(!i.role.equals(old.getFirst().get("role"))) {
                require(count("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND account_id=?",org,accountId)==0,HttpStatus.CONFLICT,"Unlink the student account before changing its role");
                db.update("DELETE FROM academy_parent_link WHERE organization_id=? AND member_id=?",org,id);
            }
            db.update("UPDATE academy_member SET name=?,role=?,active=? WHERE organization_id=? AND id=?",i.name,i.role,i.active,org,id);
        } else db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role,active) VALUES(?,?,?,?,?,?)",UUID.randomUUID(),org,accountId,i.name,i.role,i.active);
    }
    @PostMapping("/{org}/parent-links")
    public void parent(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody ParentInput i) {
        Access a=admin(bearer,org); student(org,i.studentId,a);
        require(count("SELECT COUNT(*) FROM academy_member WHERE organization_id=? AND id=? AND role='PARENT' AND active=TRUE",org,i.memberId)==1,HttpStatus.BAD_REQUEST,"Active parent membership required");
        if(count("SELECT COUNT(*) FROM academy_parent_link WHERE organization_id=? AND member_id=? AND student_id=?",org,i.memberId,i.studentId)==0)
            db.update("INSERT INTO academy_parent_link(organization_id,member_id,student_id) VALUES(?,?,?)",org,i.memberId,i.studentId);
    }
    @DeleteMapping("/{org}/parent-links/{member}/{student}")
    public void removeParent(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID member,@PathVariable UUID student) {
        admin(bearer,org); db.update("DELETE FROM academy_parent_link WHERE organization_id=? AND member_id=? AND student_id=?",org,member,student);
    }
    @PostMapping("/{org}/assignments")
    public void assign(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody AssignmentInput i) {
        Access a=trainer(bearer,org); require(!i.dueDate.isBefore(LocalDate.now()),HttpStatus.BAD_REQUEST,"Due date must be today or later");
        if(i.puzzleId!=null) require(i.kind.equals("PUZZLES") && Integer.parseInt(i.puzzleId.substring(i.puzzleId.indexOf('-')+1))>=1 && Integer.parseInt(i.puzzleId.substring(i.puzzleId.indexOf('-')+1))<=200,HttpStatus.BAD_REQUEST,"Choose a puzzle from 1 to 200");
        if(i.positionFen!=null || i.bestMove!=null) {
            require(i.kind.equals("POSITIONS") && i.positionFen!=null && i.bestMove!=null,HttpStatus.BAD_REQUEST,"Position practice needs FEN and best move");
            require(validTrainingFen(i.positionFen),HttpStatus.BAD_REQUEST,"Use a valid FEN with both kings");
        }
        for(UUID id:new HashSet<>(i.studentIds)) {
            require(Boolean.TRUE.equals(student(org,id,a).get("active")),HttpStatus.CONFLICT,"Student is inactive");
            db.update("INSERT INTO academy_assignment(id,organization_id,student_id,created_by,title,kind,instructions,due_date,puzzle_id,position_fen,best_move) VALUES(?,?,?,?,?,?,?,?,?,?,?)",UUID.randomUUID(),org,id,a.member,i.title,i.kind,i.instructions,i.dueDate,i.puzzleId,i.positionFen,i.bestMove);
        }
    }
    private boolean validTrainingFen(String fen) {
        String[] fields=fen.trim().split("\\s+"); if(fields.length!=6 || !fields[1].matches("[wb]")) return false;
        String[] ranks=fields[0].split("/");if(ranks.length!=8)return false;
        for(String rank:ranks){int squares=0;for(char c:rank.toCharArray()){if(c>='1'&&c<='8')squares+=c-'0';else if("prnbqkPRNBQK".indexOf(c)>=0)squares++;else return false;}if(squares!=8)return false;}
        return fields[0].chars().filter(c->c=='K').count()==1 && fields[0].chars().filter(c->c=='k').count()==1 && fields[2].matches("-|[KQkq]+") && fields[3].matches("-|[a-h][36]") && fields[4].matches("[0-9]{1,5}") && fields[5].matches("[1-9][0-9]{0,4}");
    }
    @PostMapping("/{org}/assignments/{id}/results")
    public void assignmentResult(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id,@Valid @RequestBody AssignmentResultInput i) {
        Access a=access(bearer,org); require(a.role.equals("STUDENT"),HttpStatus.FORBIDDEN,"Only the assigned student can submit practice");
        var found=rows("SELECT * FROM academy_assignment WHERE organization_id=? AND id=? FOR UPDATE",org,id);
        require(!found.isEmpty(),HttpStatus.NOT_FOUND,"Assignment not found"); var assignment=found.getFirst();
        UUID studentId=uuid(assignment.get("student_id"));student(org,studentId,a);
        var duplicate=rows("SELECT organization_id,assignment_id,student_id FROM academy_assignment_result WHERE id=?",i.id);
        if(!duplicate.isEmpty()){var old=duplicate.getFirst();require(org.equals(old.get("organization_id"))&&id.equals(old.get("assignment_id"))&&studentId.equals(old.get("student_id")),HttpStatus.CONFLICT,"Result identifier already used");return;}
        require(assignment.get("completed_at")==null,HttpStatus.CONFLICT,"Assignment already completed");
        if(List.of("OPENINGS","MASTER_GAMES").contains(assignment.get("kind")))require(!i.notes.isBlank(),HttpStatus.BAD_REQUEST,"Add your study notes for coach review");
        db.update("INSERT INTO academy_assignment_result(id,organization_id,assignment_id,student_id,attempts,solved,notes) VALUES(?,?,?,?,?,?,?)",i.id,org,id,studentId,i.attempts,i.solved,i.notes);
        if(i.solved)db.update("UPDATE academy_assignment SET completed_at=CURRENT_TIMESTAMP WHERE organization_id=? AND id=?",org,id);
    }
    @PostMapping("/{org}/assignments/{id}/complete")
    public void complete(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id) {
        Access a=access(bearer,org); require(a.trainer() || a.role.equals("STUDENT"),HttpStatus.FORBIDDEN,"Parents have read-only access");
        var assignment=rows("SELECT * FROM academy_assignment WHERE organization_id=? AND id=?",org,id);
        require(!assignment.isEmpty(),HttpStatus.NOT_FOUND,"Assignment not found"); student(org,uuid(assignment.getFirst().get("student_id")),a);
        db.update("UPDATE academy_assignment SET completed_at=CURRENT_TIMESTAMP WHERE organization_id=? AND id=? AND completed_at IS NULL",org,id);
    }
    @PostMapping("/{org}/observations")
    public void observe(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody ObservationInput i) {
        Access a=trainer(bearer,org); student(org,i.studentId,a);
        require(i.retryFailures<=i.retryAttempts,HttpStatus.BAD_REQUEST,"Retry failures cannot exceed attempts");
        db.update("INSERT INTO academy_observation(id,organization_id,student_id,recorded_by,practiced_on,rating,accuracy,minutes,tactics,blunders,opening_errors,middle_errors,endgame_errors,retry_attempts,retry_failures,notes) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",UUID.randomUUID(),org,i.studentId,a.member,i.practicedOn,i.rating,i.accuracy,i.minutes,i.tactics,i.blunders,i.openingErrors,i.middleErrors,i.endgameErrors,i.retryAttempts,i.retryFailures,i.notes);
    }
    @GetMapping("/{org}/shareable-games")
    public List<Map<String,Object>> shareableGames(@RequestHeader("Authorization") String bearer,@PathVariable UUID org) {
        Access a=access(bearer,org);
        require(a.role.equals("STUDENT") && students(org,a).size()==1,HttpStatus.FORBIDDEN,"Linked student membership required");
        return rows("SELECT game_id,draft,created_at FROM computer_game_history WHERE player_id=? ORDER BY created_at DESC LIMIT 100",a.account)
            .stream().map(row -> {
                var state=json.readTree(row.get("draft").toString()).path("state");
                Map<String,Object> game=new LinkedHashMap<>(); game.put("id",row.get("game_id"));
                game.put("name",state.path("whiteName").asText("White")+" vs "+state.path("blackName").asText("Black")+" · "+state.path("result").asText("Finished")+" · "+row.get("created_at").toString().substring(0,10));
                return game;
            }).toList();
    }
    @PostMapping("/{org}/games/{gameId}/share")
    public void shareGame(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable String gameId) {
        Access a=access(bearer,org); require(a.role.equals("STUDENT"),HttpStatus.FORBIDDEN,"Only a student can share their own game");
        var own=students(org,a); require(own.size()==1,HttpStatus.CONFLICT,"Student account is not linked");
        var history=rows("SELECT draft FROM computer_game_history WHERE player_id=? AND game_id=?",a.account,gameId);
        require(!history.isEmpty(),HttpStatus.NOT_FOUND,"Your saved game was not found");
        UUID student=uuid(own.getFirst().get("id"));
        if(count("SELECT COUNT(*) FROM academy_game WHERE organization_id=? AND student_id=? AND game_id=?",org,student,gameId)==0)
            db.update("INSERT INTO academy_game(id,organization_id,student_id,game_id,draft) VALUES(?,?,?,?,?)",UUID.randomUUID(),org,student,gameId,history.getFirst().get("draft"));
    }
    @GetMapping("/{org}/games/{id}")
    public Object game(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id) {
        Access a=access(bearer,org); var games=rows("SELECT * FROM academy_game WHERE organization_id=? AND id=?",org,id);
        require(!games.isEmpty(),HttpStatus.NOT_FOUND,"Game not found"); var game=games.getFirst(); student(org,uuid(game.get("student_id")),a);
        return json.readTree(game.get("draft").toString());
    }
    @PostMapping("/{org}/reports")
    public void report(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody ReportInput i) {
        Access a=trainer(bearer,org); var s=student(org,i.studentId,a);
        LocalDate end=LocalDate.now(),start=i.period.equals("WEEKLY")?end.minusDays(6):end.minusMonths(1).plusDays(1);
        var observations=rows("SELECT * FROM academy_observation WHERE organization_id=? AND student_id=? AND practiced_on BETWEEN ? AND ? ORDER BY practiced_on,created_at",org,i.studentId,start,end);
        var assignments=rows("SELECT title,due_date,completed_at FROM academy_assignment WHERE organization_id=? AND student_id=? AND due_date BETWEEN ? AND ?",org,i.studentId,start,end);
        var appDaily=activityDaily(org,List.of(i.studentId),start,end);
        var results=rows("SELECT r.*,a.title,a.kind FROM academy_assignment_result r JOIN academy_assignment a ON a.organization_id=r.organization_id AND a.id=r.assignment_id WHERE r.organization_id=? AND r.student_id=? AND r.created_at>=? AND r.created_at<? ORDER BY r.created_at",org,i.studentId,java.sql.Timestamp.valueOf(start.atStartOfDay()),java.sql.Timestamp.valueOf(end.plusDays(1).atStartOfDay()));
        String summary=json.writeValueAsString(Map.of("student",s.get("name"),"from",start.toString(),"to",end.toString(),"source","Coach observations and separately labelled app-reported practice","observations",observations,"assignments",assignments,"appDaily",appDaily,"assignmentResults",results));
        db.update("INSERT INTO academy_report(id,organization_id,student_id,created_by,period,summary) VALUES(?,?,?,?,?,?)",UUID.randomUUID(),org,i.studentId,a.member,i.period,summary);
    }
    @PostMapping("/{org}/students/{id}/guidance")
    public AcademyGuidanceService.Guidance guidance(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@PathVariable UUID id) {
        Access a=trainer(bearer,org); student(org,id,a); lock(org);
        LocalDate today=LocalDate.now(java.time.ZoneOffset.UTC);
        var usage=rows("SELECT used_count FROM academy_guidance_usage WHERE organization_id=? AND member_id=? AND usage_date=?",org,a.member,today);
        int used=usage.isEmpty()?0:((Number)usage.getFirst().get("used_count")).intValue();
        require(used<10,HttpStatus.TOO_MANY_REQUESTS,"Daily guidance limit reached. Your training insights remain available.");
        if(usage.isEmpty()) db.update("INSERT INTO academy_guidance_usage(organization_id,member_id,usage_date,used_count) VALUES(?,?,?,1)",org,a.member,today);
        else db.update("UPDATE academy_guidance_usage SET used_count=used_count+1 WHERE organization_id=? AND member_id=? AND usage_date=?",org,a.member,today);
        return guidance.recommend(rows("SELECT accuracy,minutes,tactics,blunders,opening_errors,middle_errors,endgame_errors,retry_attempts,retry_failures FROM academy_observation WHERE organization_id=? AND student_id=? AND practiced_on>=? ORDER BY practiced_on DESC LIMIT 60",org,id,today.minusDays(29)));
    }
    @PutMapping("/{org}/branding")
    public void brand(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody BrandingInput i) {
        admin(bearer,org); db.update("UPDATE academy_organization SET name=?,color=?,logo_url=?,white_label=? WHERE id=?",i.name,i.color,i.logoUrl,i.whiteLabel,org);
    }
    @PostMapping("/{org}/seat-requests")
    public void seats(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody SeatInput i) {
        admin(bearer,org); db.update("INSERT INTO academy_seat_request(id,organization_id,seats) VALUES(?,?,?)",UUID.randomUUID(),org,i.seats);
    }
    @PostMapping("/{org}/support")
    public void support(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody SupportInput i) {
        admin(bearer,org); db.update("INSERT INTO academy_support(id,organization_id,subject) VALUES(?,?,?)",UUID.randomUUID(),org,i.subject);
    }
    @GetMapping("/platform")
    public Map<String,Object> platform(@RequestHeader("Authorization") String bearer) {
        superAdmin(bearer);
        return Map.of("organizations",rows("SELECT o.*,(SELECT COUNT(*) FROM academy_student s WHERE s.organization_id=o.id AND s.active=TRUE) AS students,(SELECT COUNT(*) FROM academy_game g WHERE g.organization_id=o.id) AS games FROM academy_organization o ORDER BY o.name"),
            "support",rows("SELECT * FROM academy_support ORDER BY created_at DESC"),"seatRequests",rows("SELECT * FROM academy_seat_request ORDER BY created_at DESC"),
            "subscriptionRequests",rows("SELECT * FROM academy_subscription_request ORDER BY created_at DESC"));
    }
    @PostMapping("/platform/organizations")
    public Map<String,Object> createOrganization(@RequestHeader("Authorization") String bearer,@Valid @RequestBody OrganizationInput i) {
        superAdmin(bearer); account(i.adminAccountId); UUID org=UUID.randomUUID();
        db.update("INSERT INTO academy_organization(id,name,kind) VALUES(?,?,?)",org,i.name,i.kind);
        String name=db.queryForObject("SELECT display_name FROM player_account WHERE id=?",String.class,i.adminAccountId);
        db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,?,'ORGANIZATION_ADMIN')",UUID.randomUUID(),org,i.adminAccountId,name);
        return Map.of("id",org);
    }
    @PutMapping("/platform/organizations/{org}/license")
    public void license(@RequestHeader("Authorization") String bearer,@PathVariable UUID org,@Valid @RequestBody LicenseInput i) {
        superAdmin(bearer); organization(org); lock(org);
        require(i.seats>=count("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND active=TRUE",org),HttpStatus.CONFLICT,"Seat limit cannot be below active student count");
        db.update("UPDATE academy_organization SET plan=?,seats=?,renewal_date=?,status=?,feature_flags=? WHERE id=?",i.plan,i.seats,i.renewalDate,i.status,i.featureFlags,org);
    }
    @PostMapping("/platform/support/{id}/close")
    public void closeSupport(@RequestHeader("Authorization") String bearer,@PathVariable UUID id) {
        superAdmin(bearer); require(db.update("UPDATE academy_support SET status='CLOSED' WHERE id=?",id)==1,HttpStatus.NOT_FOUND,"Request not found");
    }
    @PostMapping("/platform/seat-requests/{id}/approve")
    public void approveSeats(@RequestHeader("Authorization") String bearer,@PathVariable UUID id) {
        superAdmin(bearer); var requests=rows("SELECT * FROM academy_seat_request WHERE id=? FOR UPDATE",id);
        require(!requests.isEmpty(),HttpStatus.NOT_FOUND,"Request not found"); var r=requests.getFirst();
        require(r.get("status").equals("PENDING"),HttpStatus.CONFLICT,"Request already processed");
        db.update("UPDATE academy_organization SET seats=seats+? WHERE id=?",r.get("seats"),r.get("organization_id"));
        db.update("UPDATE academy_seat_request SET status='APPROVED' WHERE id=?",id);
    }
    @PostMapping("/platform/subscription-requests/{id}/{decision}")
    public void reviewSubscription(@RequestHeader("Authorization")String bearer,@PathVariable UUID id,@PathVariable @Pattern(regexp="approve|reject") String decision){
        UUID reviewer=auth.requireBearer(bearer).id();superAdmin(bearer);
        var requests=rows("SELECT * FROM academy_subscription_request WHERE id=? FOR UPDATE",id);require(!requests.isEmpty(),HttpStatus.NOT_FOUND,"Request not found");var r=requests.getFirst();
        require("PENDING".equals(r.get("status")),HttpStatus.CONFLICT,"Request already reviewed");
        String status="approve".equals(decision)?"APPROVED":"REJECTED";db.update("UPDATE academy_subscription_request SET status=?,reviewed_by=?,reviewed_at=CURRENT_TIMESTAMP WHERE id=?",status,reviewer,id);
        if("APPROVED".equals(status)&&!LocalDate.parse(r.get("effective_on").toString()).isAfter(LocalDate.now()))new AcademySubscriptionProcessor(db).apply(id);
    }
}

package com.epitomehub.chessverse.academy;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/academy")
@Transactional
public class AcademyInvitationController {
    private static final SecureRandom RANDOM = new SecureRandom();
    private final JdbcTemplate db;
    private final PlayerAuthenticationService auth;
    private final AcademyInvitationMailService mail;

    public AcademyInvitationController(JdbcTemplate db, PlayerAuthenticationService auth) {
        this(db, auth, null);
    }

    @Autowired
    public AcademyInvitationController(JdbcTemplate db, PlayerAuthenticationService auth, AcademyInvitationMailService mail) {
        this.db = db;
        this.auth = auth;
        this.mail = mail;
    }

    public record InviteInput(
            @NotBlank @Email @Size(max = 254) String email,
            @NotNull @Pattern(regexp = "COACH|STUDENT|PARENT") String role) {}

    public record AcceptInput(@NotBlank @Size(min = 32, max = 200) String token) {}

    @GetMapping("/{org}/invitations")
    public List<Map<String, Object>> invitations(
            @RequestHeader("Authorization") String bearer, @PathVariable UUID org) {
        admin(bearer, org);
        expire(org);
        return rows("SELECT id,email,role,status,expires_at,created_at,accepted_at,email_sent_at,reminder_sent_at FROM academy_invitation WHERE organization_id=? ORDER BY created_at DESC", org);
    }

    @PostMapping("/{org}/invitations")
    public Map<String, Object> invite(
            @RequestHeader("Authorization") String bearer,
            @PathVariable UUID org,
            @Valid @RequestBody InviteInput input) {
        UUID inviter = admin(bearer, org);
        String email = input.email().trim().toLowerCase(Locale.ROOT);
        expire(org);
        require(count("SELECT COUNT(*) FROM academy_member m JOIN player_account p ON p.id=m.account_id WHERE m.organization_id=? AND LOWER(p.email)=?", org, email) == 0,
                HttpStatus.CONFLICT, "This account is already an academy member.");
        require(count("SELECT COUNT(*) FROM academy_invitation WHERE organization_id=? AND email=? AND status='PENDING'", org, email) == 0,
                HttpStatus.CONFLICT, "An active invitation already exists for this email.");
        String token = token();
        UUID id = UUID.randomUUID();
        Instant expires = Instant.now().plus(7, ChronoUnit.DAYS);
        db.update("INSERT INTO academy_invitation(id,organization_id,email,role,token_hash,invited_by,expires_at) VALUES(?,?,?,?,?,?,?)",
                id, org, email, input.role(), hash(token), inviter, Timestamp.from(expires));
        String academy = db.queryForObject("SELECT name FROM academy_organization WHERE id=?", String.class, org);
        boolean emailSent = mail != null && mail.sendInvitation(email, academy, input.role(), token, false);
        if (emailSent) db.update("UPDATE academy_invitation SET email_sent_at=CURRENT_TIMESTAMP WHERE id=?", id);
        return Map.of("id", id, "email", email, "role", input.role(), "token", token,
                "inviteUrl", "/academy/?invite=" + token, "expiresAt", expires.toString(), "emailSent", emailSent);
    }

    @PostMapping("/{org}/invitations/{id}/remind")
    public Map<String, Object> remind(@RequestHeader("Authorization") String bearer,
            @PathVariable UUID org, @PathVariable UUID id) {
        admin(bearer, org); expire(org);
        Map<String, Object> invitation = rows("SELECT i.*,o.name academy_name FROM academy_invitation i JOIN academy_organization o ON o.id=i.organization_id WHERE i.id=? AND i.organization_id=? AND i.status='PENDING'", id, org)
                .stream().findFirst().orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Active invitation not found."));
        require(invitation.get("reminder_sent_at") == null, HttpStatus.TOO_MANY_REQUESTS,
                "A reminder was already sent for this invitation.");
        // A new one-time link replaces the old hash so copied stale links cannot be reused.
        String token = token();
        boolean sent = mail != null && mail.sendInvitation(invitation.get("email").toString(),
                invitation.get("academy_name").toString(), invitation.get("role").toString(), token, true);
        require(sent, HttpStatus.SERVICE_UNAVAILABLE, "Invitation email is temporarily unavailable. Copy the existing link instead.");
        db.update("UPDATE academy_invitation SET token_hash=?,reminder_sent_at=CURRENT_TIMESTAMP,expires_at=? WHERE id=?",
                hash(token), Timestamp.from(Instant.now().plus(7, ChronoUnit.DAYS)), id);
        return Map.of("sent", true);
    }

    @DeleteMapping("/{org}/invitations/{id}")
    public void revoke(@RequestHeader("Authorization") String bearer, @PathVariable UUID org, @PathVariable UUID id) {
        admin(bearer, org);
        require(db.update("UPDATE academy_invitation SET status='REVOKED' WHERE id=? AND organization_id=? AND status='PENDING'", id, org) == 1,
                HttpStatus.NOT_FOUND, "Active invitation not found.");
    }

    @PostMapping("/invitations/accept")
    public Map<String, Object> accept(
            @RequestHeader("Authorization") String bearer, @Valid @RequestBody AcceptInput input) {
        UUID account = auth.requireBearer(bearer).id();
        Map<String, Object> player = rows("SELECT id,email,display_name,verified FROM player_account WHERE id=? FOR UPDATE", account)
                .stream().findFirst().orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account not found."));
        require(Boolean.TRUE.equals(player.get("verified")), HttpStatus.FORBIDDEN, "Verify your email before accepting an academy invitation.");
        List<Map<String, Object>> found = rows("SELECT * FROM academy_invitation WHERE token_hash=? FOR UPDATE", hash(input.token()));
        require(!found.isEmpty(), HttpStatus.NOT_FOUND, "Invitation not found.");
        Map<String, Object> invitation = found.getFirst();
        UUID org = UUID.fromString(invitation.get("organization_id").toString());
        if (Instant.parse(timestamp(invitation.get("expires_at"))).isBefore(Instant.now())) {
            db.update("UPDATE academy_invitation SET status='EXPIRED' WHERE id=? AND status='PENDING'", invitation.get("id"));
        }
        require("PENDING".equals(invitation.get("status")) && Instant.parse(timestamp(invitation.get("expires_at"))).isAfter(Instant.now()),
                HttpStatus.GONE, "Invitation has expired or is no longer active.");
        require(invitation.get("email").toString().equalsIgnoreCase(player.get("email").toString()),
                HttpStatus.FORBIDDEN, "Sign in with the email address that received this invitation.");
        Map<String, Object> organization = rows("SELECT status,renewal_date FROM academy_organization WHERE id=? FOR UPDATE", org)
                .stream().findFirst().orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Academy not found."));
        require(!"SUSPENDED".equals(organization.get("status")), HttpStatus.FORBIDDEN, "This academy is suspended.");
        require(activeLicense(organization.get("renewal_date")), HttpStatus.PAYMENT_REQUIRED,
                "This academy plan has expired. Ask the administrator to renew it.");
        require(count("SELECT COUNT(*) FROM academy_member WHERE organization_id=? AND account_id=?", org, account) == 0,
                HttpStatus.CONFLICT, "This account is already an academy member.");
        String role = invitation.get("role").toString();
        UUID member = UUID.randomUUID();
        db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,?,?)",
                member, org, account, player.get("display_name"), role);
        if ("STUDENT".equals(role)) {
            int seats = db.queryForObject("SELECT seats FROM academy_organization WHERE id=?", Integer.class, org);
            long used = count("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND active=TRUE", org);
            require(used < seats, HttpStatus.CONFLICT, "Academy seat limit reached. Ask the administrator to add seats.");
            db.update("INSERT INTO academy_student(id,organization_id,name,email,account_id,active) VALUES(?,?,?,?,?,TRUE)",
                    UUID.randomUUID(), org, player.get("display_name"), player.get("email"), account);
        }
        db.update("UPDATE academy_invitation SET status='ACCEPTED',accepted_by=?,accepted_at=CURRENT_TIMESTAMP WHERE id=?",
                account, invitation.get("id"));
        return Map.of("accepted", true, "organizationId", org, "role", role);
    }

    private UUID admin(String bearer, UUID org) {
        UUID account = auth.requireBearer(bearer).id();
        List<Map<String, Object>> rows = rows("SELECT m.id,o.status,o.renewal_date FROM academy_member m JOIN academy_organization o ON o.id=m.organization_id WHERE m.organization_id=? AND m.account_id=? AND m.role='ORGANIZATION_ADMIN' AND m.active=TRUE", org, account);
        require(!rows.isEmpty(), HttpStatus.FORBIDDEN, "Organization Admin required.");
        require(!"SUSPENDED".equals(rows.getFirst().get("status")), HttpStatus.FORBIDDEN, "Organization is suspended.");
        require(activeLicense(rows.getFirst().get("renewal_date")), HttpStatus.PAYMENT_REQUIRED,
                "Your academy plan has expired. Renew it before inviting members.");
        return UUID.fromString(rows.getFirst().get("id").toString());
    }

    private boolean activeLicense(Object renewalDate) {
        return renewalDate == null || LocalDate.parse(renewalDate.toString()).isAfter(LocalDate.now());
    }

    private void expire(UUID org) {
        db.update("UPDATE academy_invitation SET status='EXPIRED' WHERE organization_id=? AND status='PENDING' AND expires_at<=CURRENT_TIMESTAMP", org);
    }

    private long count(String sql, Object... args) { return db.queryForObject(sql, Long.class, args); }
    private void require(boolean ok, HttpStatus status, String message) { if (!ok) throw new ResponseStatusException(status, message); }
    private List<Map<String, Object>> rows(String sql, Object... args) {
        return db.query(sql, (rs, n) -> {
            Map<String, Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= rs.getMetaData().getColumnCount(); i++) row.put(rs.getMetaData().getColumnLabel(i).toLowerCase(Locale.ROOT), rs.getObject(i));
            return row;
        }, args);
    }
    private String token() { byte[] bytes = new byte[32]; RANDOM.nextBytes(bytes); return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes); }
    private String hash(String token) {
        try { return java.util.HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8))); }
        catch (java.security.NoSuchAlgorithmException impossible) { throw new IllegalStateException(impossible); }
    }
    private String timestamp(Object value) {
        if (value instanceof java.time.OffsetDateTime o) return o.toInstant().toString();
        if (value instanceof Timestamp t) return t.toInstant().toString();
        return value.toString();
    }
}

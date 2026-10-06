package com.epitomehub.chessverse.academy;

import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

final class AcademyCoachLimits {
    static int limit(String plan) {
        if (plan == null) return Integer.MAX_VALUE;
        return switch (plan) {
            case "Free trial", "Starter", "Starter Academy", "Starter — one-time test offer" -> 1;
            case "Growth", "Growth Academy" -> 5;
            case "School", "Elite Academy" -> 15;
            default -> Integer.MAX_VALUE;
        };
    }
    static void adding(JdbcTemplate db, UUID org, UUID account) {
        String plan=db.queryForObject("SELECT plan FROM academy_organization WHERE id=? FOR UPDATE",String.class,org);
        int used=db.queryForObject("SELECT COUNT(*) FROM academy_member WHERE organization_id=? AND role='COACH' AND active=TRUE AND account_id<>?",Integer.class,org,account);
        if(used>=limit(plan))throw new ResponseStatusException(HttpStatus.CONFLICT,"Your plan's coach limit is reached. Choose a larger plan or deactivate a coach.");
    }
}

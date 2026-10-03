package com.epitomehub.chessverse.online;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
class DailyPushScheduler {
    static final ZoneId ZONE = ZoneId.of("Asia/Kolkata");
    private final JdbcTemplate jdbc;
    private final PlayerNotificationService notifications;

    DailyPushScheduler(JdbcTemplate jdbc, PlayerNotificationService notifications) {
        this.jdbc = jdbc;
        this.notifications = notifications;
    }

    @Scheduled(cron = "0 30 9 * * *", zone = "Asia/Kolkata")
    void dailyPuzzle() {
        for (UUID playerId : pushPlayers()) {
            notifications.createOnce(playerId, "DAILY_PUZZLE", key("puzzle"),
                    "Daily Puzzle", "Today's chess challenge is ready. Solve it and build your streak!",
                    "DAILY_PUZZLE", null);
        }
    }

    @Scheduled(cron = "0 30 18 * * *", zone = "Asia/Kolkata")
    void streakReminder() {
        jdbc.query("""
                select d.player_id, p.daily_streak
                from push_notification_device d
                join player_cloud_progress p on p.player_id=d.player_id
                where d.enabled=true and p.daily_streak>0
                group by d.player_id,p.daily_streak
                """, (rs, row) -> new StreakPlayer(
                rs.getObject(1, UUID.class), rs.getInt(2))).stream()
                .filter(player -> !hasPlayedToday(player.id()))
                .forEach(player -> sendStreak(player.id(), player.streak()));
    }

    @Scheduled(cron = "0 30 20 * * *", zone = "Asia/Kolkata")
    void beginnerReminder() {
        jdbc.queryForList("""
                select distinct d.player_id from push_notification_device d
                left join player_cloud_progress p on p.player_id=d.player_id
                where d.enabled=true and coalesce(p.daily_streak,0)=0
                """, UUID.class).stream().filter(playerId -> !hasPlayedToday(playerId))
                .forEach(playerId -> notifications.createOnce(playerId, "DAILY_GAME_REMINDER",
                        key("beginner"), "Your board is waiting",
                        "Play one quick game today and start your first streak!",
                        "DAILY_GAME_REMINDER", null));
    }

    @Scheduled(cron = "0 45 20 * * *", zone = "Asia/Kolkata")
    void weeklyCongratulations() {
        jdbc.queryForList("""
                select distinct d.player_id from push_notification_device d
                join player_cloud_progress p on p.player_id=d.player_id
                where d.enabled=true and p.daily_streak>0 and mod(p.daily_streak,7)=0
                  and (p.last_daily_completed_at at time zone 'Asia/Kolkata')::date=current_date
                """, UUID.class).forEach(playerId -> notifications.createOnce(
                playerId, "STREAK_MILESTONE", key("week"), "Congratulations, champ!",
                "You completed a 7-day streak. Keep the momentum going tomorrow!",
                "STREAK_MILESTONE", null));
    }

    private List<UUID> pushPlayers() {
        return jdbc.queryForList("select distinct player_id from push_notification_device where enabled=true", UUID.class);
    }

    boolean hasPlayedToday(UUID playerId) {
        Boolean played = jdbc.queryForObject("""
                select exists(
                  select 1 from player_cloud_progress p where p.player_id=?
                    and (p.last_daily_completed_at at time zone 'Asia/Kolkata')::date=current_date
                  union all select 1 from computer_game_history g where g.player_id=?
                    and (g.created_at at time zone 'Asia/Kolkata')::date=current_date
                  union all select 1 from online_match m where (m.white_player_id=? or m.black_player_id=?)
                    and m.status='FINISHED'
                    and (m.finished_at at time zone 'Asia/Kolkata')::date=current_date
                  union all select 1 from puzzle_sprint_result s where s.player_id=?
                    and (s.played_at at time zone 'Asia/Kolkata')::date=current_date
                )
                """, Boolean.class, playerId, playerId, playerId, playerId, playerId);
        return Boolean.TRUE.equals(played);
    }

    private void sendStreak(UUID playerId, int streak) {
        int day = Math.min(6, Math.max(1, streak));
        String[] titles = {"", "Your first streak is at risk!", "You're on a roll!",
                "You're a serious player!", "You crossed the halfway mark!",
                "Only two days to go!", "One step away from a full week!"};
        String[] bodies = {"", "Play today to reach your day-2 streak.",
                "Your 2-day streak is complete. Play with your AI Coach to reach day 3.",
                "Keep your 3-day streak alive. Open the board now!",
                "A 4-day streak is impressive. Keep your grandmaster consistency!",
                "Don't lose your 5-day streak. Play a quick match today!",
                "Complete today's match and reach a full-week streak tomorrow!"};
        notifications.createOnce(playerId, "STREAK_REMINDER", key("streak"),
                titles[day], bodies[day], "STREAK_REMINDER_DAY_" + day, null);
    }

    private String key(String category) { return LocalDate.now(ZONE) + ":" + category; }
    private record StreakPlayer(UUID id, int streak) {}
}

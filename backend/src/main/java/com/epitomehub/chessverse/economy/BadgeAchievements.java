package com.epitomehub.chessverse.economy;

import java.time.*;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Cosmetic milestones use synced learning progress; online wins are server adjudicated. */
@Service
class BadgeAchievements {
    static final Map<String,Integer> TARGETS = Map.of("academy-scout",1,"puzzle-hunter",25,
            "tactical-eye",20,"opening-sage",5,"streak-flame",7,"checkmate-crown",10);
    private final JdbcTemplate db;
    BadgeAchievements(JdbcTemplate db) { this.db=db; }
    record Progress(int current,int target,boolean earned,boolean newlyEarned) {}

    Map<String,Progress> reconcile(UUID player) {
        var items=db.query("select id,slug from cosmetic_item where category='FRAME' and active=true",
                (rs,n)->Map.entry(rs.getString("slug"),rs.getObject("id",UUID.class)))
                .stream().filter(e->TARGETS.containsKey(e.getKey())).toList();
        if(items.isEmpty()) return Map.of();
        // All shop mutations use this lock; concurrent catalog/equip requests award once.
        db.queryForObject("select id from player_account where id=? for update",UUID.class,player);
        var puzzles=db.queryForList("select puzzle_id from player_completed_puzzle where player_id=?",String.class,player);
        var lessons=db.queryForList("select lesson_id from player_completed_academy_lesson where player_id=?",String.class,player);
        var days=db.queryForList("select challenge_id from player_completed_daily_challenge where player_id=?",String.class,player);
        int wins=db.queryForObject("""
            select count(*) from online_match where result_reason='CHECKMATE'
            and ((white_player_id=? and result='1-0') or (black_player_id=? and result='0-1'))
            """,Integer.class,player,player);
        var counts=Map.of("academy-scout",lessons.size(),"puzzle-hunter",puzzles.size(),
                "tactical-eye",(int)puzzles.stream().filter(id->id.startsWith("medium-")||id.startsWith("hard-")).count(),
                "opening-sage",(int)lessons.stream().filter(id->id.startsWith("opening-")).count(),
                "streak-flame",longestStreak(days,LocalDate.now(ZoneOffset.UTC)),"checkmate-crown",wins);
        Map<String,Progress> result=new HashMap<>();
        for(var item:items) {
            String slug=item.getKey(); UUID id=item.getValue(); int target=TARGETS.get(slug);
            boolean earned=exists("player_badge_achievement",player,id), fresh=false;
            if(!earned && counts.get(slug)>=target) {
                db.update("insert into player_badge_achievement(player_id,item_id,earned_at) values(?,?,current_timestamp)",player,id);
                if(!exists("player_cosmetic_inventory",player,id))
                    db.update("insert into player_cosmetic_inventory(player_id,item_id,acquired_at) values(?,?,current_timestamp)",player,id);
                earned=true; fresh=true;
            }
            result.put(slug,new Progress(Math.min(target,counts.get(slug)),target,earned,fresh));
        }
        return result;
    }
    private boolean exists(String table,UUID player,UUID item) {
        return db.queryForObject("select count(*) from "+table+" where player_id=? and item_id=?",Integer.class,player,item)>0;
    }
    static int longestStreak(Collection<String> ids,LocalDate today) {
        TreeSet<LocalDate> days=new TreeSet<>();
        for(String id:ids) {
            if(id==null || id.length()<10) continue;
            try { LocalDate d=LocalDate.parse(id.substring(0,10)); if(!d.isAfter(today)) days.add(d); }
            catch(java.time.format.DateTimeParseException ignored) {}
        }
        LocalDate previous=null; int run=0,best=0;
        for(LocalDate day:days) { run=previous!=null && previous.plusDays(1).equals(day)?run+1:1; best=Math.max(best,run); previous=day; }
        return best;
    }
}

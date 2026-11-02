package com.epitomehub.chessverse.online;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.github.bhlangonijr.chesslib.Board;
import com.github.bhlangonijr.chesslib.Piece;
import com.github.bhlangonijr.chesslib.Side;
import com.github.bhlangonijr.chesslib.move.Move;
import java.time.LocalDate;
import java.time.Instant;
import java.sql.Timestamp;
import java.time.ZoneId;
import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
class DailyPracticeCup {
    private final JdbcTemplate db;
    DailyPracticeCup(JdbcTemplate db) { this.db = db; }
    record Game(int number, int round, int white, int black, String moves, boolean started, String result) {}
    record Seat(int number, String name, UUID player) { public boolean isBot() { return player == null; } }
    record Cup(UUID id, int mySeat, List<Seat> seats, List<Game> games, long lobbySeconds) {}
    record Winner(String name, boolean bot, Instant finishedAt) {}
    record Position(Cup cup, int board, String fen, int ply, List<String> legal) {}

    // Serialise joins per day and joins/moves per cup: a human may take only
    // a bot seat that has not yet entered any board.
    Cup join(AuthenticatedPlayer player) {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Kolkata"));
        db.update("insert into practice_cup_day(day) values(?) on conflict do nothing", today);
        db.queryForObject("select day from practice_cup_day where day=? for update", LocalDate.class, today);
        List<UUID> existing = db.queryForList("""
                select c.id from practice_cup c join practice_cup_seat s on s.cup_id=c.id
                where c.day=? and s.player_id=? and exists (
                  select 1 from practice_cup_game g where g.cup_id=c.id
                    and s.seat in (g.white_seat,g.black_seat) and g.result='*')
                order by c.starts_at desc, c.id
                """, UUID.class, today, player.id());
        if (!existing.isEmpty()) return standings(existing.getFirst(), player.id());
        List<UUID> available = db.queryForList("""
                select c.id from practice_cup c where c.day=? and c.starts_at>CURRENT_TIMESTAMP and exists (
                  select 1 from practice_cup_seat s where s.cup_id=c.id and s.player_id is null
                  and not exists (select 1 from practice_cup_game g where g.cup_id=c.id
                    and g.started and s.seat in (g.white_seat,g.black_seat)))
                order by c.id
                """, UUID.class, today);
        for (UUID id : available) {
            lock(id);
            if (claim(id, player)) return snapshot(id, player.id());
        }
        UUID id = UUID.randomUUID();
        db.update("insert into practice_cup(id,day,starts_at) values(?,?,?)", id,today,Timestamp.from(Instant.now().plusSeconds(60)));
        var names = new ArrayList<>(List.of("Arjun","Nova","Mira","Ravi","Tara",
                "Amara","Leo","Kiran","Indigo","Niko","Isha","Sage"));
        Collections.shuffle(names);
        for (int i=0;i<6;i++) db.update("insert into practice_cup_seat values(?,?,?,?)",id,i,null,names.get(i));
        for (Game game : schedule()) db.update("""
                insert into practice_cup_game(cup_id,board_no,round_no,white_seat,black_seat)
                values(?,?,?,?,?)
                """,id,game.number(),game.round(),game.white(),game.black());
        claim(id,player);
        return snapshot(id,player.id());
    }

    static List<Game> schedule() {
        var seats = new ArrayList<>(List.of(0,1,2,3,4,5));
        var games = new ArrayList<Game>();
        for (int round=1;round<=5;round++) {
            for (int i=0;i<3;i++) {
                int a=seats.get(i), b=seats.get(5-i);
                games.add(new Game(games.size()+1,round,round%2==1?a:b,round%2==1?b:a,"",false,"*"));
            }
            seats.add(1,seats.removeLast());
        }
        return games;
    }

    private boolean claim(UUID id, AuthenticatedPlayer player) {
        return db.update("""
                update practice_cup_seat set player_id=?, name=? where cup_id=? and
                  exists(select 1 from practice_cup c where c.id=practice_cup_seat.cup_id and c.starts_at>?)
                  and seat=(
                  select s.seat from practice_cup_seat s where s.cup_id=? and s.player_id is null
                  and not exists(select 1 from practice_cup_game g where g.cup_id=s.cup_id
                    and g.started and s.seat in(g.white_seat,g.black_seat))
                  order by s.seat limit 1)
                """,player.id(), player.displayName(), id,Timestamp.from(Instant.now()),id)==1;
    }

    private void lock(UUID id) {
        if (db.queryForList("select id from practice_cup where id=? for update",UUID.class,id).isEmpty())
            throw new OnlineMatchException(HttpStatus.NOT_FOUND,"Tournament was not found.");
    }
    Cup standings(UUID id, UUID player) {
        lock(id);
        Cup cup = snapshot(id, player);
        if (advanceBotBoards(cup)) cup = snapshot(id, player);
        recordFinish(cup);
        return cup;
    }

    private Cup snapshot(UUID id, UUID player) {
        List<Seat> seats=db.query("select seat,name,player_id from practice_cup_seat where cup_id=? order by seat",
                (r,i)->new Seat(r.getInt(1),r.getString(2),r.getObject(3,UUID.class)),id);
        Seat mine=seats.stream().filter(s->player.equals(s.player())).findFirst().orElseThrow(
                ()->new OnlineMatchException(HttpStatus.FORBIDDEN,"Join this tournament first."));
        List<Game> games=db.query("select board_no,round_no,white_seat,black_seat,moves,started,result from practice_cup_game where cup_id=? order by board_no",
                (r,i)->new Game(r.getInt(1),r.getInt(2),r.getInt(3),r.getInt(4),r.getString(5),r.getBoolean(6),r.getString(7)),id);
        var starts=db.queryForObject("select starts_at from practice_cup where id=?",Timestamp.class,id);
        long remaining=Math.max(0,(starts.getTime()-System.currentTimeMillis()+999)/1000);
        if (remaining>0) {
            return new Cup(id,mine.number(),seats.stream().filter(s->!s.isBot()).toList(),List.of(),remaining);
        }
        return new Cup(id,mine.number(),seats,games,0);
    }

    Position enter(UUID id, int number, UUID player, String move, Integer ply) {
        lock(id);
        Cup cup=snapshot(id,player);
        if(cup.lobbySeconds()>0) throw new OnlineMatchException(HttpStatus.CONFLICT,"Registration is still open.");
        Game game=cup.games().stream().filter(g->g.number()==number).findFirst().orElseThrow(
                ()->new OnlineMatchException(HttpStatus.NOT_FOUND,"Board not found."));
        if(game.white()!=cup.mySeat() && game.black()!=cup.mySeat())
            throw new OnlineMatchException(HttpStatus.FORBIDDEN,"This is not your board.");
        Board board=new Board();
        var moves=new ArrayList<String>();
        if(!game.moves().isBlank()) for(String uci:game.moves().split(" ")) {
            apply(board,uci); moves.add(uci);
        }
        boolean whiteHuman=!cup.seats().get(game.white()).isBot();
        boolean blackHuman=!cup.seats().get(game.black()).isBot();
        String result=game.result();
        if(move!=null) {
            int turn=board.getSideToMove()==Side.WHITE?game.white():game.black();
            if(!result.equals("*") || !Objects.equals(ply,moves.size()) || turn!=cup.mySeat())
                throw new OnlineMatchException(HttpStatus.CONFLICT,"Refresh the board before moving.");
            apply(board,move); moves.add(move); result=result(board);
        }
        if(result.equals("*") && !(board.getSideToMove()==Side.WHITE?whiteHuman:blackHuman)) {
            Move bot=botMove(board);
            board.doMove(bot); moves.add(bot.toString()); result=result(board);
        }
        db.update("update practice_cup_game set started=true,moves=?,result=? where cup_id=? and board_no=?",
                String.join(" ",moves),result,id,number);
        List<String> legal=result.equals("*")?board.legalMoves().stream().map(Move::toString).toList():List.of();
        Cup updated=snapshot(id,player);
        recordFinish(updated);
        return new Position(updated,number,board.getFen(),moves.size(),legal);
    }
    static void apply(Board board,String uci) {
        Move legal=board.legalMoves().stream().filter(m->m.toString().equals(uci)).findFirst().orElseThrow(
                ()->new OnlineMatchException(HttpStatus.BAD_REQUEST,"Illegal move."));
        board.doMove(legal);
    }
    static String result(Board board) {
        if(board.isMated()) return board.getSideToMove()==Side.WHITE?"0-1":"1-0";
        return board.isDraw() || board.isStaleMate()?"1/2-1/2":"*";
    }
    static Move botMove(Board board) {
        var legal=new ArrayList<>(board.legalMoves());
        Collections.shuffle(legal);
        return legal.stream().max(Comparator.comparingInt(m->{
            Piece target=board.getPiece(m.getTo());
            return target==Piece.NONE?0:switch(target.getPieceType()) {
                case QUEEN->9; case ROOK->5; case BISHOP,KNIGHT->3; default->1;
            };
        })).orElseThrow();
    }
    private boolean advanceBotBoards(Cup cup) {
        if(cup.games().isEmpty()) return false;
        if(cup.games().stream().anyMatch(g->g.result().equals("*") &&
                (!cup.seats().get(g.white()).isBot() || !cup.seats().get(g.black()).isBot()))) return false;
        boolean advanced = false;
        for(Game g:cup.games()) if(g.result().equals("*")) {
            Board board=new Board();
            var moves=new ArrayList<String>();
            if (!g.moves().isBlank()) for (String move : g.moves().split(" ")) {
                apply(board, move);
                moves.add(move);
            }
            // Limit work per refresh. Persist the position and continue later,
            // instead of inventing a result when a bot game runs long.
            int limit = moves.size() + 24;
            while(result(board).equals("*") && moves.size()<limit) {
                Move m=botMove(board); board.doMove(m); moves.add(m.toString());
            }
            db.update("update practice_cup_game set started=true,moves=?,result=? where cup_id=? and board_no=?",
                    String.join(" ",moves),result(board),cup.id(),g.number());
            advanced = true;
        }
        return advanced;
    }

    private void recordFinish(Cup cup) {
        if(cup.games().size()==15 && cup.games().stream().noneMatch(g->g.result().equals("*")))
            db.update("update practice_cup set finished_at=CURRENT_TIMESTAMP where id=? and finished_at is null",cup.id());
    }

    public void finishReadyCups() {
        var ready=db.queryForList("""
            select c.id from practice_cup c where c.finished_at is null and c.starts_at<=CURRENT_TIMESTAMP
            and not exists(select 1 from practice_cup_game g join practice_cup_seat s
                on s.cup_id=g.cup_id and s.seat in (g.white_seat,g.black_seat)
                where g.cup_id=c.id and g.result='*' and s.player_id is not null)
            order by c.id limit 8
            """,UUID.class);
        for(UUID id:ready) {
            var owner=db.queryForObject("select player_id from practice_cup_seat where cup_id=? and seat=0",UUID.class,id);
            standings(id,owner);
        }
    }

    List<Winner> recentWinners() {
        return db.query("""
            with recent as (select id, finished_at from practice_cup where finished_at>=?
                order by finished_at desc limit 6),
            scores as (select s.cup_id,s.name,s.player_id,s.seat,r.finished_at,
                sum(case when g.result='1/2-1/2' then 1
                    when g.result='1-0' and g.white_seat=s.seat then 2
                    when g.result='0-1' and g.black_seat=s.seat then 2 else 0 end) points
                from recent r join practice_cup_seat s on s.cup_id=r.id
                join practice_cup_game g on g.cup_id=s.cup_id and s.seat in(g.white_seat,g.black_seat)
                group by s.cup_id,s.seat,s.name,s.player_id,r.finished_at),
            ranked as (select scores.*, rank() over(partition by cup_id order by points desc) place from scores)
            select name,player_id,finished_at from ranked where place=1 order by finished_at desc,cup_id,seat
            """,(r,i)->new Winner(r.getString(1),r.getObject(2)==null,r.getTimestamp(3).toInstant()),
                Timestamp.from(Instant.now().minusSeconds(86400)));
    }
}

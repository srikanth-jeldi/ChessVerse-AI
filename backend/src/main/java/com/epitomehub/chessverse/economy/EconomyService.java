package com.epitomehub.chessverse.economy;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class EconomyService {
    static final long SIGNUP_COINS = 700;
    static final long SIGNUP_DIAMONDS = 10;
    static final long DAILY_COINS = 100;
    static final long REWARDED_AD_COINS = 150;
    static final int REWARDED_AD_DAILY_LIMIT = 3;
    static final long FREE_COIN_COOLDOWN_HOURS = 24;
    private final JdbcTemplate jdbc;

    public EconomyService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    EconomyDtos.WalletDto wallet(AuthenticatedPlayer player) {
        ensureWallet(player.id());
        return readWallet(player.id());
    }

    @Transactional
    EconomyDtos.WalletHistoryDto history(AuthenticatedPlayer player, int requestedLimit) {
        ensureWallet(player.id());
        int limit = Math.max(1, Math.min(100, requestedLimit));
        List<EconomyDtos.TransactionDto> transactions = jdbc.query("""
                select id,currency,amount,balance_after,transaction_type,description,created_at
                from economy_transaction where player_id=?
                order by created_at desc,id desc limit ?
                """, this::mapTransaction, player.id(), limit);
        return new EconomyDtos.WalletHistoryDto(readWallet(player.id()), transactions);
    }

    @Transactional
    public boolean grantCoins(UUID playerId, long amount, String type,
                              String referenceKey, String description) {
        if (amount <= 0 || amount > 1_000_000) {
            throw new IllegalArgumentException("Coin grant must be between 1 and 1,000,000.");
        }
        ensureWallet(playerId);
        if (exists(playerId, referenceKey)) return false;
        WalletCreditState state = jdbc.queryForObject("""
                select coin_balance,coin_debt from player_wallet where player_id=? for update
                """, (rs, row) -> new WalletCreditState(rs.getLong("coin_balance"),
                rs.getLong("coin_debt")), playerId);
        if (state == null) throw new IllegalStateException("Wallet not found.");
        long debtPaid = Math.min(state.debt, amount);
        long credited = amount - debtPaid;
        int updated = jdbc.update("""
                update player_wallet set coin_balance=coin_balance+?,coin_debt=coin_debt-?,updated_at=?
                where player_id=?
                """, credited, debtPaid, Timestamp.from(Instant.now()), playerId);
        if (updated != 1) throw new IllegalStateException("Wallet update failed.");
        long balance = coinBalance(playerId);
        try {
            jdbc.update("""
                    insert into economy_transaction(id,player_id,currency,amount,balance_after,
                    transaction_type,reference_key,description,created_at) values(?,?,?,?,?,?,?,?,?)
                    """, UUID.randomUUID(), playerId, "COINS", credited, balance, type,
                    referenceKey, debtPaid == 0 ? description : description + " (refund debt adjusted)",
                    Timestamp.from(Instant.now()));
            return true;
        } catch (org.springframework.dao.DuplicateKeyException duplicate) {
            throw new IllegalStateException("Duplicate reward raced after balance update.", duplicate);
        }
    }

    /** Credits a server-verified direct coin-pack purchase exactly once. */
    @Transactional
    public boolean grantPurchasedCoins(UUID playerId, long amount, UUID orderId) {
        return grantCoins(playerId, amount, "COIN_PACK_PURCHASE", "purchase:" + orderId,
                "Verified coin pack purchase");
    }

    /** Reverses refunded coins and records any already-spent amount as debt. */
    @Transactional
    public Reversal revokePurchasedCoins(UUID playerId, long amount, UUID orderId, String eventHash) {
        ensureWallet(playerId);
        Long balanceValue = jdbc.queryForObject(
                "select coin_balance from player_wallet where player_id=? for update", Long.class, playerId);
        long balance = balanceValue == null ? 0 : balanceValue;
        long revoked = Math.min(balance, amount);
        long debt = amount - revoked;
        jdbc.update("""
                update player_wallet set coin_balance=coin_balance-?,coin_debt=coin_debt+?,updated_at=?
                where player_id=?
                """, revoked, debt, Timestamp.from(Instant.now()), playerId);
        if (revoked > 0) {
            long after = balance - revoked;
            jdbc.update("""
                    insert into economy_transaction(id,player_id,currency,amount,balance_after,
                    transaction_type,reference_key,description,created_at) values(?,?,?,?,?,?,?,?,?)
                    """, UUID.randomUUID(), playerId, "COINS", -revoked, after, "PURCHASE_REFUND",
                    "refund:" + orderId, "Refunded coin pack", Timestamp.from(Instant.now()));
        }
        jdbc.update("""
                insert into purchase_reversal(order_id,player_id,coins_revoked,coin_debt_added,
                provider_event_hash,created_at) values(?,?,?,?,?,?)
                """, orderId, playerId, revoked, debt, eventHash, Timestamp.from(Instant.now()));
        return new Reversal(revoked, debt);
    }

    public record Reversal(long coinsRevoked, long coinDebtAdded) {}
    private record WalletCreditState(long balance, long debt) {}

    @Transactional
    public boolean spend(UUID playerId, String currency, long amount, String type,
                         String referenceKey, String description) {
        if (!("COINS".equals(currency) || "DIAMONDS".equals(currency))) {
            throw new IllegalArgumentException("Unsupported currency.");
        }
        if (amount <= 0 || amount > 1_000_000) {
            throw new IllegalArgumentException("Spend amount must be between 1 and 1,000,000.");
        }
        ensureWallet(playerId);
        if (exists(playerId, referenceKey)) return false;
        String column = "COINS".equals(currency) ? "coin_balance" : "diamond_balance";
        int updated = jdbc.update("update player_wallet set " + column + "=" + column + "-?,updated_at=? where player_id=? and " + column + ">=?",
                amount, Timestamp.from(Instant.now()), playerId, amount);
        if (updated != 1) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Insufficient " + currency.toLowerCase() + ".");
        }
        Long balance = jdbc.queryForObject("select " + column + " from player_wallet where player_id=?", Long.class, playerId);
        jdbc.update("""
                insert into economy_transaction(id,player_id,currency,amount,balance_after,
                transaction_type,reference_key,description,created_at) values(?,?,?,?,?,?,?,?,?)
                """, UUID.randomUUID(), playerId, currency, -amount, balance, type,
                referenceKey, description, Timestamp.from(Instant.now()));
        return true;
    }

    @Transactional
    public boolean grantRewardedAd(UUID playerId, String transactionId) {
        ensureWallet(playerId);
        Instant dayStart = Instant.now().truncatedTo(ChronoUnit.DAYS);
        Integer today = jdbc.queryForObject("""
                select count(*) from economy_transaction
                where player_id=? and transaction_type='REWARDED_AD' and created_at>=?
                """, Integer.class, playerId, Timestamp.from(dayStart));
        if (today != null && today >= REWARDED_AD_DAILY_LIMIT) return false;
        return grantCoins(playerId, REWARDED_AD_COINS, "REWARDED_AD", "admob:" + transactionId,
                "Rewarded video");
    }

    @Transactional
    EconomyDtos.RewardStatusDto claimDaily(AuthenticatedPlayer player) {
        ensureWallet(player.id());
        jdbc.queryForObject("select coin_balance from player_wallet where player_id=? for update",
                Long.class, player.id());
        Instant last = lastDailyClaim(player.id());
        Instant now = Instant.now();
        if (last != null && last.plus(FREE_COIN_COOLDOWN_HOURS, ChronoUnit.HOURS).isAfter(now)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Free coins are not ready yet.");
        }
        grantCoins(player.id(), DAILY_COINS, "DAILY_REWARD", "daily:" + UUID.randomUUID(),
                "Daily play coins");
        return rewardStatus(player);
    }

    @Transactional
    EconomyDtos.RewardStatusDto rewardStatus(AuthenticatedPlayer player) {
        ensureWallet(player.id());
        Instant last = lastDailyClaim(player.id());
        Instant next = last == null ? Instant.now() : last.plus(FREE_COIN_COOLDOWN_HOURS, ChronoUnit.HOURS);
        Instant dayStart = Instant.now().truncatedTo(ChronoUnit.DAYS);
        Integer used = jdbc.queryForObject("""
                select count(*) from economy_transaction
                where player_id=? and transaction_type='REWARDED_AD' and created_at>=?
                """, Integer.class, player.id(), Timestamp.from(dayStart));
        int count = used == null ? 0 : used;
        return new EconomyDtos.RewardStatusDto(readWallet(player.id()),
                last == null || !next.isAfter(Instant.now()), next, count,
                Math.max(0, REWARDED_AD_DAILY_LIMIT - count),
                (int) DAILY_COINS, (int) REWARDED_AD_COINS);
    }

    private Instant lastDailyClaim(UUID playerId) {
        List<Instant> values = jdbc.query("""
                select created_at from economy_transaction
                where player_id=? and transaction_type='DAILY_REWARD'
                order by created_at desc limit 1
                """, (rs, row) -> rs.getTimestamp("created_at").toInstant(), playerId);
        return values.isEmpty() ? null : values.getFirst();
    }

    private void ensureWallet(UUID playerId) {
        // Serialize first-use initialization per player without relying on
        // database-specific UPSERT syntax. This also closes the concurrent
        // first-request race that could otherwise duplicate welcome grants.
        jdbc.queryForObject("select id from player_account where id=? for update", UUID.class, playerId);
        Integer existing = jdbc.queryForObject("select count(*) from player_wallet where player_id=?", Integer.class, playerId);
        if (existing != null && existing > 0) return;
        Instant now = Instant.now();
        jdbc.update("""
                insert into player_wallet(player_id,coin_balance,diamond_balance,created_at,updated_at)
                values(?,?,?,?,?)
                """, playerId, SIGNUP_COINS, SIGNUP_DIAMONDS, Timestamp.from(now), Timestamp.from(now));
        insertInitial(playerId, "COINS", SIGNUP_COINS, "SIGNUP_COINS", "Welcome coins", now);
        insertInitial(playerId, "DIAMONDS", SIGNUP_DIAMONDS, "SIGNUP_DIAMONDS", "Welcome diamonds", now);
    }

    private void insertInitial(UUID playerId, String currency, long amount,
                               String referenceKey, String description, Instant now) {
        jdbc.update("""
                insert into economy_transaction(id,player_id,currency,amount,balance_after,
                transaction_type,reference_key,description,created_at) values(?,?,?,?,?,?,?,?,?)
                """, UUID.randomUUID(), playerId, currency, amount, amount, "WELCOME",
                referenceKey, description, Timestamp.from(now));
    }

    private boolean exists(UUID playerId, String referenceKey) {
        Boolean value = jdbc.queryForObject("select exists(select 1 from economy_transaction where player_id=? and reference_key=?)",
                Boolean.class, playerId, referenceKey);
        return Boolean.TRUE.equals(value);
    }

    private EconomyDtos.WalletDto readWallet(UUID playerId) {
        List<EconomyDtos.WalletDto> rows = jdbc.query("""
                select coin_balance,diamond_balance,updated_at from player_wallet where player_id=?
                """, (rs, row) -> new EconomyDtos.WalletDto(rs.getLong("coin_balance"),
                rs.getLong("diamond_balance"), rs.getTimestamp("updated_at").toInstant()), playerId);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Wallet not found.");
        return rows.getFirst();
    }

    private long coinBalance(UUID playerId) {
        Long balance = jdbc.queryForObject("select coin_balance from player_wallet where player_id=?", Long.class, playerId);
        if (balance == null) throw new IllegalStateException("Wallet balance missing.");
        return balance;
    }

    private EconomyDtos.TransactionDto mapTransaction(ResultSet rs, int row) throws SQLException {
        return new EconomyDtos.TransactionDto(rs.getObject("id", UUID.class), rs.getString("currency"),
                rs.getLong("amount"), rs.getLong("balance_after"), rs.getString("transaction_type"),
                rs.getString("description"), rs.getTimestamp("created_at").toInstant());
    }
}

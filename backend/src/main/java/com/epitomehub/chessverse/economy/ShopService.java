package com.epitomehub.chessverse.economy;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
class ShopService {
    private final JdbcTemplate jdbc;
    private final EconomyService economy;
    ShopService(JdbcTemplate jdbc, EconomyService economy){this.jdbc=jdbc;this.economy=economy;}

    @Transactional
    ShopDtos.ShopDto catalog(AuthenticatedPlayer player){return load(player);}

    @Transactional
    ShopDtos.ShopDto purchase(AuthenticatedPlayer player,UUID itemId){
        Item item=item(itemId,true);
        if(owned(player.id(),itemId)||"FREE".equals(item.currency)) return equipIfFree(player,item);
        economy.spend(player.id(),item.currency,item.price,"COSMETIC_PURCHASE",
                "cosmetic:"+itemId,"Purchased "+item.name);
        jdbc.update("insert into player_cosmetic_inventory(player_id,item_id,acquired_at) values(?,?,?)",
                player.id(),itemId,Timestamp.from(Instant.now()));
        return load(player);
    }

    @Transactional
    ShopDtos.ShopDto equip(AuthenticatedPlayer player,String rawSlot,UUID itemId){
        String slot=rawSlot.toUpperCase();
        if(!List.of("BOARD","PIECES","EFFECT","FRAME").contains(slot)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Unknown cosmetic slot.");
        Item item=item(itemId,false);
        if(!slot.equals(item.category)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Item does not match this slot.");
        if(!"FREE".equals(item.currency)&&!owned(player.id(),itemId)) throw new ResponseStatusException(HttpStatus.CONFLICT,"Purchase this item before equipping it.");
        ensureLoadout(player.id());
        String column=switch(slot){case "BOARD"->"board_item_id";case "PIECES"->"pieces_item_id";case "EFFECT"->"effect_item_id";default->"frame_item_id";};
        jdbc.update("update player_cosmetic_loadout set "+column+"=?,updated_at=? where player_id=?",itemId,Timestamp.from(Instant.now()),player.id());
        return load(player);
    }

    private ShopDtos.ShopDto equipIfFree(AuthenticatedPlayer player,Item item){
        return equip(player,item.category,item.id);
    }
    private ShopDtos.ShopDto load(AuthenticatedPlayer player){
        EconomyDtos.WalletDto wallet=economy.wallet(player);
        ensureLoadout(player.id());
        List<ShopDtos.ItemDto> items=jdbc.query("""
                select i.*,exists(select 1 from player_cosmetic_inventory x where x.player_id=? and x.item_id=i.id) owned,
                (l.board_item_id=i.id or l.pieces_item_id=i.id or l.effect_item_id=i.id or l.frame_item_id=i.id) equipped
                from cosmetic_item i join player_cosmetic_loadout l on l.player_id=? where i.active=true order by i.category,i.sort_order
                """,this::map,player.id(),player.id());
        return new ShopDtos.ShopDto(player.id(),wallet,items);
    }
    private void ensureLoadout(UUID playerId){jdbc.update("""
            insert into player_cosmetic_loadout(player_id,board_item_id,pieces_item_id,updated_at)
            select ?, '41000000-0000-0000-0000-000000000001','42000000-0000-0000-0000-000000000001',?
            where not exists(select 1 from player_cosmetic_loadout where player_id=?)
            """,playerId,Timestamp.from(Instant.now()),playerId);}
    private boolean owned(UUID playerId,UUID itemId){Boolean v=jdbc.queryForObject("select exists(select 1 from player_cosmetic_inventory where player_id=? and item_id=?)",Boolean.class,playerId,itemId);return Boolean.TRUE.equals(v);}
    private Item item(UUID id,boolean lock){return jdbc.query("select id,category,name,price_currency,price_amount from cosmetic_item where id=? and active=true"+(lock?" for update":""),rs->{if(!rs.next())throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Cosmetic item not found.");return new Item(rs.getObject(1,UUID.class),rs.getString(2),rs.getString(3),rs.getString(4),rs.getLong(5));},id);}
    private ShopDtos.ItemDto map(ResultSet rs,int row)throws SQLException{return new ShopDtos.ItemDto(rs.getObject("id",UUID.class),rs.getString("slug"),rs.getString("category"),rs.getString("name"),rs.getString("description"),rs.getString("price_currency"),rs.getLong("price_amount"),rs.getString("primary_color"),rs.getString("secondary_color"),rs.getString("asset_key"),rs.getBoolean("owned")||"FREE".equals(rs.getString("price_currency")),rs.getBoolean("equipped"));}
    private record Item(UUID id,String category,String name,String currency,long price){}
}

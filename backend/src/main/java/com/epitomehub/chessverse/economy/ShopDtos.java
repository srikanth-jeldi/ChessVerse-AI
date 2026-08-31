package com.epitomehub.chessverse.economy;

import java.util.List;
import java.util.UUID;

final class ShopDtos {
    private ShopDtos() {}
    record ItemDto(UUID id,String slug,String category,String name,String description,
                   String priceCurrency,long priceAmount,String primaryColor,
                   String secondaryColor,String assetKey,boolean owned,boolean equipped) {}
    record ShopDto(UUID playerId,EconomyDtos.WalletDto wallet,List<ItemDto> items) {}
    record EquipRequest(UUID itemId) {}
}

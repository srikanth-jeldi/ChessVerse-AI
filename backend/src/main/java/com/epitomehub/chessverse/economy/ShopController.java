package com.epitomehub.chessverse.economy;

import com.epitomehub.chessverse.auth.AuthenticatedPlayer;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import java.util.UUID;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/shop")
class ShopController {
    private final PlayerAuthenticationService authentication;private final ShopService shop;
    ShopController(PlayerAuthenticationService authentication,ShopService shop){this.authentication=authentication;this.shop=shop;}
    @GetMapping ShopDtos.ShopDto catalog(@RequestHeader("Authorization")String auth){return shop.catalog(player(auth));}
    @PostMapping("/items/{id}/purchase") ShopDtos.ShopDto purchase(@RequestHeader("Authorization")String auth,@PathVariable UUID id){return shop.purchase(player(auth),id);}
    @PutMapping("/loadout/{slot}") ShopDtos.ShopDto equip(@RequestHeader("Authorization")String auth,@PathVariable String slot,@RequestBody ShopDtos.EquipRequest request){return shop.equip(player(auth),slot,request.itemId());}
    private AuthenticatedPlayer player(String auth){return authentication.requireBearer(auth);}
}

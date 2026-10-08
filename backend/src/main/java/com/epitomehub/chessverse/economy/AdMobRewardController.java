package com.epitomehub.chessverse.economy;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api/v1/economy/rewarded-ad")
class AdMobRewardController {
    private static final Logger LOG = LoggerFactory.getLogger(AdMobRewardController.class);
    private final AdMobRewardVerifier verifier;private final EconomyService economy;private final String expectedAdUnit;
    AdMobRewardController(AdMobRewardVerifier verifier,EconomyService economy,
            @Value("${chessverse.economy.admob.rewarded-ad-unit-id:}")String expectedAdUnit){this.verifier=verifier;this.economy=economy;this.expectedAdUnit=expectedAdUnit;}
    @GetMapping("/callback") void callback(HttpServletRequest request){
        Map<String,String> value=verifier.verify(request.getQueryString());
        if (!matchesExpectedAdUnit(value.get("ad_unit"))
                || !"chessverse_coins_v1".equals(value.get("custom_data"))) {
            LOG.warn("AdMob SSV source mismatch: ad_unit={}, custom_data={}",
                    value.get("ad_unit"), value.get("custom_data"));
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Unexpected reward source.");
        }
        String transaction=value.get("transaction_id");String user=value.get("user_id");
        if(transaction==null||transaction.length()>120||user==null)throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Incomplete reward callback.");
        try{economy.grantRewardedAd(UUID.fromString(user),transaction);}catch(IllegalArgumentException exception){throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Invalid reward player.");}
    }

    boolean matchesExpectedAdUnit(String callbackAdUnit) {
        if (expectedAdUnit.isBlank() || callbackAdUnit == null || callbackAdUnit.isBlank()) return false;
        return expectedAdUnit.equals(callbackAdUnit) || expectedAdUnit.endsWith("/" + callbackAdUnit);
    }
}

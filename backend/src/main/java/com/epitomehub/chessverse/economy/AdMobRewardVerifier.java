package com.epitomehub.chessverse.economy;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import com.google.crypto.tink.apps.rewardedads.RewardedAdsVerifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
class AdMobRewardVerifier {
    private static final String CALLBACK_URL =
            "https://api.chessverseai.com/api/v1/economy/rewarded-ad/callback?";
    private final boolean enabled;
    private final RewardedAdsVerifier verifier;

    AdMobRewardVerifier(@Value("${chessverse.economy.admob.enabled:false}") boolean enabled) {
        this.enabled = enabled;
        this.verifier = createVerifier();
    }

    private static RewardedAdsVerifier createVerifier() {
        try {
            return new RewardedAdsVerifier.Builder()
                    .fetchVerifyingPublicKeysWith(RewardedAdsVerifier.KEYS_DOWNLOADER_INSTANCE_PROD)
                    .build();
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to initialize AdMob reward verification.", exception);
        }
    }

    Map<String,String> verify(String rawQuery){
        if(!enabled)throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Rewarded ads are not enabled.");
        if (rawQuery == null || rawQuery.isBlank()) throw invalid();
        try {
            verifier.verify(CALLBACK_URL + rawQuery);
            int signature = rawQuery.indexOf("&signature=");
            if (signature < 1) throw invalid();
            return parameters(rawQuery.substring(0, signature));
        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (Exception exception) {
            throw invalid();
        }
    }
    private Map<String,String> parameters(String signed){Map<String,String> values=new HashMap<>();for(String pair:signed.split("&")){int split=pair.indexOf('=');if(split>0)values.put(decode(pair.substring(0,split)),decode(pair.substring(split+1)));}return values;}
    private String decode(String value){return URLDecoder.decode(value,StandardCharsets.UTF_8);}
    private ResponseStatusException invalid(){return new ResponseStatusException(HttpStatus.UNAUTHORIZED,"Invalid AdMob reward signature.");}
}

package com.epitomehub.chessverse.economy;

import java.net.URLDecoder;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.time.Duration;
import java.time.Instant;
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
    private final String keysUrl;
    private volatile HttpClient http;
    private volatile RewardedAdsVerifier verifier;
    private volatile Instant verifierExpires = Instant.EPOCH;

    AdMobRewardVerifier(@Value("${chessverse.economy.admob.enabled:false}") boolean enabled,
            @Value("${chessverse.economy.admob.verifier-keys-url}") String keysUrl) {
        this.enabled = enabled;
        this.keysUrl = keysUrl;
    }

    private synchronized RewardedAdsVerifier verifier() throws Exception {
        if (verifier != null && Instant.now().isBefore(verifierExpires)) return verifier;
        if (http == null) {
            http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        }
        HttpRequest request = HttpRequest.newBuilder(URI.create(keysUrl))
                .timeout(Duration.ofSeconds(8)).GET().build();
        HttpResponse<String> response = http.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) throw new IllegalStateException("AdMob keys unavailable.");
        verifier = new RewardedAdsVerifier.Builder()
                .setVerifyingPublicKeys(response.body())
                .build();
        verifierExpires = Instant.now().plus(Duration.ofHours(24));
        return verifier;
    }

    Map<String,String> verify(String rawQuery){
        if(!enabled)throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Rewarded ads are not enabled.");
        if (rawQuery == null || rawQuery.isBlank()) throw invalid();
        try {
            verifier().verify(CALLBACK_URL + rawQuery);
            int signature = rawQuery.indexOf("&signature=");
            if (signature < 1) throw invalid();
            return parameters(rawQuery.substring(0, signature));
        } catch (ResponseStatusException exception) {
            throw exception;
        } catch (GeneralSecurityException exception) {
            if (exception.getMessage() != null
                    && exception.getMessage().startsWith("cannot find verifying key")) {
                throw new ResponseStatusException(HttpStatus.PRECONDITION_FAILED,
                        "AdMob signing key is not available.");
            }
            throw invalid();
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "AdMob verification was interrupted.");
        } catch (Exception exception) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "AdMob verification is temporarily unavailable.");
        }
    }
    private Map<String,String> parameters(String signed){Map<String,String> values=new HashMap<>();for(String pair:signed.split("&")){int split=pair.indexOf('=');if(split>0)values.put(decode(pair.substring(0,split)),decode(pair.substring(split+1)));}return values;}
    private String decode(String value){return URLDecoder.decode(value,StandardCharsets.UTF_8);}
    private ResponseStatusException invalid(){return new ResponseStatusException(HttpStatus.UNAUTHORIZED,"Invalid AdMob reward signature.");}
}

package com.epitomehub.chessverse.economy;

import java.net.URI;
import java.net.URLDecoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
class AdMobRewardVerifier {
    private static final Pattern SIGNED = Pattern.compile("^(.*)&signature=([^&]+)&key_id=([^&]+)$");
    private static final Pattern KEY = Pattern.compile("\\\"keyId\\\"\\s*:\\s*(\\d+).*?\\\"pem\\\"\\s*:\\s*\\\"(.*?)\\\"", Pattern.DOTALL);
    private final boolean enabled; private final String keysUrl; private volatile HttpClient http;
    private Map<Long,PublicKey> keys=Map.of(); private Instant keysExpire=Instant.EPOCH;
    AdMobRewardVerifier(@Value("${chessverse.economy.admob.enabled:false}")boolean enabled,
            @Value("${chessverse.economy.admob.verifier-keys-url}")String keysUrl){
        this.enabled=enabled;this.keysUrl=keysUrl;
    }
    Map<String,String> verify(String rawQuery){
        if(!enabled)throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Rewarded ads are not enabled.");
        Matcher matcher=SIGNED.matcher(rawQuery==null?"":rawQuery);
        if(!matcher.matches())throw invalid();
        try{
            long keyId=Long.parseLong(decode(matcher.group(3)));
            PublicKey key=keys().get(keyId);if(key==null)throw invalid();
            Signature verifier=Signature.getInstance("SHA256withECDSA");verifier.initVerify(key);
            verifier.update(matcher.group(1).getBytes(StandardCharsets.UTF_8));
            if(!verifier.verify(Base64.getUrlDecoder().decode(decode(matcher.group(2)))))throw invalid();
            return parameters(matcher.group(1));
        }catch(ResponseStatusException exception){throw exception;}catch(Exception exception){throw invalid();}
    }
    private synchronized Map<Long,PublicKey> keys()throws Exception{
        if(Instant.now().isBefore(keysExpire)&&!keys.isEmpty())return keys;
        HttpRequest request=HttpRequest.newBuilder(URI.create(keysUrl)).timeout(Duration.ofSeconds(8)).GET().build();
        HttpResponse<String> response=client().send(request,HttpResponse.BodyHandlers.ofString());
        if(response.statusCode()!=200)throw invalid();
        Map<Long,PublicKey> loaded=new HashMap<>();Matcher matcher=KEY.matcher(response.body());
        while(matcher.find()){
            String pem=matcher.group(2).replace("\\n","\n").replace("\\/","/");
            String base64=pem.replace("-----BEGIN PUBLIC KEY-----","").replace("-----END PUBLIC KEY-----","").replaceAll("\\s","");
            loaded.put(Long.parseLong(matcher.group(1)),KeyFactory.getInstance("EC").generatePublic(new X509EncodedKeySpec(Base64.getDecoder().decode(base64))));
        }
        if(loaded.isEmpty())throw invalid();keys=Map.copyOf(loaded);keysExpire=Instant.now().plus(Duration.ofHours(24));return keys;
    }
    private Map<String,String> parameters(String signed){Map<String,String> values=new HashMap<>();for(String pair:signed.split("&")){int split=pair.indexOf('=');if(split>0)values.put(decode(pair.substring(0,split)),decode(pair.substring(split+1)));}return values;}
    private HttpClient client(){HttpClient current=http;if(current!=null)return current;synchronized(this){if(http==null)http=HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();return http;}}
    private String decode(String value){return URLDecoder.decode(value,StandardCharsets.UTF_8);}
    private ResponseStatusException invalid(){return new ResponseStatusException(HttpStatus.UNAUTHORIZED,"Invalid AdMob reward signature.");}
}

package com.epitomehub.chessverse.academy;

import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import tools.jackson.databind.ObjectMapper;

/** Optional AI wording over numeric evidence only. Names, notes, emails and IDs never leave the service. */
@Service
public class AcademyGuidanceService {
    private final ObjectMapper json;
    private final String endpoint, key, model;
    private final boolean enabled;
    public record Guidance(String source, String text) {}
    public AcademyGuidanceService(ObjectMapper json,
            @Value("${chessverse.academy.ai.enabled:false}") boolean enabled,
            @Value("${chessverse.coach.language.endpoint:}") String endpoint,
            @Value("${chessverse.coach.language.api-key:}") String key,
            @Value("${chessverse.coach.language.model:}") String model) {
        this.json=json; this.enabled=enabled; this.endpoint=endpoint; this.key=key; this.model=model;
    }
    public Guidance recommend(List<Map<String,Object>> observations) {
        if(observations.isEmpty()) return new Guidance("RULES","Record training sessions before requesting a personalized plan.");
        Map<String,Integer> evidence=new LinkedHashMap<>();
        for(String field:List.of("accuracy","minutes","tactics","blunders","opening_errors","middle_errors","endgame_errors","retry_attempts","retry_failures")) {
            int value=observations.stream().mapToInt(o->((Number)o.get(field)).intValue()).sum();
            evidence.put(field.equals("accuracy")?"average_accuracy_percent":field,field.equals("accuracy")?value/observations.size():value);
        }
        evidence.put("sessions",observations.size());
        var labels=Map.of("blunders","tactical calculation","opening_errors","opening principles","middle_errors","middlegame planning","endgame_errors","endgame fundamentals");
        String focus=labels.entrySet().stream().max(Comparator.comparingInt(e->evidence.get(e.getKey()))).orElseThrow().getValue();
        String fallback="Prioritize "+focus+" in the next session. Review three recorded mistakes, solve five related positions, and explain candidate moves before playing. Retry the failed positions after 48 hours and compare success rates. Coach review is recommended.";
        if(!enabled || endpoint.isBlank() || key.isBlank() || model.isBlank()) return new Guidance("RULES",fallback+" AI guidance is not configured for this deployment.");
        try {
            URI uri=URI.create(endpoint);
            if(!"https".equalsIgnoreCase(uri.getScheme()) || uri.getHost()==null || uri.getUserInfo()!=null) return new Guidance("RULES",fallback);
            String body=json.writeValueAsString(Map.of("model",model,"temperature",0.2,"max_tokens",250,"messages",List.of(
                Map.of("role","developer","content","You are a chess academy coach. Suggest a concise three-step training plan using ONLY the numeric training evidence supplied. Do not invent moves, openings played, identities, diagnoses or future ratings. State uncertainty. Under 150 words. Plain text only."),
                Map.of("role","user","content",json.writeValueAsString(evidence)))));
            try(HttpClient client=HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).followRedirects(HttpClient.Redirect.NEVER).build()) {
                var request=HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(8)).header("Authorization","Bearer "+key).header("Content-Type","application/json").POST(HttpRequest.BodyPublishers.ofString(body)).build();
                var response=client.send(request,HttpResponse.BodyHandlers.ofInputStream());
                try(var stream=response.body()) {
                    byte[] bytes=stream.readNBytes(65537);
                    if(response.statusCode()==200 && bytes.length<=65536) {
                        String text=json.readTree(new String(bytes,StandardCharsets.UTF_8)).path("choices").path(0).path("message").path("content").asText("");
                        if(!text.isBlank() && text.length()<=4000) return new Guidance("AI",text);
                    }
                }
            }
        } catch(InterruptedException ex) { Thread.currentThread().interrupt(); }
        catch(Exception ex) { /* Provider errors and secrets must not leak into the API response. */ }
        return new Guidance("RULES",fallback+" AI provider unavailable; showing evidence-based fallback.");
    }
}

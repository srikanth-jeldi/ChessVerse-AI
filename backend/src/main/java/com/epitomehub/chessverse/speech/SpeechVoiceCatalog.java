package com.epitomehub.chessverse.speech;

import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

final class SpeechVoiceCatalog {
    private static final Pattern LOCALE = Pattern.compile("^[a-z]{2,3}(?:[-_][A-Za-z]{2,4})?$");
    private static final Map<String, Voice> VOICES = Map.ofEntries(
            entry("en", "en-US", "en-US-JennyNeural"),
            entry("te", "te-IN", "te-IN-ShrutiNeural"),
            entry("hi", "hi-IN", "hi-IN-SwaraNeural"),
            entry("ta", "ta-IN", "ta-IN-PallaviNeural"),
            entry("kn", "kn-IN", "kn-IN-SapnaNeural"),
            entry("ml", "ml-IN", "ml-IN-SobhanaNeural"),
            entry("mr", "mr-IN", "mr-IN-AarohiNeural"),
            entry("bn", "bn-IN", "bn-IN-TanishaaNeural"),
            entry("gu", "gu-IN", "gu-IN-DhwaniNeural"),
            entry("pa", "pa-IN", "pa-IN-VaaniNeural"),
            entry("ur", "ur-PK", "ur-PK-UzmaNeural"),
            entry("ar", "ar-SA", "ar-SA-ZariyahNeural"),
            entry("es", "es-ES", "es-ES-ElviraNeural"),
            entry("fr", "fr-FR", "fr-FR-DeniseNeural"),
            entry("de", "de-DE", "de-DE-KatjaNeural"),
            entry("it", "it-IT", "it-IT-ElsaNeural"),
            entry("pt", "pt-BR", "pt-BR-FranciscaNeural"),
            entry("ru", "ru-RU", "ru-RU-SvetlanaNeural"),
            entry("uk", "uk-UA", "uk-UA-PolinaNeural"),
            entry("tr", "tr-TR", "tr-TR-EmelNeural"),
            entry("fa", "fa-IR", "fa-IR-DilaraNeural"),
            entry("zh", "zh-CN", "zh-CN-XiaoxiaoNeural"),
            entry("ja", "ja-JP", "ja-JP-NanamiNeural"),
            entry("ko", "ko-KR", "ko-KR-SunHiNeural"),
            entry("id", "id-ID", "id-ID-GadisNeural"),
            entry("ms", "ms-MY", "ms-MY-YasminNeural"),
            entry("th", "th-TH", "th-TH-PremwadeeNeural"),
            entry("vi", "vi-VN", "vi-VN-HoaiMyNeural"),
            entry("pl", "pl-PL", "pl-PL-ZofiaNeural"),
            entry("nl", "nl-NL", "nl-NL-ColetteNeural"),
            entry("sv", "sv-SE", "sv-SE-SofieNeural"),
            entry("el", "el-GR", "el-GR-AthinaNeural"),
            entry("he", "he-IL", "he-IL-HilaNeural"),
            entry("sw", "sw-KE", "sw-KE-ZuriNeural"));

    private SpeechVoiceCatalog() {}

    static Voice resolve(String requested) {
        String normalized = requested == null ? "" : requested.trim();
        if (!LOCALE.matcher(normalized).matches()) return null;
        String language = normalized.replace('_', '-').split("-", 2)[0].toLowerCase(Locale.ROOT);
        return VOICES.get(language);
    }

    private static Map.Entry<String, Voice> entry(String language, String locale, String name) {
        return Map.entry(language, new Voice(locale, name));
    }

    record Voice(String locale, String name) {}
}

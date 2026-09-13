{{flutter_js}}
{{flutter_build_config}}

// ChessVerseAI is deployed frequently and must always load the tested release
// from the server. Offline caching is intentionally disabled to prevent an old
// Flutter bundle from trapping users on a stale splash screen.
_flutter.loader.load();

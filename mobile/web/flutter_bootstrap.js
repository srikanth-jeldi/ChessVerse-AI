{{flutter_js}}
{{flutter_build_config}}

// A new URL also bypasses cached entrypoints from before the board fix.
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) build.mainJsPath += '?v=daily-coin-rewards';
}

// ChessVerseAI is deployed frequently and must always load the tested release
// from the server. Offline caching is intentionally disabled to prevent an old
// Flutter bundle from trapping users on a stale splash screen.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    } catch (error) {
      window.chessverseStartupFailed();
      console.error(error);
    }
  }
}).catch(function (error) {
  window.chessverseStartupFailed();
  console.error(error);
});

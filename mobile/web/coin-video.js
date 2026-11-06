(() => {
  let loading;
  let busy = false;
  function loadSdk() {
    if (window.AyetVideoSdk) return Promise.resolve(window.AyetVideoSdk);
    if (!loading) loading = new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = "https://cdn.ayet.io/offerwall/js/ayetvideosdk.min.js";
      script.onload = () => resolve(window.AyetVideoSdk);
      script.onerror = () => { loading = undefined; script.remove(); reject(new Error("SDK unavailable")); };
      document.head.append(script);
    });
    return loading;
  }

  window.showChessVerseCoinVideo = (placement, slot, player) => {
    if (busy) return Promise.resolve("unavailable");
    busy = true;
    return new Promise(resolve => {
      let active = true;
      let sdk;
      let timer;
      let closed = false;
      let rewarded = false;
      function finish(result) {
        if (!active) return;
        active = false;
        clearTimeout(timer);
        busy = false;
        resolve(result);
      }
      function deadline(ms) {
        clearTimeout(timer);
        timer = setTimeout(() => {
          finish("unavailable");
          sdk?.destroy();
        }, ms);
      }
      deadline(20000);
      loadSdk().then(async provider => {
        if (!active) return;
        sdk = provider;
        await sdk.init(placement, player, null);
        if (!active) return;
        sdk.callbackError = () => finish("unavailable");
        sdk.callbackRewarded = details => {
          rewarded = details?.rewarded === true && details.externalIdentifier === player;
          if (closed && rewarded) finish("earned");
        };
        // Completion and reward validation are separate events. Wallet credit comes from the signed postback.
        sdk.callbackComplete = () => {
          if (!active) return;
          closed = true;
          if (rewarded) return finish("earned");
          clearTimeout(timer);
          timer = setTimeout(() => finish("dismissed"), 15000);
        };
        sdk.requestAd(slot, () => {
          if (!active) return;
          deadline(180000);
          try { sdk.playFullsizeAd(); } catch { finish("unavailable"); }
        }, () => finish("unavailable"));
      }).catch(() => finish("unavailable"));
    });
  };
})();

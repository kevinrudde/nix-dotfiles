(() => {
  const bridgeEvent = "slack-open-links-external:open";
  const originalOpen = window.open;

  function isSlackHost(hostname) {
    return hostname === "slack.com" || hostname.endsWith(".slack.com");
  }

  function externalHttpUrl(value) {
    if (!value) {
      return null;
    }

    try {
      const url = new URL(String(value), window.location.href);
      if (url.protocol !== "http:" && url.protocol !== "https:") {
        return null;
      }

      if (isSlackHost(url.hostname)) {
        return null;
      }

      return url.href;
    } catch (_error) {
      return null;
    }
  }

  function requestExternalOpen(url) {
    window.dispatchEvent(new CustomEvent(bridgeEvent, { detail: { url } }));
  }

  window.open = function open(url, target, features) {
    const externalUrl = externalHttpUrl(url);
    if (externalUrl) {
      requestExternalOpen(externalUrl);
      return null;
    }

    return originalOpen.call(window, url, target, features);
  };
})();

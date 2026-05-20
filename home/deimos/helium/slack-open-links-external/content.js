const BRIDGE_EVENT = "slack-open-links-external:open";

function isSlackHost(hostname) {
  return hostname === "slack.com" || hostname.endsWith(".slack.com");
}

function externalHttpUrl(value) {
  if (!value) {
    return null;
  }

  try {
    const url = new URL(value, window.location.href);
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

function openExternal(url) {
  chrome.runtime.sendMessage({ type: "openExternal", url });
}

function nearestAnchor(target) {
  if (!(target instanceof Element)) {
    return null;
  }

  return target.closest("a[href]");
}

function handlePointerOpen(event) {
  if (event.defaultPrevented) {
    return;
  }

  if (event.type === "click" && event.button !== 0) {
    return;
  }

  if (event.type === "auxclick" && event.button !== 1) {
    return;
  }

  const anchor = nearestAnchor(event.target);
  const url = externalHttpUrl(anchor?.href);
  if (!url) {
    return;
  }

  event.preventDefault();
  event.stopImmediatePropagation();
  openExternal(url);
}

function handleKeyboardOpen(event) {
  if (event.defaultPrevented || event.key !== "Enter") {
    return;
  }

  const anchor = nearestAnchor(event.target);
  const url = externalHttpUrl(anchor?.href);
  if (!url) {
    return;
  }

  event.preventDefault();
  event.stopImmediatePropagation();
  openExternal(url);
}

window.addEventListener(BRIDGE_EVENT, (event) => {
  const url = externalHttpUrl(event.detail?.url);
  if (url) {
    openExternal(url);
  }
});

document.addEventListener("click", handlePointerOpen, true);
document.addEventListener("auxclick", handlePointerOpen, true);
document.addEventListener("keydown", handleKeyboardOpen, true);

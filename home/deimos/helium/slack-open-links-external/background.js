const HOST_NAME = "dev.kevin.slack_open_links_external";

function normalizeHttpUrl(value) {
  if (typeof value !== "string") {
    return null;
  }

  try {
    const url = new URL(value);
    if (url.protocol !== "http:" && url.protocol !== "https:") {
      return null;
    }

    return url.href;
  } catch (_error) {
    return null;
  }
}

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (!message || message.type !== "openExternal") {
    return false;
  }

  const url = normalizeHttpUrl(message.url);
  if (!url) {
    sendResponse({ ok: false, error: "invalid_url" });
    return false;
  }

  chrome.runtime.sendNativeMessage(HOST_NAME, { url }, (response) => {
    const error = chrome.runtime.lastError;
    if (error) {
      sendResponse({ ok: false, error: error.message });
      return;
    }

    sendResponse(response || { ok: true });
  });

  return true;
});

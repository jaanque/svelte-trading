/**
 * Utility functions for the application
 */

/**
 * Escapes HTML special characters to prevent XSS.
 */
export function escapeHtml(text: string): string {
  if (!text) return "";
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * Converts text URLs into clickable HTML anchor tags.
 * Designed to work on already escaped HTML text.
 */
export function linkify(text: string): string {
  // Regex to find substrings that look like URLs
  // Matches http://, https://, or www. followed by non-whitespace characters
  const urlRegex = /((?:https?:\/\/|www\.)[^\s]+)/g;

  return text.replace(urlRegex, (url) => {
    let trailing = "";

    // Peel off trailing punctuation or HTML entities that are likely not part of the URL
    // This helps when a URL is at the end of a sentence or in parenthesis
    while (url.length > 0) {
        if (/[.,!?)]$/.test(url)) {
             trailing = url.charAt(url.length - 1) + trailing;
             url = url.slice(0, -1);
        } else if (url.endsWith("&quot;")) {
             trailing = "&quot;" + trailing;
             url = url.slice(0, -6);
        } else if (url.endsWith("&lt;")) {
             trailing = "&lt;" + trailing;
             url = url.slice(0, -4);
        } else if (url.endsWith("&gt;")) {
             trailing = "&gt;" + trailing;
             url = url.slice(0, -4);
        } else if (url.endsWith("&#039;")) {
             trailing = "&#039;" + trailing;
             url = url.slice(0, -6);
        } else {
            break;
        }
    }

    if (url.length === 0) {
        return trailing;
    }

    let href = url;
    // If it starts with www., add http://
    if (!href.startsWith("http://") && !href.startsWith("https://")) {
        href = "http://" + href;
    }

    // Note: 'url' here is already HTML escaped (e.g. &amp; instead of &), which is fine for display
    // 'href' is also escaped, but browsers handle encoded entities in href attributes gracefully.

    return `<a href="${href}" target="_blank" rel="noopener noreferrer">${url}</a>${trailing}`;
  });
}

/**
 * Formats a raw message string for display:
 * 1. Escapes HTML
 * 2. Linkifies URLs
 * 3. Converts newlines to <br>
 */
export function formatMessage(text: string): string {
  if (!text) return "";
  let safeText = escapeHtml(text);
  safeText = linkify(safeText);
  safeText = safeText.replace(/\n/g, "<br>");
  return safeText;
}

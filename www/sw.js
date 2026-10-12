// Network-first service worker: always fetches the latest files when online
// (so a new commit shows up on the next open) and falls back to the cache offline.
const CACHE = "c3-live-v1";
const ASSETS = ["./", "index.html", "manifest.json", "favicon.svg", "favicon-32.png", "favicon-16.png",
  "apple-touch-icon.png", "icon-192.png", "icon-512.png", "offline.html"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  if (new URL(req.url).origin !== self.location.origin) return;
  e.respondWith(
    fetch(req, { cache: "no-cache" })
      .then(res => {
        if (res && res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return res;
      })
      .catch(() =>
        caches.match(req).then(r => r || caches.match("index.html") || caches.match("./"))
      )
  );
});

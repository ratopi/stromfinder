// ---------------------------------------------------------------------------
// Stromfinder – Service Worker
// Caches the app shell for offline use.
// Own resources: network-first (always fresh after deploy)
// CDN resources: cache-first (never change)
// Data/tiles: network-first with cache fallback (offline support)
// ---------------------------------------------------------------------------

const CACHE_NAME = "stromfinder-v1";

const APP_SHELL = [
  "./",
  "./index.html",
  "./style.css",
  "./app.js",
  "./ports.js",
  "./manifest.json",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css",
  "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js",
  "https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css",
  "https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css",
  "https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js",
  "https://unpkg.com/pako@2.1.0/dist/pako.min.js",
];

// Install: cache the app shell
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

// Activate: clean old caches
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((k) => k !== CACHE_NAME)
          .map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// Fetch strategy
self.addEventListener("fetch", (event) => {
  const url = event.request.url;

  // Data, tiles, version.json: network first, cache fallback
  if (url.includes("ladesaeulen.json") || url.includes("tile.openstreetmap.org") || url.includes("version.json")) {
    event.respondWith(
      fetch(event.request)
        .then((r) => { caches.open(CACHE_NAME).then((c) => c.put(event.request, r.clone())); return r; })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // CDN (unpkg): cache first
  if (!url.startsWith(self.location.origin)) {
    event.respondWith(
      caches.match(event.request).then((cached) =>
        cached || fetch(event.request).then((r) => { caches.open(CACHE_NAME).then((c) => c.put(event.request, r.clone())); return r; })
      )
    );
    return;
  }

  // Own resources: network first, cache fallback
  event.respondWith(
    fetch(event.request)
      .then((r) => { caches.open(CACHE_NAME).then((c) => c.put(event.request, r.clone())); return r; })
      .catch(() => caches.match(event.request))
  );
});

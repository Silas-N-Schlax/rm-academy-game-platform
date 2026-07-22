const CACHE_NAME = "v2";
const PRECACHE_URLS = [
  "/offline",
  "https://cdn.jsdelivr.net/npm/@rolemodel/optics@2.4.0/dist/css/optics+lucide_icons.min.css",
  "https://unpkg.com/lucide-static@1.21.0/icons/cloud-off.svg",
  "/logo.png",
  "/icon.png"
];

const addResourcesToCache = async (resources) => {
  const cache = await caches.open(CACHE_NAME);
  await cache.addAll(resources);
};

self.addEventListener("install", (event) => {
  event.waitUntil(addResourcesToCache(PRECACHE_URLS));
  self.skipWaiting()
});

self.addEventListener("fetch", (event) => {
  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match('/offline');
      })
    );
    return;
  }

  if (PRECACHE_URLS.includes(event.request.url)) {
    event.respondWith(
      caches.match(event.request).then((cached) => cached || fetch(event.request))
    );
  }
});


self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
        )
      )
      .then(() => self.clients.claim())
  )
})

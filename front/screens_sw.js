const CACHE_NAME = 'screens-ads-v17';
const MEDIA_CACHE_NAME = 'screens-media-permanent-v1';
const ASSETS = [
  './',
  'index.html',
  'screens_manifest.json',
  'logo.png',
  'logo2.png'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS);
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME && key !== MEDIA_CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET') return;

  // 1. Permanent Supabase Media Cache: Network-first, offline fallback from disk on C:
  if (url.origin.includes('supabase.co') && url.pathname.includes('/media/')) {
    e.respondWith(
      fetch(e.request)
        .then((response) => {
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(MEDIA_CACHE_NAME).then((cache) => cache.put(e.request, clone));
          }
          return response;
        })
        .catch(() => {
          return caches.open(MEDIA_CACHE_NAME).then((cache) => {
            return cache.match(e.request).then((matching) => {
              if (matching) return matching;
              return new Response('Offline media not available', { status: 503 });
            });
          });
        })
    );
    return;
  }

  // 2. Same-origin app shell caching
  if (url.origin !== self.location.origin) return;

  e.respondWith(
    fetch(e.request)
      .then((response) => {
        if (response && response.status === 200) {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(e.request, responseToCache);
          });
        }
        return response;
      })
      .catch(() => {
        return caches.match(e.request).then((matching) => {
          if (matching) return matching;
          if (url.pathname.endsWith('/screens') || url.pathname.endsWith('/index.html') || url.pathname === '/') {
            return caches.match('index.html');
          }
          return new Response('Offline', { status: 503, statusText: 'Offline' });
        });
      })
  );
});

const CACHE_NAME = 'screens-ads-v14';
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
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Cache-falling app shell strategy for same-origin resources only
self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  
  // Only intercept same-origin app shell requests; let external Supabase media stream directly
  if (e.request.method !== 'GET' || url.origin !== self.location.origin) {
    return;
  }

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

// SadaSneha service worker: lets the app open from the home screen, even on
// a weak network. The family's last status is kept by the page itself.
const CACHE = 'ghar-sarthi-v79';
const SHELL = ['./', './index.html', './manifest.json', './sneha.jpg', './icon-192.png', './icon-512.png'];
self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET' || new URL(e.request.url).origin !== location.origin) return;
  e.respondWith(fetch(e.request).then((res) => {
    const copy = res.clone();
    caches.open(CACHE).then((c) => c.put(e.request, copy));
    return res;
  }).catch(() => caches.match(e.request).then((r) => r || caches.match('./'))));
});
// Phone notifications (a family call, even when the app is closed): show it, and open the app when tapped
self.addEventListener('push', (e) => {
  let d = {}; try { d = e.data ? e.data.json() : {}; } catch (x) { d = { title: e.data ? e.data.text() : 'सदा स्नेहा' }; }
  e.waitUntil(self.registration.showNotification(d.title || 'सदा स्नेहा', {
    body: d.body || '', tag: d.tag || 'sadasneha', renotify: true, requireInteraction: /^call-/.test(d.tag || ''),
    icon: './icon-192.png', badge: './icon-192.png', vibrate: [600, 300, 600, 300, 600, 300, 600], silent: false, data: { url: d.url || './' },
    // a call: "उठाएँ" opens the app straight to the ringing screen
    actions: /^call-/.test(d.tag || '') ? [{ action: 'answer', title: '📞 उठाएँ / Answer' }, { action: 'later', title: 'बाद में / Later' }] : [] }));
});
self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  if (e.action === 'later') return;
  const url = new URL((e.notification.data && e.notification.data.url) || './', self.registration.scope).href;
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((cs) => {
    const c = cs.find((x) => x.url.startsWith(self.registration.scope));
    return c ? c.focus() : self.clients.openWindow(url);
  }));
});

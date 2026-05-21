// MOFU Service Worker - プッシュ通知対応

self.addEventListener('push', function(event) {
  const data = event.data ? event.data.json() : {};
  const title = data.title || '🐾 今日のモフ';
  const options = {
    body: data.body || '今日もかわいい動物が待ってるよ',
    icon: '/mofu-app/icons/Icon-192.png',
    badge: '/mofu-app/icons/Icon-192.png',
    vibrate: [100, 50, 100],
    data: { url: data.url || '/mofu-app/' },
    actions: [
      { action: 'open', title: '見てみる 🐾' },
      { action: 'close', title: 'あとで' },
    ],
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  if (event.action === 'close') return;
  const url = event.notification.data?.url || '/mofu-app/';
  event.waitUntil(clients.openWindow(url));
});

self.addEventListener('install', (e) => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(clients.claim()));

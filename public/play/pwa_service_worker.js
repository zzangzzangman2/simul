'use strict';

// 설치 가능 여부만 안정적으로 제공하는 네트워크 우선 워커다. 게임 파일 캐시는
// 빌드 ID와 HTTP 헤더가 담당하므로 여기서는 낡은 파일을 따로 보관하지 않는다.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', () => {
  // 네트워크 요청은 브라우저의 기본 경로로 그대로 통과시킨다.
});

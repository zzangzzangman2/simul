'use strict';

const BUILD_ID_PATTERN = /^[0-9a-f]{12}$/;
const CACHE_PREFIX = 'decimal-static-';
const workerBuildId = new URL(self.location.href).searchParams.get('v');
const WORKER_BUILD_ID = BUILD_ID_PATTERN.test(workerBuildId ?? '')
  ? workerBuildId
  : 'unversioned';
const WORKER_CACHE_NAME = `${CACHE_PREFIX}${WORKER_BUILD_ID}`;

self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const cacheNames = await caches.keys();
    await Promise.all(
      cacheNames
        .filter((name) => name.startsWith(CACHE_PREFIX) && name !== WORKER_CACHE_NAME)
        .map((name) => caches.delete(name)),
    );
    await self.clients.claim();
  })());
});

function buildIdFromUrl(value) {
  if (!value) return null;
  try {
    const buildId = new URL(value).searchParams.get('appBuild');
    return BUILD_ID_PATTERN.test(buildId ?? '') ? buildId : null;
  } catch {
    return null;
  }
}

async function buildIdForRequest(event) {
  const clientId = event.clientId || event.resultingClientId;
  if (clientId) {
    const client = await self.clients.get(clientId);
    const clientBuildId = buildIdFromUrl(client?.url);
    if (clientBuildId) return clientBuildId;
  }

  return buildIdFromUrl(event.request.referrer) ?? WORKER_BUILD_ID;
}

async function respondWithVersionedAsset(event, requestUrl) {
  const buildId = await buildIdForRequest(event);
  requestUrl.searchParams.set('v', buildId);
  const versionedRequest = new Request(requestUrl.toString(), event.request);
  const cache = await caches.open(`${CACHE_PREFIX}${buildId}`);
  const cached = await cache.match(versionedRequest);
  if (cached) return cached;

  const response = await fetch(versionedRequest, { cache: 'reload' });
  if (response.ok && response.type === 'basic') {
    event.waitUntil(cache.put(versionedRequest, response.clone()));
  }
  return response;
}

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const requestUrl = new URL(event.request.url);
  const assetRoot = new URL('assets/', self.registration.scope);
  if (
    requestUrl.origin !== assetRoot.origin ||
    !requestUrl.pathname.startsWith(assetRoot.pathname)
  ) return;

  event.respondWith(respondWithVersionedAsset(event, requestUrl));
});

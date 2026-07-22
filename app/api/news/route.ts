export const runtime = "nodejs";

import { NextResponse } from "next/server";

import {
  generateDynamicNews,
  NewsConfigurationError,
  NewsInputError,
  parseDynamicNewsRequest,
} from "@/lib/dynamic-news";

const rateBuckets = new Map<string, { startedAt: number; count: number }>();
const RATE_WINDOW_MS = 60_000;
const RATE_LIMIT = 10;

function requestKey(request: Request) {
  const forwarded = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  return forwarded || request.headers.get("x-real-ip") || request.headers.get("origin") || "local";
}

function isRateLimited(request: Request) {
  const now = Date.now();
  const key = requestKey(request);
  const bucket = rateBuckets.get(key);
  if (!bucket || now - bucket.startedAt >= RATE_WINDOW_MS) {
    rateBuckets.set(key, { startedAt: now, count: 1 });
    return false;
  }
  bucket.count += 1;
  if (rateBuckets.size > 1000) {
    for (const [entryKey, entry] of rateBuckets) {
      if (now - entry.startedAt >= RATE_WINDOW_MS) rateBuckets.delete(entryKey);
    }
  }
  return bucket.count > RATE_LIMIT;
}

function allowedOrigin(request: Request) {
  const origin = request.headers.get("origin");
  if (!origin) return null;
  if (origin === new URL(request.url).origin) return origin;
  if (/^https?:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/i.test(origin)) {
    return origin;
  }
  const configured = (process.env.NEWS_ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  return configured.includes(origin) ? origin : null;
}

function responseHeaders(request: Request, cacheControl = "no-store") {
  const headers = new Headers({
    "Cache-Control": cacheControl,
    Vary: "Origin",
  });
  const origin = allowedOrigin(request);
  if (origin) headers.set("Access-Control-Allow-Origin", origin);
  return headers;
}

function jsonResponse(
  request: Request,
  body: unknown,
  status: number,
  cacheControl?: string,
) {
  return NextResponse.json(body, {
    status,
    headers: responseHeaders(request, cacheControl),
  });
}

export function OPTIONS(request: Request) {
  const origin = allowedOrigin(request);
  if (!origin) return new Response(null, { status: 403 });
  const headers = responseHeaders(request);
  headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  headers.set("Access-Control-Allow-Headers", "Content-Type");
  headers.set("Access-Control-Max-Age", "600");
  return new Response(null, { status: 204, headers });
}

export async function POST(request: Request) {
  if (request.headers.has("origin") && !allowedOrigin(request)) {
    return jsonResponse(request, { error: "허용되지 않은 요청 출처입니다." }, 403);
  }
  if (isRateLimited(request)) {
    return jsonResponse(request, { error: "뉴스 요청이 너무 많습니다. 잠시 뒤 다시 시도해 주세요." }, 429);
  }
  const length = Number(request.headers.get("content-length") || 0);
  if (length > 4096) {
    return jsonResponse(request, { error: "요청 본문이 너무 큽니다." }, 413);
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(request, { error: "유효한 JSON 본문이 필요합니다." }, 400);
  }

  try {
    const input = parseDynamicNewsRequest(body);
    const article = await generateDynamicNews(input, request.signal);
    return jsonResponse(request, article, 200, "private, max-age=300");
  } catch (error) {
    if (error instanceof NewsInputError) {
      return jsonResponse(request, { error: error.message }, 400);
    }
    if (error instanceof NewsConfigurationError) {
      return jsonResponse(
        request,
        { error: "뉴스 생성 서버가 아직 연결되지 않았습니다." },
        503,
      );
    }
    console.error("dynamic-news generation failed", error);
    return jsonResponse(
      request,
      { error: "동적 뉴스를 생성하지 못했습니다." },
      502,
    );
  }
}

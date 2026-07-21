export const runtime = "nodejs";

import { NextResponse } from "next/server";

import {
  generateDynamicNews,
  NewsConfigurationError,
  NewsInputError,
  parseDynamicNewsRequest,
} from "@/lib/dynamic-news";

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "유효한 JSON 본문이 필요합니다." },
      { status: 400 },
    );
  }

  try {
    const input = parseDynamicNewsRequest(body);
    const article = await generateDynamicNews(input, request.signal);
    return NextResponse.json(article, {
      headers: { "Cache-Control": "private, max-age=300" },
    });
  } catch (error) {
    if (error instanceof NewsInputError) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    if (error instanceof NewsConfigurationError) {
      return NextResponse.json(
        { error: "뉴스 생성 서버가 아직 연결되지 않았습니다." },
        { status: 503 },
      );
    }
    console.error("dynamic-news generation failed", error);
    return NextResponse.json(
      { error: "동적 뉴스를 생성하지 못했습니다." },
      { status: 502 },
    );
  }
}

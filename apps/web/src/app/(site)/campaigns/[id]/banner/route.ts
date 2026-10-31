import { type NextRequest, NextResponse } from "next/server";

import { API_URL } from "@/lib/admin/tokens";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const VERSION = /^[0-9a-z]{1,40}$/i;

/**
 * A campaign's banner photo, public: the rules page, its link previews and
 * the admin panel's preview show it. Browsers can't reach the Go API in
 * production, so this route passes its bytes on, at the same path the API
 * gives as `bannerUrl` (`/campaigns/{id}/banner?v=…`).
 */
export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const v = req.nextUrl.searchParams.get("v") ?? "";
  if (!UUID.test(id) || (v && !VERSION.test(v))) return new NextResponse("Not found", { status: 404 });

  // The API rate-limits by visitor; nginx's X-Forwarded-For tells it who that is.
  const xff = req.headers.get("x-forwarded-for");
  let res: Response;
  try {
    res = await fetch(`${API_URL}/campaigns/${id}/banner${v ? `?v=${v}` : ""}`, {
      headers: { Accept: "image/*", "User-Agent": "varsitykotha-web", ...(xff ? { "X-Forwarded-For": xff } : {}) },
      cache: "no-store",
      signal: AbortSignal.timeout(20_000),
    });
  } catch {
    return new NextResponse("The server can't be reached", { status: 502 });
  }
  if (!res.ok || !res.body) {
    const status = res.status === 404 || res.status === 429 ? res.status : 502;
    return new NextResponse(status === 404 ? "Not found" : "Image unavailable", { status, headers: { "Cache-Control": "public, max-age=60" } });
  }
  const type = res.headers.get("content-type") ?? "";
  if (!type.startsWith("image/")) return new NextResponse("Not an image", { status: 502 });

  const headers: Record<string, string> = {
    "Content-Type": type,
    "Cache-Control": res.headers.get("cache-control") ?? "public, max-age=300",
    "X-Content-Type-Options": "nosniff",
    "Content-Disposition": "inline",
  };
  const length = res.headers.get("content-length");
  if (length) headers["Content-Length"] = length;
  return new NextResponse(res.body, { status: 200, headers });
}

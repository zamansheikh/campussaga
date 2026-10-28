import { cookies } from "next/headers";
import { type NextRequest, NextResponse } from "next/server";

import { API_URL, COOKIE } from "@/lib/admin/tokens";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Campus Voice photos for the moderation pages. The browser never gets the
 * admin's token: this route fetches the image from the Go API with it (the
 * API applies the same visibility rules as the photo's issue) and passes
 * the bytes on, never cached.
 */
export async function GET(req: NextRequest, { params }: { params: Promise<{ imageId: string }> }) {
  const { imageId } = await params;
  const size = req.nextUrl.searchParams.get("size") === "full" ? "full" : "thumb";
  if (!UUID.test(imageId)) return new NextResponse("Not found", { status: 404 });

  const token = (await cookies()).get(COOKIE.access)?.value;
  if (!token) return new NextResponse("Sign in", { status: 401 });

  let res: Response;
  try {
    res = await fetch(`${API_URL}/issues/images/${imageId}?size=${size}`, {
      headers: { Authorization: `Bearer ${token}`, Accept: "image/*" },
      cache: "no-store",
      signal: AbortSignal.timeout(20_000),
    });
  } catch {
    return new NextResponse("The server can't be reached", { status: 502 });
  }
  if (!res.ok || !res.body) {
    const status = res.status === 401 || res.status === 403 || res.status === 404 ? res.status : 502;
    return new NextResponse(status === 502 ? "Image unavailable" : "Not found", { status });
  }
  const type = res.headers.get("content-type") ?? "";
  if (!type.startsWith("image/")) return new NextResponse("Not an image", { status: 502 });

  return new NextResponse(res.body, {
    status: 200,
    headers: {
      "Content-Type": type,
      "Cache-Control": "private, no-store",
      "X-Content-Type-Options": "nosniff",
      "Content-Disposition": "inline",
    },
  });
}

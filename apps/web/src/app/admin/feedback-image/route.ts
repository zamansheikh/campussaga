import { cookies } from "next/headers";
import { type NextRequest, NextResponse } from "next/server";

import { API_URL, COOKIE } from "@/lib/admin/tokens";

/**
 * Screenshots attached to feedback. The browser never gets the admin's
 * token: this route fetches the image from the Go API with it and passes
 * the bytes on. Only addresses on the API's own host are fetched.
 */
export async function GET(req: NextRequest) {
  let src = req.nextUrl.searchParams.get("src") ?? "";
  // The API gives the student's address (/feedback/{id}/images/…), which
  // only the owner may open; the panel uses the admin one.
  if (src.startsWith("/feedback/")) src = `/admin${src}`;
  const api = new URL(API_URL);
  let target: URL;
  try {
    // A path is read against the API's address; "/api/v1/..." paths keep their prefix.
    target = src.startsWith("/") ? new URL(src.startsWith("/api/") ? `${api.origin}${src}` : `${API_URL}${src}`) : new URL(src);
  } catch {
    return new NextResponse("Not found", { status: 404 });
  }
  if (target.origin !== api.origin || target.pathname.includes("..")) return new NextResponse("Not found", { status: 404 });

  const token = (await cookies()).get(COOKIE.access)?.value;
  if (!token) return new NextResponse("Sign in", { status: 401 });

  let res: Response;
  try {
    res = await fetch(target, {
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

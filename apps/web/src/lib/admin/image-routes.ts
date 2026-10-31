import "server-only";

import { cookies } from "next/headers";
import { type NextRequest, NextResponse } from "next/server";

import { errorMessage } from "@/lib/admin/errors";
import { API_URL, COOKIE } from "@/lib/admin/tokens";

export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const VERSION = /^[0-9a-z]{1,40}$/i;

/** What the panel's image fields read back. */
export type ImageUploadResult = { ok: true; url: string | null } | { ok: false; error: string };

function fail(status: number, error: string) {
  return NextResponse.json({ ok: false, error } satisfies ImageUploadResult, { status });
}

/** Only the panel's own pages may post (the browser always sends Origin on a POST). */
function sameOrigin(req: NextRequest): boolean {
  const origin = req.headers.get("origin");
  const host = (req.headers.get("x-forwarded-host") ?? req.headers.get("host") ?? "").split(",")[0]?.trim();
  if (!origin || !host) return false;
  try {
    return new URL(origin).host === host;
  } catch {
    return false;
  }
}

/**
 * Forwards a multipart "image" upload to the Go API with the admin's token,
 * which the browser never gets (Server Actions take 1 MB at most). Answers
 * with the new image URL, read from the entity the API returns by [urlField],
 * or a plain-words error.
 */
export async function forwardImage(
  req: NextRequest,
  { id, apiPath, urlField, maxBytes, notFound }: { id: string; apiPath: string; urlField: string; maxBytes: number; notFound: string },
): Promise<NextResponse> {
  if (!UUID.test(id)) return fail(404, errorMessage(notFound));
  if (!sameOrigin(req)) return fail(403, errorMessage("FORBIDDEN"));
  const token = (await cookies()).get(COOKIE.access)?.value;
  if (!token) return fail(401, errorMessage("UNAUTHORIZED"));

  let file: FormDataEntryValue | null;
  try {
    file = (await req.formData()).get("image");
  } catch {
    return fail(400, "Choose an image to upload.");
  }
  if (!(file instanceof File) || file.size === 0) return fail(400, "Choose an image to upload.");
  if (file.size > maxBytes) return fail(413, `This image is larger than ${Math.round(maxBytes / (1 << 20))} MB. Choose a smaller one.`);

  const body = new FormData();
  body.set("image", file, file.name || "image");
  let res: Response;
  try {
    res = await fetch(`${API_URL}${apiPath}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, Accept: "application/json", "User-Agent": "varsitykotha-web-admin" },
      body,
      cache: "no-store",
      signal: AbortSignal.timeout(60_000),
    });
  } catch {
    return fail(502, errorMessage("NETWORK"));
  }
  let json: { success?: boolean; data?: Record<string, unknown>; error?: { code: string; message: string; details?: unknown } };
  try {
    json = await res.json();
  } catch {
    return fail(502, errorMessage("INTERNAL_ERROR"));
  }
  if (!res.ok || json.success === false || !json.data) {
    const e = json.error;
    return fail(res.status >= 400 && res.status < 500 ? res.status : 502, errorMessage(e?.code ?? "INTERNAL_ERROR", e?.details, e?.message));
  }
  const url = json.data[urlField];
  return NextResponse.json({ ok: true, url: typeof url === "string" ? url : null } satisfies ImageUploadResult);
}

/**
 * Passes a public image from the API on, at the same path the API gives
 * (browsers can't reach the API in production). Used for the admin panel's
 * previews of ad images and sponsor logos.
 */
export async function passImage(req: NextRequest, apiPath: string, id: string): Promise<NextResponse> {
  const v = req.nextUrl.searchParams.get("v") ?? "";
  if (!UUID.test(id) || (v && !VERSION.test(v))) return new NextResponse("Not found", { status: 404 });
  const xff = req.headers.get("x-forwarded-for");
  let res: Response;
  try {
    res = await fetch(`${API_URL}${apiPath}${v ? `?v=${v}` : ""}`, {
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

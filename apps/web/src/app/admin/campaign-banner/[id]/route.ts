import { revalidatePath } from "next/cache";
import { cookies } from "next/headers";
import { type NextRequest, NextResponse } from "next/server";

import { errorMessage } from "@/lib/admin/errors";
import type { AdminCampaign } from "@/lib/admin/growth";
import { API_URL, COOKIE } from "@/lib/admin/tokens";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
/** The API takes photos up to 8 MB. */
const MAX_BYTES = 8 << 20;

/** What the panel's banner field reads back (see banner-field.tsx). */
type BannerUploadResult = { ok: true; bannerUrl: string | null } | { ok: false; error: string };

function fail(status: number, error: string) {
  return NextResponse.json({ ok: false, error } satisfies BannerUploadResult, { status });
}

/** Only the panel's own pages may post here (the browser always sends Origin on a POST). */
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
 * Uploads a campaign's banner photo (multipart field "image"). Server
 * Actions take 1 MB at most, so the panel posts the file here, and this
 * route forwards it to the Go API with the admin's token, which the browser
 * never gets. Answers with the new `bannerUrl` or a plain-words error.
 */
export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!UUID.test(id)) return fail(404, errorMessage("CAMPAIGN_NOT_FOUND"));
  if (!sameOrigin(req)) return fail(403, errorMessage("FORBIDDEN"));
  const token = (await cookies()).get(COOKIE.access)?.value;
  if (!token) return fail(401, errorMessage("UNAUTHORIZED"));

  let file: FormDataEntryValue | null;
  try {
    file = (await req.formData()).get("image");
  } catch {
    return fail(400, "Choose a photo to upload.");
  }
  if (!(file instanceof File) || file.size === 0) return fail(400, "Choose a photo to upload.");
  if (file.size > MAX_BYTES) return fail(413, "This photo is larger than 8 MB. Choose a smaller one.");

  const body = new FormData();
  body.set("image", file, file.name || "banner");
  let res: Response;
  try {
    res = await fetch(`${API_URL}/admin/campaigns/${id}/banner`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, Accept: "application/json", "User-Agent": "varsitykotha-web-admin" },
      body,
      cache: "no-store",
      signal: AbortSignal.timeout(60_000),
    });
  } catch {
    return fail(502, errorMessage("NETWORK"));
  }
  let json: { success?: boolean; data?: AdminCampaign; error?: { code: string; message: string; details?: unknown } };
  try {
    json = await res.json();
  } catch {
    return fail(502, errorMessage("INTERNAL_ERROR"));
  }
  if (!res.ok || json.success === false || !json.data) {
    const e = json.error;
    return fail(res.status >= 400 && res.status < 500 ? res.status : 502, errorMessage(e?.code ?? "INTERNAL_ERROR", e?.details, e?.message));
  }

  revalidatePath("/admin/campaigns");
  revalidatePath(`/admin/campaigns/${id}`);
  revalidatePath(`/campaigns/${id}`);
  return NextResponse.json({ ok: true, bannerUrl: json.data.bannerUrl ?? null } satisfies BannerUploadResult);
}

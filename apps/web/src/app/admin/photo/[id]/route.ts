import { cookies } from "next/headers";

import { API_URL, COOKIE } from "@/lib/admin/tokens";

/**
 * A user's uploaded profile photo, fetched from the API as the signed-in
 * admin (the API only serves photos to signed-in users). ?v= is the photo
 * version, so each one can be cached for long in this browser.
 */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const token = (await cookies()).get(COOKIE.access)?.value;
  if (!token || !/^[0-9a-f-]{36}$/i.test(id)) return new Response(null, { status: 404 });
  const v = new URL(req.url).searchParams.get("v") ?? "";
  const res = await fetch(`${API_URL}/users/${id}/photo?v=${encodeURIComponent(v)}`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store",
  });
  if (!res.ok || !res.body) return new Response(null, { status: res.status === 404 ? 404 : 502 });
  return new Response(res.body, {
    headers: { "Content-Type": "image/jpeg", "Cache-Control": "private, max-age=604800" },
  });
}

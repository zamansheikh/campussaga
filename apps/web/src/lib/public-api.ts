import "server-only";

import { API_URL } from "@/lib/admin/tokens";

/**
 * GET from the Go API without signing in (public pages). Returns null on 404,
 * any other error or a slow answer, so a page can fall back to a generic view.
 */
export async function publicApi<T>(path: string, revalidate = 60): Promise<T | null> {
  try {
    const res = await fetch(`${API_URL}${path}`, {
      headers: { Accept: "application/json", "User-Agent": "varsitykotha-web" },
      next: { revalidate },
      signal: AbortSignal.timeout(5_000),
    });
    if (!res.ok) return null;
    const json = (await res.json()) as { success?: boolean; data?: T };
    return json.success === false ? null : (json.data ?? null);
  } catch {
    return null;
  }
}

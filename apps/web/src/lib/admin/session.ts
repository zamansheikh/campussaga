import "server-only";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { cache } from "react";

import { ApiError } from "@/lib/admin/errors";
import { callApi, COOKIE } from "@/lib/admin/tokens";
import type { Me, PanelRole } from "@/lib/admin/types";

const AUTH_CODES = new Set(["UNAUTHORIZED", "TOKEN_EXPIRED", "TOKEN_INVALID", "SESSION_ENDED", "REFRESH_INVALID", "ACCOUNT_BLOCKED"]);

/**
 * Calls the Go API as the signed-in admin. A dead session sends the admin
 * to the login page (the proxy already refreshed the token if it could).
 */
export async function api<T>(path: string, init: { method?: string; body?: unknown } = {}): Promise<T> {
  const store = await cookies();
  const accessToken = store.get(COOKIE.access)?.value;
  if (!accessToken) redirect("/admin/login");
  try {
    return await callApi<T>(path, { ...init, accessToken });
  } catch (e) {
    if (e instanceof ApiError && AUTH_CODES.has(e.code)) redirect("/admin/login?expired=1");
    if (e instanceof ApiError && e.code === "NOT_ADMIN") {
      // A moderator on an admin-only page: back to what they can use.
      const me = path === "/me" ? undefined : await getAdmin();
      redirect(me?.role === "moderator" ? "/admin/moderation" : "/admin/login?error=not_admin");
    }
    throw e;
  }
}

/** The roles that can use the panel: admins see everything, moderators only Moderation. */
export function panelRole(role: string): PanelRole | null {
  return role === "admin" || role === "moderator" ? role : null;
}

/** The signed-in admin or moderator (once per request). */
export const getAdmin = cache(async (): Promise<Me & { role: PanelRole }> => {
  const me = await api<Me>("/me");
  const role = panelRole(me.role);
  if (!role) redirect("/admin/login?error=not_admin");
  return { ...me, role };
});

/** Admin-only pages: a moderator is sent to Moderation instead. */
export async function requireAdmin(): Promise<Me & { role: "admin" }> {
  const me = await getAdmin();
  if (me.role !== "admin") redirect("/admin/moderation");
  return { ...me, role: "admin" };
}

/** Builds `?a=1&b=2` from defined, non-empty values. */
export function query(params: Record<string, string | number | boolean | undefined | null>): string {
  const q = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== "") q.set(k, String(v));
  }
  const s = q.toString();
  return s ? `?${s}` : "";
}

/** One "now" per request, so relative times on a page agree. */
export const requestNow = cache((): number => Date.now());

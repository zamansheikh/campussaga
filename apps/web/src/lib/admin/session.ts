import "server-only";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { cache } from "react";

import { ApiError } from "@/lib/admin/errors";
import { callApi, COOKIE } from "@/lib/admin/tokens";
import type { Me } from "@/lib/admin/types";

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
    if (e instanceof ApiError && e.code === "NOT_ADMIN") redirect("/admin/login?error=not_admin");
    throw e;
  }
}

/** The signed-in admin (once per request). */
export const getAdmin = cache(async (): Promise<Me> => {
  const me = await api<Me>("/me");
  if (me.role !== "admin") redirect("/admin/login?error=not_admin");
  return me;
});

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

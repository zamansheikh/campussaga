// Admin tokens: kept in httpOnly cookies on /admin, never seen by browser JS.
// Used by the proxy (refresh before a page renders) and by Server Actions.

import { ApiError } from "@/lib/admin/errors";
import type { Tokens } from "@/lib/admin/types";

export const API_URL = (process.env.API_URL ?? "http://127.0.0.1:8090/api/v1").replace(/\/$/, "");

export const COOKIE = {
  access: "cs_admin_at",
  accessExpires: "cs_admin_at_exp",
  refresh: "cs_admin_rt",
} as const;

/** Refresh this long before the access token expires. */
export const REFRESH_EARLY_MS = 60_000;

export type CookieToSet = {
  name: string;
  value: string;
  options: {
    httpOnly: true;
    secure: boolean;
    sameSite: "lax";
    path: string;
    expires?: Date;
    maxAge?: number;
  };
};

const base = {
  httpOnly: true as const,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/admin",
};

/** Cookies that store a fresh token pair. */
export function tokenCookies(t: Tokens): CookieToSet[] {
  const refreshExpires = new Date(t.refreshTokenExpiresAt);
  return [
    // The access cookie lives as long as the refresh one: the proxy needs
    // to see an expired access token to know it should refresh.
    { name: COOKIE.access, value: t.accessToken, options: { ...base, expires: refreshExpires } },
    {
      name: COOKIE.accessExpires,
      value: String(new Date(t.accessTokenExpiresAt).getTime()),
      options: { ...base, expires: refreshExpires },
    },
    { name: COOKIE.refresh, value: t.refreshToken, options: { ...base, expires: refreshExpires } },
  ];
}

/** Cookies that sign the admin out. */
export function clearedCookies(): CookieToSet[] {
  return Object.values(COOKIE).map((name) => ({ name, value: "", options: { ...base, maxAge: 0 } }));
}

/** POST/GET to the Go API and unwrap the envelope. Throws ApiError. */
export async function callApi<T>(
  path: string,
  init: { method?: string; body?: unknown; accessToken?: string } = {},
): Promise<T> {
  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, {
      method: init.method ?? "GET",
      headers: {
        Accept: "application/json",
        ...(init.body !== undefined ? { "Content-Type": "application/json" } : {}),
        ...(init.accessToken ? { Authorization: `Bearer ${init.accessToken}` } : {}),
        "User-Agent": "varsitykotha-web-admin",
      },
      body: init.body !== undefined ? JSON.stringify(init.body) : undefined,
      cache: "no-store",
      signal: AbortSignal.timeout(20_000),
    });
  } catch (e) {
    throw new ApiError(503, "NETWORK", e instanceof Error ? e.message : "network error");
  }
  if (res.status === 204) return undefined as T;
  let json: { success?: boolean; data?: T; error?: { code: string; message: string; details?: unknown } };
  try {
    json = await res.json();
  } catch {
    throw new ApiError(res.status, res.ok ? "INTERNAL_ERROR" : `HTTP_${res.status}`, `HTTP ${res.status}`);
  }
  if (!res.ok || json.success === false) {
    const err = json.error ?? { code: `HTTP_${res.status}`, message: `HTTP ${res.status}` };
    throw new ApiError(res.status, err.code, err.message, err.details);
  }
  return json.data as T;
}

// A refresh token works once: the API revokes the whole session if an old
// one is reused. Pages often fire several requests at once, so concurrent
// refreshes with the same token share one call, and the result is kept for
// a short while for requests that still carry the old cookie.
const inflight = new Map<string, Promise<Tokens>>();
const recent = new Map<string, { tokens: Tokens; at: number }>();
const RECENT_MS = 30_000;

export function refreshOnce(refreshToken: string): Promise<Tokens> {
  const now = Date.now();
  for (const [k, v] of recent) if (now - v.at > RECENT_MS) recent.delete(k);
  const done = recent.get(refreshToken);
  if (done) return Promise.resolve(done.tokens);
  let p = inflight.get(refreshToken);
  if (!p) {
    p = callApi<Tokens>("/auth/refresh", { method: "POST", body: { refreshToken } })
      .then((tokens) => {
        recent.set(refreshToken, { tokens, at: Date.now() });
        return tokens;
      })
      .finally(() => inflight.delete(refreshToken));
    inflight.set(refreshToken, p);
  }
  return p;
}

/** Whether a stored access token should be refreshed now. */
export function needsRefresh(expiresAtMs: string | undefined): boolean {
  const exp = Number(expiresAtMs);
  return !Number.isFinite(exp) || exp - REFRESH_EARLY_MS <= Date.now();
}

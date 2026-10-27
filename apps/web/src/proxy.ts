import { NextResponse, type NextRequest } from "next/server";

import { ApiError } from "@/lib/admin/errors";
import { clearedCookies, COOKIE, needsRefresh, refreshOnce, tokenCookies } from "@/lib/admin/tokens";

// Runs before every /admin request: sends signed-out visitors to the login
// page, and refreshes the access token shortly before it expires, so pages
// and Server Actions always see a valid one.
export async function proxy(req: NextRequest) {
  const { pathname, search } = req.nextUrl;
  if (pathname === "/admin/login" || pathname.startsWith("/admin/login/")) return NextResponse.next();

  const refresh = req.cookies.get(COOKIE.refresh)?.value;
  if (!refresh) return toLogin(req, pathname + search);

  const access = req.cookies.get(COOKIE.access)?.value;
  if (access && !needsRefresh(req.cookies.get(COOKIE.accessExpires)?.value)) return NextResponse.next();

  try {
    const tokens = await refreshOnce(refresh);
    const cookies = tokenCookies(tokens);
    // Let this request's render see the new tokens, and store them.
    for (const c of cookies) req.cookies.set(c.name, c.value);
    const res = NextResponse.next({ request: req });
    for (const c of cookies) res.cookies.set(c.name, c.value, c.options);
    return res;
  } catch (e) {
    // Server unreachable: let the page show its own error instead of
    // signing the admin out.
    if (e instanceof ApiError && e.code === "NETWORK") return NextResponse.next();
    return toLogin(req, pathname + search, true);
  }
}

function toLogin(req: NextRequest, next: string, expired = false) {
  const url = req.nextUrl.clone();
  url.pathname = "/admin/login";
  url.search = "";
  if (next && next !== "/admin") url.searchParams.set("next", next);
  if (expired) url.searchParams.set("expired", "1");
  const res = NextResponse.redirect(url);
  if (expired) for (const c of clearedCookies()) res.cookies.set(c.name, c.value, c.options);
  return res;
}

export const config = {
  matcher: ["/admin/:path*"],
};

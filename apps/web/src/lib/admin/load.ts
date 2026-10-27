import "server-only";

import { unstable_rethrow } from "next/navigation";

import { ApiError, errorMessage } from "@/lib/admin/errors";

/**
 * Runs a page's data load and turns API errors into a message the page can
 * show (redirects and other Next.js control flow still propagate).
 */
export async function load<T>(fn: () => Promise<T>): Promise<{ data: T; error?: undefined } | { data?: undefined; error: string }> {
  try {
    return { data: await fn() };
  } catch (e) {
    unstable_rethrow(e);
    if (e instanceof ApiError) return { error: errorMessage(e.code, e.details, e.message) };
    console.error(e);
    return { error: errorMessage("INTERNAL_ERROR") };
  }
}

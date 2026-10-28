"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { z } from "zod";

import { ApiError, errorMessage } from "@/lib/admin/errors";
import { callApi, clearedCookies, COOKIE, tokenCookies } from "@/lib/admin/tokens";
import type { CodeSent, SignedIn } from "@/lib/admin/types";

export type LoginState =
  | { step: "email"; error?: string; email?: string }
  | { step: "code"; email: string; resendAfterSeconds: number; sentAt: number; error?: string; notice?: string };

const emailSchema = z.email().max(254);

/** Sends a sign-in code (only admin accounts actually get one). */
export async function requestCode(_prev: LoginState, form: FormData): Promise<LoginState> {
  const raw = String(form.get("email") ?? "").trim().toLowerCase();
  const parsed = emailSchema.safeParse(raw);
  if (!parsed.success) return { step: "email", email: raw, error: "Enter a valid email address." };
  try {
    const sent = await callApi<CodeSent>("/admin/auth/code", { method: "POST", body: { email: parsed.data } });
    return {
      step: "code",
      email: parsed.data,
      resendAfterSeconds: sent?.resendAfterSeconds ?? 60,
      sentAt: Date.now(),
    };
  } catch (e) {
    return { step: "email", email: raw, error: message(e) };
  }
}

/** Resends the code from the code step. */
export async function resendCode(prev: LoginState): Promise<LoginState> {
  if (prev.step !== "code") return prev;
  try {
    const sent = await callApi<CodeSent>("/admin/auth/code", { method: "POST", body: { email: prev.email } });
    return { ...prev, error: undefined, resendAfterSeconds: sent?.resendAfterSeconds ?? 60, sentAt: Date.now(), notice: "We sent a new code." };
  } catch (e) {
    return { ...prev, notice: undefined, error: message(e) };
  }
}

/** Checks the code, stores the session in httpOnly cookies, opens the panel. */
export async function verifyCode(prev: LoginState, form: FormData): Promise<LoginState> {
  if (prev.step !== "code") return prev;
  const code = String(form.get("code") ?? "").replace(/\D/g, "");
  if (code.length !== 6) return { ...prev, notice: undefined, error: "Enter the 6-digit code from the email." };
  let signedIn: SignedIn;
  try {
    signedIn = await callApi<SignedIn>("/admin/auth/verify", { method: "POST", body: { email: prev.email, code } });
  } catch (e) {
    return { ...prev, notice: undefined, error: message(e) };
  }
  const store = await cookies();
  for (const c of tokenCookies(signedIn.tokens)) store.set(c.name, c.value, c.options);
  const next = safeNext(String(form.get("next") ?? ""));
  // Moderators only use Moderation: straight there unless they asked for a page in it.
  redirect(signedIn.user.role === "moderator" && !next.startsWith("/admin/moderation") ? "/admin/moderation" : next);
}

/** Ends the session on the server and forgets it here. */
export async function signOut(): Promise<void> {
  const store = await cookies();
  const accessToken = store.get(COOKIE.access)?.value;
  if (accessToken) {
    await callApi("/auth/logout", { method: "POST", accessToken }).catch(() => undefined);
  }
  for (const c of clearedCookies()) store.set(c.name, c.value, c.options);
  redirect("/admin/login");
}

function message(e: unknown) {
  if (e instanceof ApiError) return errorMessage(e.code, e.details, e.message);
  console.error(e);
  return errorMessage("INTERNAL_ERROR");
}

/** Only same-site admin paths, so ?next= can't send anyone elsewhere. */
function safeNext(next: string) {
  return next.startsWith("/admin") && !next.startsWith("//") && !next.startsWith("/admin/login") ? next : "/admin";
}

/** One entry point for the two-step form (useActionState). */
export async function login(prev: LoginState, form: FormData): Promise<LoginState> {
  switch (form.get("intent")) {
    case "verify":
      return verifyCode(prev, form);
    case "resend":
      return resendCode(prev);
    case "back":
      return { step: "email", email: prev.step === "code" ? prev.email : prev.email };
    default:
      return requestCode(prev, form);
  }
}

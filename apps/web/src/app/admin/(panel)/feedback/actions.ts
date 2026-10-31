"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";

const id = z.uuid();
const statuses = ["new", "seen", "planned", "in_progress", "done", "wont_do"] as const;

function revalidate(feedbackId: string) {
  revalidatePath("/admin/feedback", "layout");
  revalidatePath("/admin", "layout");
  revalidatePath(`/admin/feedback/${feedbackId}`);
}

/** Replies as the team; the student gets a push. */
export async function replyToFeedback(feedbackId: string, body: string): Promise<ActionResult> {
  const fid = id.safeParse(feedbackId);
  const text = z.string().trim().min(1, "Write a reply first.").max(2000, "Keep the reply under 2000 characters.").safeParse(body);
  if (!fid.success) return { ok: false, error: "That feedback isn't valid." };
  if (!text.success) return { ok: false, error: text.error.issues[0]?.message ?? "That reply isn't valid." };
  try {
    await api(`/admin/feedback/${fid.data}/messages`, { method: "POST", body: { body: text.data } });
    revalidate(fid.data);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Changes the status; the student gets a push. */
export async function setFeedbackStatus(feedbackId: string, status: string): Promise<ActionResult> {
  const fid = id.safeParse(feedbackId);
  const st = z.enum(statuses).safeParse(status);
  if (!fid.success || !st.success) return { ok: false, error: "That change isn't valid." };
  try {
    await api(`/admin/feedback/${fid.data}`, { method: "PATCH", body: { status: st.data } });
    revalidate(fid.data);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

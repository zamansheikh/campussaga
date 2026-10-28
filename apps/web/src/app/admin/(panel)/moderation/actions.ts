"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import { formatDate } from "@/lib/format";

const id = z.uuid();
const action = z.enum(["approve", "hide", "remove", "restore"]);
const reason = z.string().trim().max(300);

const moderateSchema = z
  .object({ id, action, reason })
  .refine((v) => v.action !== "remove" || v.reason.length > 0, "Add a reason for removing (the author sees it).");

const banSchema = z.object({
  id,
  days: z.union([z.literal(7), z.literal(30), z.null()]),
  reason: z.string().trim().min(1, "Add a reason for the ban.").max(300),
});

const dismissSchema = z.object({ targetType: z.enum(["issue", "comment"]), targetId: id });

function revalidate(issueId?: string) {
  revalidatePath("/admin/moderation");
  if (issueId) revalidatePath(`/admin/moderation/issues/${issueId}`);
}

function invalid(e: z.ZodError) {
  return { ok: false as const, error: e.issues[0]?.message ?? "That change isn't valid." };
}

/** Approve / hide / remove / restore an issue. */
export async function moderateIssue(input: { id: string; action: string; reason?: string }): Promise<ActionResult> {
  const parsed = moderateSchema.safeParse({ ...input, reason: input.reason ?? "" });
  if (!parsed.success) return invalid(parsed.error);
  const { id: issueId, action: act, reason: why } = parsed.data;
  try {
    await api(`/moderation/issues/${issueId}`, { method: "POST", body: { action: act, ...(why ? { reason: why } : {}) } });
    revalidate(issueId);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Approve / hide / remove / restore one comment of an issue. */
export async function moderateComment(input: {
  id: string;
  issueId: string;
  action: string;
  reason?: string;
}): Promise<ActionResult> {
  const parsed = moderateSchema.safeParse({ id: input.id, action: input.action, reason: input.reason ?? "" });
  const issueId = id.safeParse(input.issueId);
  if (!parsed.success) return invalid(parsed.error);
  if (!issueId.success) return { ok: false, error: "That issue isn't valid." };
  const { id: commentId, action: act, reason: why } = parsed.data;
  try {
    await api(`/moderation/comments/${commentId}`, { method: "POST", body: { action: act, ...(why ? { reason: why } : {}) } });
    revalidate(issueId.data);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/**
 * Bans whoever wrote an issue or comment from posting, commenting, voting
 * and reporting. The server resolves the author; nothing about them comes
 * back.
 */
export async function banAuthor(input: {
  targetType: "issue" | "comment";
  id: string;
  issueId: string;
  days: 7 | 30 | null;
  reason: string;
}): Promise<ActionResult> {
  const parsed = banSchema.safeParse({ id: input.id, days: input.days, reason: input.reason });
  const issueId = id.safeParse(input.issueId);
  if (!parsed.success) return invalid(parsed.error);
  if (!issueId.success || (input.targetType !== "issue" && input.targetType !== "comment")) {
    return { ok: false, error: "That item isn't valid." };
  }
  const path = input.targetType === "issue" ? "issues" : "comments";
  try {
    const res = await api<{ bannedUntil: string | null }>(`/moderation/${path}/${parsed.data.id}/ban-author`, {
      method: "POST",
      body: { days: parsed.data.days, reason: parsed.data.reason },
    });
    revalidate(issueId.data);
    return {
      ok: true,
      message: res?.bannedUntil ? `The author is banned until ${formatDate(res.bannedUntil)}` : "The author is banned for good",
    };
  } catch (e) {
    return failure(e);
  }
}

/** Dismisses the open reports on an issue or comment. */
export async function dismissReports(input: {
  targetType: "issue" | "comment";
  targetId: string;
  issueId: string;
}): Promise<ActionResult> {
  const parsed = dismissSchema.safeParse({ targetType: input.targetType, targetId: input.targetId });
  const issueId = id.safeParse(input.issueId);
  if (!parsed.success || !issueId.success) return { ok: false, error: "That item isn't valid." };
  try {
    await api("/moderation/reports/dismiss", { method: "POST", body: parsed.data });
    revalidate(issueId.data);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

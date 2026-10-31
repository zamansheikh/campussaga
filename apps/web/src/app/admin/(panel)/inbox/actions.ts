"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import type { CampusAdmin } from "@/lib/admin/types";

const id = z.uuid();
const anyId = z.string().trim().regex(/^[0-9a-zA-Z-]{1,64}$/);

function revalidate() {
  revalidatePath("/admin", "layout");
}

export async function resolveEscalation(escalationId: string, resolution: string): Promise<ActionResult> {
  const eid = anyId.safeParse(escalationId);
  const text = z.string().trim().min(1, "Write what you did.").max(300, "Keep it under 300 characters.").safeParse(resolution);
  if (!eid.success) return { ok: false, error: "That request isn't valid." };
  if (!text.success) return { ok: false, error: text.error.issues[0]?.message ?? "That isn't valid." };
  try {
    await api(`/admin/escalations/${eid.data}/resolve`, { method: "POST", body: { resolution: text.data } });
    revalidate();
    return { ok: true };
  } catch (e) {
    revalidate();
    return failure(e);
  }
}

export async function approveDomainRequest(requestId: string, universityId: string): Promise<ActionResult> {
  const rid = anyId.safeParse(requestId);
  const uid = id.safeParse(universityId);
  if (!rid.success || !uid.success) return { ok: false, error: "Choose a university first." };
  try {
    await api(`/admin/domain-requests/${rid.data}/approve`, { method: "POST", body: { universityId: uid.data } });
    revalidate();
    revalidatePath("/admin/universities");
    return { ok: true };
  } catch (e) {
    revalidate();
    return failure(e);
  }
}

export async function rejectDomainRequest(requestId: string): Promise<ActionResult> {
  const rid = anyId.safeParse(requestId);
  if (!rid.success) return { ok: false, error: "That request isn't valid." };
  try {
    await api(`/admin/domain-requests/${rid.data}/reject`, { method: "POST", body: {} });
    revalidate();
    return { ok: true };
  } catch (e) {
    revalidate();
    return failure(e);
  }
}

/** The campus admins of one university. */
export async function listCampusAdmins(universityId: string): Promise<ActionResult<CampusAdmin[]>> {
  const uid = id.safeParse(universityId);
  if (!uid.success) return { ok: false, error: "That university isn't valid." };
  try {
    const res = await api<CampusAdmin[] | { items: CampusAdmin[] }>(`/admin/campus-admins?universityId=${uid.data}`);
    return { ok: true, data: Array.isArray(res) ? res : (res.items ?? []) };
  } catch (e) {
    return failure(e);
  }
}

/** Appoints a verified student of their own university. */
export async function appointCampusAdmin(userId: string): Promise<ActionResult> {
  const uid = id.safeParse(userId);
  if (!uid.success) return { ok: false, error: "That user isn't valid." };
  try {
    await api("/admin/campus-admins", { method: "POST", body: { userId: uid.data } });
    revalidate();
    revalidatePath("/admin/users", "layout");
    revalidatePath("/admin/universities", "layout");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

export async function removeCampusAdmin(userId: string): Promise<ActionResult> {
  const uid = id.safeParse(userId);
  if (!uid.success) return { ok: false, error: "That user isn't valid." };
  try {
    await api(`/admin/campus-admins/${uid.data}`, { method: "DELETE" });
    revalidate();
    revalidatePath("/admin/users", "layout");
    revalidatePath("/admin/universities", "layout");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

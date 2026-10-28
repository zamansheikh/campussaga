"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";

const uuid = z.uuid();

function ids(...v: string[]) {
  return v.every((x) => uuid.safeParse(x).success);
}

export async function setMemberRole(groupId: string, userId: string, role: "cr" | "member"): Promise<ActionResult> {
  if (!ids(groupId, userId) || !["cr", "member"].includes(role)) return { ok: false, error: "That change isn't valid." };
  try {
    await api(`/admin/groups/${groupId}/members/${userId}`, { method: "PUT", body: { role } });
    revalidatePath(`/admin/groups/${groupId}`);
    revalidatePath("/admin/groups");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

export async function removeMember(groupId: string, userId: string): Promise<ActionResult> {
  if (!ids(groupId, userId)) return { ok: false, error: "That change isn't valid." };
  try {
    await api(`/admin/groups/${groupId}/members/${userId}`, { method: "DELETE" });
    revalidatePath(`/admin/groups/${groupId}`);
    revalidatePath("/admin/groups");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

export async function deleteGroup(groupId: string): Promise<ActionResult> {
  if (!ids(groupId)) return { ok: false, error: "That group isn't valid." };
  try {
    await api(`/admin/groups/${groupId}`, { method: "DELETE" });
    revalidatePath("/admin/groups");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

const codeRe = /^[A-HJ-NP-Z]{6}$/;

/** Sets a group's join code (6 letters, no I or O) and/or whether it stays when empty. */
export async function updateGroup(
  groupId: string,
  change: { joinCode?: string; keepWhenEmpty?: boolean },
): Promise<ActionResult> {
  if (!ids(groupId)) return { ok: false, error: "That group isn't valid." };
  const body: { joinCode?: string; keepWhenEmpty?: boolean } = {};
  if (change.joinCode !== undefined) {
    const code = change.joinCode.trim().toUpperCase();
    if (!codeRe.test(code)) return { ok: false, error: "A join code is 6 letters, without I or O." };
    body.joinCode = code;
  }
  if (change.keepWhenEmpty !== undefined) body.keepWhenEmpty = change.keepWhenEmpty;
  try {
    await api(`/admin/groups/${groupId}`, { method: "PATCH", body });
    revalidatePath(`/admin/groups/${groupId}`);
    revalidatePath("/admin/groups");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

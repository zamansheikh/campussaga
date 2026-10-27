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

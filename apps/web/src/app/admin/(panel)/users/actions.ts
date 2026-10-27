"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import type { AdminUser, AdminUserDetail } from "@/lib/admin/types";

const id = z.uuid();

const patchSchema = z
  .object({
    role: z.enum(["student", "admin"]),
    universityId: z.uuid().nullable(),
    verified: z.boolean(),
    blocked: z.boolean(),
    displayName: z.string().trim().min(1).max(60),
  })
  .partial();

export type UserPatch = z.infer<typeof patchSchema>;

export async function updateUser(userId: string, patch: UserPatch): Promise<ActionResult<AdminUserDetail>> {
  const parsedId = id.safeParse(userId);
  const parsed = patchSchema.safeParse(patch);
  if (!parsedId.success || !parsed.success) return { ok: false, error: "That change isn't valid." };
  // The API clears the university with an empty string.
  const body = { ...parsed.data, ...(parsed.data.universityId === null ? { universityId: "" } : {}) };
  try {
    const user = await api<AdminUserDetail>(`/admin/users/${parsedId.data}`, { method: "PATCH", body });
    revalidatePath("/admin/users", "layout");
    return { ok: true, data: user };
  } catch (e) {
    return failure(e);
  }
}

export async function deleteUser(userId: string): Promise<ActionResult> {
  const parsedId = id.safeParse(userId);
  if (!parsedId.success) return { ok: false, error: "That user isn't valid." };
  try {
    await api(`/admin/users/${parsedId.data}`, { method: "DELETE" });
    revalidatePath("/admin/users", "layout");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** For pickers (push to one user): top matches by email or name. */
export async function searchUsers(q: string): Promise<ActionResult<Pick<AdminUser, "id" | "email" | "displayName">[]>> {
  const term = q.trim().slice(0, 100);
  if (term.length < 2) return { ok: true, data: [] };
  try {
    const res = await api<{ items: AdminUser[] }>(`/admin/users?q=${encodeURIComponent(term)}&pageSize=8`);
    return { ok: true, data: res.items.map((u) => ({ id: u.id, email: u.email, displayName: u.displayName })) };
  } catch (e) {
    return failure(e);
  }
}

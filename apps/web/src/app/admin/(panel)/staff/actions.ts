"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import type { StaffItem } from "@/lib/admin/types";

const addSchema = z
  .discriminatedUnion("kind", [
    z.object({
      kind: z.literal("authority"),
      userId: z.uuid("Choose a user."),
      universityId: z.uuid("An authority needs a university."),
      title: z.string().trim().min(2, "Add their public title, e.g. Proctor Office.").max(80),
    }),
    z.object({
      kind: z.literal("moderator"),
      userId: z.uuid("Choose a user."),
      universityId: z.uuid().nullable(),
      title: z.string().trim().max(80),
    }),
  ]);

export type StaffInput = z.input<typeof addSchema>;

/** Makes a user an authority (official) of a university, or a moderator. */
export async function addStaff(input: StaffInput): Promise<ActionResult<StaffItem>> {
  const parsed = addSchema.safeParse(input);
  if (!parsed.success) return { ok: false, error: parsed.error.issues[0]?.message ?? "That isn't valid." };
  const { userId, kind, universityId, title } = parsed.data;
  try {
    const item = await api<StaffItem>("/admin/staff", {
      method: "POST",
      body: { userId, kind, ...(universityId ? { universityId } : {}), ...(title ? { title } : {}) },
    });
    revalidatePath("/admin/staff");
    return { ok: true, data: item };
  } catch (e) {
    return failure(e);
  }
}

/** Removes a staff role (they become a student again). */
export async function removeStaff(userId: string): Promise<ActionResult> {
  const parsed = z.uuid().safeParse(userId);
  if (!parsed.success) return { ok: false, error: "That user isn't valid." };
  try {
    await api(`/admin/staff/${parsed.data}`, { method: "DELETE" });
    revalidatePath("/admin/staff");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

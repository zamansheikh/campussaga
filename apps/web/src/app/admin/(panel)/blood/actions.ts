"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";
import type { BloodRequest } from "@/lib/admin/types";

const id = z.uuid();
const reasonSchema = z.string().trim().max(300, "Keep the reason under 300 characters.");

/** Closes an open blood request (BLOOD_REQUEST_NOT_OPEN if someone else got there first). */
export async function closeBloodRequest(requestId: string, reason: string): Promise<ActionResult<BloodRequest>> {
  const rid = id.safeParse(requestId);
  if (!rid.success) return { ok: false, error: "That request isn't valid." };
  const why = reasonSchema.safeParse(reason);
  if (!why.success) return { ok: false, error: why.error.issues[0]?.message ?? "That reason isn't valid." };
  try {
    const item = await api<BloodRequest>(`/admin/blood/requests/${rid.data}/close`, {
      method: "POST",
      body: why.data ? { reason: why.data } : {},
    });
    revalidatePath("/admin/blood");
    return { ok: true, data: item };
  } catch (e) {
    revalidatePath("/admin/blood");
    return failure(e);
  }
}

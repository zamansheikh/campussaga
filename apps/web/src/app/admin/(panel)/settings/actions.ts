"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api } from "@/lib/admin/session";

const key = z.string().regex(/^[a-zA-Z][a-zA-Z0-9]{0,63}$/);

export async function updateConfig(k: string, value: unknown): Promise<ActionResult> {
  if (!key.safeParse(k).success) return { ok: false, error: "That setting name isn't valid." };
  if (k === "features" && !(value && typeof value === "object" && Object.values(value).every((v) => typeof v === "boolean"))) {
    return { ok: false, error: "Feature flags must be on/off values." };
  }
  if (k === "minSupportedBuild" && !(Number.isInteger(value) && (value as number) >= 1)) {
    return { ok: false, error: "The minimum build must be a whole number of at least 1." };
  }
  try {
    await api(`/admin/config/${k}`, { method: "PUT", body: { value } });
    revalidatePath("/admin/settings");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api, requireAdmin } from "@/lib/admin/session";
import { type AdminSponsor, limits } from "@/lib/admin/sponsors";

const uuid = z.uuid();

const optionalHttps = z
  .string()
  .trim()
  .max(limits.website, `The website can be at most ${limits.website} characters.`)
  .refine((v) => v === "" || /^https:\/\/[^\s/$.?#].[^\s]*$/i.test(v), "The website must start with https://");

const sponsor = z.object({
  name: z.string().trim().min(1, "Add the brand's name.").max(limits.name, `The name can be at most ${limits.name} characters.`),
  category: z.enum(["general", "health"]),
  website: optionalHttps,
  contactName: z.string().trim().max(limits.contactName, `The contact name can be at most ${limits.contactName} characters.`),
  contactPhone: z
    .string()
    .trim()
    .max(limits.contactPhone, `The phone can be at most ${limits.contactPhone} characters.`)
    .refine((v) => v === "" || /^\+?[0-9 ()-]{6,}$/.test(v), "The phone may only have digits, spaces, + - ( )."),
  contactEmail: z
    .string()
    .trim()
    .max(limits.contactEmail, `The email can be at most ${limits.contactEmail} characters.`)
    .refine((v) => v === "" || z.email().safeParse(v).success, "That email doesn't look right."),
  notes: z.string().trim().max(limits.notes, `Notes can be at most ${limits.notes} characters.`),
});

export type SponsorInput = z.input<typeof sponsor>;

function refresh(id?: string) {
  revalidatePath("/admin/sponsors");
  revalidatePath("/admin/ads");
  if (id) revalidatePath(`/admin/sponsors/${id}`);
}

/** Creates a sponsor, or saves one. */
export async function saveSponsor(id: string | null, input: SponsorInput): Promise<ActionResult<{ id: string }>> {
  await requireAdmin();
  if (id !== null && !uuid.safeParse(id).success) return { ok: false, error: "That sponsor isn't valid." };
  const parsed = sponsor.safeParse(input);
  if (!parsed.success) return { ok: false, error: parsed.error.issues[0]?.message ?? "Some fields are invalid." };
  try {
    if (id === null) {
      const created = await api<AdminSponsor>("/admin/sponsors", { method: "POST", body: parsed.data });
      refresh();
      return { ok: true, data: { id: created.id } };
    }
    await api(`/admin/sponsors/${id}`, { method: "PATCH", body: parsed.data });
    refresh(id);
    return { ok: true, data: { id } };
  } catch (e) {
    return failure(e);
  }
}

/** Archives a sponsor: their ads stop, the reports stay. */
export async function archiveSponsor(id: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That sponsor isn't valid." };
  try {
    await api(`/admin/sponsors/${id}`, { method: "DELETE" });
    refresh(id);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Brings an archived sponsor back; its ads stay paused until resumed one by one. */
export async function restoreSponsor(id: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That sponsor isn't valid." };
  try {
    await api(`/admin/sponsors/${id}`, { method: "PATCH", body: { archived: false } });
    refresh(id);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Removes a sponsor's logo (uploads go through /admin/sponsor-logo/{id}). */
export async function removeSponsorLogo(id: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That sponsor isn't valid." };
  try {
    await api(`/admin/sponsors/${id}/logo`, { method: "DELETE" });
    refresh(id);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

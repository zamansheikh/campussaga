"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api, requireAdmin } from "@/lib/admin/session";
import { type AdminPromo, appRoutes, CAMPAIGN_ROUTE, kindNeeds, limits, placementsFor, type PromoKind, type PromoStatus } from "@/lib/admin/sponsors";

const uuid = z.uuid();
const iso = z.string().refine((v) => !Number.isNaN(Date.parse(v)), "A date is missing or invalid.");
const fixedRoutes = new Set(appRoutes.map((r) => r.value).filter((v) => !v.includes("{")));

function text(label: string, max: number) {
  return z.string().trim().max(max, `${label} can be at most ${max} characters.`);
}

const promo = z
  .object({
    sponsorId: z.uuid("Choose a sponsor."),
    kind: z.enum(["deal", "card", "feed", "line", "campaign"]),
    placement: z.enum(["deals", "today", "campus", "line:bus", "line:groups", "line:cgpa", "line:blood", "campaign"]),
    campaignId: z.uuid().nullable(),
    titleEn: text("The English title", limits.title),
    titleBn: text("The Bangla title", limits.title),
    bodyEn: text("The English text", limits.body),
    bodyBn: text("The Bangla text", limits.body),
    ctaEn: text("The English button", limits.cta),
    ctaBn: text("The Bangla button", limits.cta),
    linkKind: z.enum(["none", "web", "app"]),
    link: text("The link", limits.link),
    code: text("The promo code", limits.code),
    expiresAt: z.string().nullable(),
    termsEn: text("The English terms", limits.terms),
    termsBn: text("The Bangla terms", limits.terms),
    universityIds: z.array(z.uuid()).nullable(),
    cities: z.array(z.string().trim().min(1).max(80)).nullable(),
    startsAt: iso,
    endsAt: iso,
    dailyCap: z.number({ error: "Times a day must be a whole number from 1 to 20." }).int("Times a day must be a whole number from 1 to 20.").min(1, "Times a day must be a whole number from 1 to 20.").max(20, "Times a day must be a whole number from 1 to 20."),
    totalViews: z
      .number({ error: "Total views must be a whole number of at least 1, or empty." })
      .int("Total views must be a whole number of at least 1, or empty.")
      .min(1, "Total views must be a whole number of at least 1, or empty.")
      .max(100_000_000, "Total views is too large.")
      .nullable(),
    priority: z.number({ error: "Priority must be 1 to 10." }).int("Priority must be 1 to 10.").min(1, "Priority must be 1 to 10.").max(10, "Priority must be 1 to 10."),
  })
  .refine((p) => placementsFor[p.kind as PromoKind].includes(p.placement), "That place doesn't fit this kind of ad.")
  .refine((p) => p.kind !== "campaign" || p.campaignId !== null, "Choose the campaign this sponsor powers.")
  .refine((p) => !kindNeeds[p.kind as PromoKind].texts || p.titleEn !== "", "Add an English title.")
  .refine((p) => !kindNeeds[p.kind as PromoKind].cta || p.linkKind === "none" || p.ctaEn !== "", "Add the button text (English), or choose no link.")
  .refine((p) => p.linkKind !== "web" || /^https:\/\/[^\s/$.?#].[^\s]*$/i.test(p.link), "The website link must start with https://")
  .refine((p) => p.linkKind !== "app" || fixedRoutes.has(p.link) || CAMPAIGN_ROUTE.test(p.link), "Choose an app screen to open.")
  .refine((p) => p.expiresAt === null || !Number.isNaN(Date.parse(p.expiresAt)), "The expiry date is invalid.")
  .refine((p) => Date.parse(p.endsAt) > Date.parse(p.startsAt), "The end must be after the start.")
  .refine((p) => p.universityIds === null || p.universityIds.length > 0, "Choose at least one university, or show it to everyone.")
  .refine((p) => p.cities === null || p.cities.length > 0, "Choose at least one city, or show it in every city.");

export type PromoInput = z.input<typeof promo>;

function refresh(id?: string, sponsorId?: string) {
  revalidatePath("/admin/ads");
  revalidatePath("/admin");
  if (id) revalidatePath(`/admin/ads/${id}`);
  if (sponsorId) revalidatePath(`/admin/sponsors/${sponsorId}`);
}

/** What the API stores for a promo: unused parts of other kinds are cleared. */
function body(p: z.output<typeof promo>) {
  const needs = kindNeeds[p.kind as PromoKind];
  const texts = needs.texts || p.kind === "line";
  return {
    sponsorId: p.sponsorId,
    kind: p.kind,
    placement: p.placement,
    campaignId: p.kind === "campaign" ? p.campaignId : null,
    titleEn: texts ? p.titleEn : "",
    titleBn: texts ? p.titleBn : "",
    bodyEn: needs.texts ? p.bodyEn : "",
    bodyBn: needs.texts ? p.bodyBn : "",
    ctaEn: needs.cta || needs.deal ? p.ctaEn : "",
    ctaBn: needs.cta || needs.deal ? p.ctaBn : "",
    linkKind: p.linkKind,
    link: p.linkKind === "none" ? "" : p.link,
    code: needs.deal && p.code !== "" ? p.code : null,
    expiresAt: needs.deal ? p.expiresAt : null,
    termsEn: needs.deal ? p.termsEn : "",
    termsBn: needs.deal ? p.termsBn : "",
    universityIds: p.universityIds,
    cities: p.cities,
    startsAt: p.startsAt,
    endsAt: p.endsAt,
    dailyCap: p.dailyCap,
    totalViews: p.totalViews,
    priority: p.priority,
  };
}

/**
 * Creates a draft, or saves one. A live ad only changes its end, total
 * views, times a day and priority, so only those are sent.
 */
export async function savePromo(id: string | null, input: PromoInput, live: boolean): Promise<ActionResult<{ id: string }>> {
  await requireAdmin();
  if (id !== null && !uuid.safeParse(id).success) return { ok: false, error: "That ad isn't valid." };
  const parsed = promo.safeParse(input);
  if (!parsed.success) return { ok: false, error: parsed.error.issues[0]?.message ?? "Some fields are invalid." };
  const p = parsed.data;
  try {
    if (id === null) {
      const created = await api<AdminPromo>("/admin/promos", { method: "POST", body: body(p) });
      refresh(undefined, p.sponsorId);
      return { ok: true, data: { id: created.id } };
    }
    const patch = live ? { endsAt: p.endsAt, totalViews: p.totalViews, dailyCap: p.dailyCap, priority: p.priority } : body(p);
    await api(`/admin/promos/${id}`, { method: "PATCH", body: patch });
    refresh(id, p.sponsorId);
    return { ok: true, data: { id } };
  } catch (e) {
    return failure(e);
  }
}

/** Publish, pause, resume or end. Going live checks the whole ad. */
export async function setPromoStatus(id: string, status: Exclude<PromoStatus, "draft">): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That ad isn't valid." };
  if (!["live", "paused", "ended"].includes(status)) return { ok: false, error: "That status isn't valid." };
  try {
    await api(`/admin/promos/${id}/status`, { method: "POST", body: { status } });
    refresh(id);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** A draft copy (with the image), to run the same ad again or try a variant. */
export async function duplicatePromo(id: string): Promise<ActionResult<{ id: string }>> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That ad isn't valid." };
  try {
    const copy = await api<AdminPromo>(`/admin/promos/${id}/duplicate`, { method: "POST" });
    refresh();
    return { ok: true, data: { id: copy.id } };
  } catch (e) {
    return failure(e);
  }
}

/** Deletes a draft (other statuses keep their reports). */
export async function deletePromo(id: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That ad isn't valid." };
  try {
    await api(`/admin/promos/${id}`, { method: "DELETE" });
    refresh();
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Removes an ad's image (uploads go through /admin/promo-image/{id}). */
export async function removePromoImage(id: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That ad isn't valid." };
  try {
    await api(`/admin/promos/${id}/image`, { method: "DELETE" });
    refresh(id);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { api, requireAdmin } from "@/lib/admin/session";

const uuid = z.uuid();
const iso = z.string().refine((v) => !Number.isNaN(Date.parse(v)), "A date is missing or invalid.");

const prize = z
  .object({
    rankFrom: z.number().int().min(1),
    rankTo: z.number().int().min(1),
    titleEn: z.string().trim().min(1, "Every prize needs an English title.").max(120),
    titleBn: z.string().trim().min(1, "Every prize needs a Bangla title.").max(120),
  })
  .refine((p) => p.rankTo >= p.rankFrom, "A prize's last rank can't be before its first rank.");

const campaign = z
  .object({
    titleEn: z.string().trim().min(1, "Add an English title.").max(120),
    titleBn: z.string().trim().min(1, "Add a Bangla title.").max(120),
    bodyEn: z.string().trim().max(2000),
    bodyBn: z.string().trim().max(2000),
    rulesEn: z.string().trim().min(1, "Add the English rules.").max(8000),
    rulesBn: z.string().trim().min(1, "Add the Bangla rules.").max(8000),
    startsAt: iso,
    endsAt: iso,
    settlesAt: iso,
    universityIds: z.array(z.uuid()).nullable(),
    prizes: z.array(prize).min(1, "Add at least one prize.").max(20),
  })
  .refine((c) => Date.parse(c.endsAt) > Date.parse(c.startsAt), "The end must be after the start.")
  .refine((c) => Date.parse(c.settlesAt) >= Date.parse(c.endsAt), "The settle date can't be before the end.")
  .refine((c) => c.universityIds === null || c.universityIds.length > 0, "Choose at least one university, or all of them.");

export type CampaignInput = z.input<typeof campaign>;

function refresh(id?: string) {
  revalidatePath("/admin/campaigns");
  if (id) revalidatePath(`/admin/campaigns/${id}`);
}

/**
 * Creates a draft, or saves one. [live] campaigns only change end, settle,
 * rules and prizes, so only those are sent.
 */
export async function saveCampaign(id: string | null, input: CampaignInput, live: boolean): Promise<ActionResult<{ id: string }>> {
  await requireAdmin();
  if (id !== null && !uuid.safeParse(id).success) return { ok: false, error: "That campaign isn't valid." };
  const parsed = campaign.safeParse(input);
  if (!parsed.success) return { ok: false, error: parsed.error.issues[0]?.message ?? "Some fields are invalid." };
  const c = parsed.data;
  try {
    if (id === null) {
      const created = await api<{ id: string }>("/admin/campaigns", { method: "POST", body: c });
      refresh();
      return { ok: true, data: { id: created.id } };
    }
    const body = live
      ? { endsAt: c.endsAt, settlesAt: c.settlesAt, rulesEn: c.rulesEn, rulesBn: c.rulesBn, prizes: c.prizes }
      : c;
    await api(`/admin/campaigns/${id}`, { method: "PATCH", body });
    refresh(id);
    return { ok: true, data: { id } };
  } catch (e) {
    return failure(e);
  }
}

export async function publishCampaign(id: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That campaign isn't valid." };
  try {
    await api(`/admin/campaigns/${id}`, { method: "PATCH", body: { status: "live" } });
    refresh(id);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Removes a campaign's banner photo (uploads go through /admin/campaign-banner/{id}). */
export async function removeCampaignBanner(id: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(id).success) return { ok: false, error: "That campaign isn't valid." };
  try {
    await api(`/admin/campaigns/${id}/banner`, { method: "DELETE" });
    refresh(id);
    revalidatePath(`/campaigns/${id}`);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

const reasonSchema =z.string().trim().min(3, "Say why, in a few words.").max(300, "Keep the reason under 300 characters.");

/** Disqualifies (or restores) one invite, found by the invited student. */
export async function setInviteDisqualified(referredId: string, disqualify: boolean, reason: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(referredId).success) return { ok: false, error: "That invite isn't valid." };
  try {
    if (disqualify) {
      const r = reasonSchema.safeParse(reason);
      if (!r.success) return { ok: false, error: r.error.issues[0]?.message ?? "Say why." };
      await api(`/admin/referrals/${referredId}/disqualify`, { method: "POST", body: { reason: r.data } });
    } else {
      await api(`/admin/referrals/${referredId}/restore`, { method: "POST" });
    }
    revalidatePath("/admin/campaigns", "layout");
    revalidatePath("/admin/referrals");
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

/** Removes a participant from one campaign (POST), or puts them back (DELETE). */
export async function setParticipantDisqualified(
  campaignId: string,
  userId: string,
  disqualify: boolean,
  reason: string,
): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(campaignId).success || !uuid.safeParse(userId).success) return { ok: false, error: "That change isn't valid." };
  try {
    if (disqualify) {
      const r = reasonSchema.safeParse(reason);
      if (!r.success) return { ok: false, error: r.error.issues[0]?.message ?? "Say why." };
      await api(`/admin/campaigns/${campaignId}/participants/${userId}/disqualify`, { method: "POST", body: { reason: r.data } });
    } else {
      await api(`/admin/campaigns/${campaignId}/participants/${userId}/disqualify`, { method: "DELETE" });
    }
    refresh(campaignId);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

export async function announceWinners(campaignId: string, winners: { userId: string; rank: number }[]): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(campaignId).success) return { ok: false, error: "That campaign isn't valid." };
  if (winners.length === 0) return { ok: false, error: "Add at least one winner." };
  if (!winners.every((w) => uuid.safeParse(w.userId).success && Number.isInteger(w.rank) && w.rank >= 1)) {
    return { ok: false, error: "Every winner needs a person and a rank." };
  }
  if (new Set(winners.map((w) => w.userId)).size !== winners.length) return { ok: false, error: "A person is listed twice." };
  if (new Set(winners.map((w) => w.rank)).size !== winners.length) return { ok: false, error: "Two winners have the same rank." };
  try {
    await api(`/admin/campaigns/${campaignId}/announce`, { method: "POST", body: { winners } });
    refresh(campaignId);
    return { ok: true, message: "Winners announced. They have been notified." };
  } catch (e) {
    return failure(e);
  }
}

export async function markDelivered(campaignId: string, userId: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(campaignId).success || !uuid.safeParse(userId).success) return { ok: false, error: "That change isn't valid." };
  try {
    await api(`/admin/campaigns/${campaignId}/winners/${userId}/delivered`, { method: "POST" });
    refresh(campaignId);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

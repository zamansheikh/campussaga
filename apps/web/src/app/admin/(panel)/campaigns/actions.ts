"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { type ActionResult, failure } from "@/lib/admin/errors";
import { type ScoringKey, scoringRange } from "@/lib/admin/growth";
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

const scoringNames: Record<ScoringKey, string> = {
  invite: "Points per friend",
  otherCampus: "Extra points for another university",
  pioneer: "Extra points for a pioneer friend",
  friendSection: "Extra points for a friend in a section",
  joinSection: "Points for joining a section",
  bloodDonor: "Points for a blood donor",
  busShare: "Points per live bus day",
  busShareDays: "Live bus days",
  sectionSetup: "Points per section set up",
  sectionSetupMax: "Sections that count",
  pioneerFirst: "Pioneer: first how many",
  minOwnCampus: "Minimum friends from their own university",
  minOtherCampus: "Minimum friends from other universities",
};

/** A whole number in the key's range, with a message that names the field. */
function scoringValue(key: ScoringKey) {
  const { min, max } = scoringRange[key];
  const msg = `${scoringNames[key]} must be a whole number from ${min} to ${max}.`;
  return z.number({ error: msg }).int(msg).min(min, msg).max(max, msg);
}

const scoring = z.object(
  Object.fromEntries((Object.keys(scoringRange) as ScoringKey[]).map((k) => [k, scoringValue(k)])) as Record<ScoringKey, ReturnType<typeof scoringValue>>,
);

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
    scoring: scoring.optional(),
    // Section challenge prize (§9.1): empty means badges only.
    sectionPrizeEn: z.string().trim().max(120, "The section prize (English) can be at most 120 characters."),
    sectionPrizeBn: z.string().trim().max(120, "The section prize (Bangla) can be at most 120 characters."),
    // Race finisher reward (§9.2): count 0 means none.
    finisherRewardEn: z.string().trim().max(120, "The finisher reward (English) can be at most 120 characters."),
    finisherRewardBn: z.string().trim().max(120, "The finisher reward (Bangla) can be at most 120 characters."),
    finisherRewardCount: z
      .number({ error: "How many finishers get the reward must be a whole number from 0 to 10000." })
      .int("How many finishers get the reward must be a whole number from 0 to 10000.")
      .min(0, "How many finishers get the reward must be a whole number from 0 to 10000.")
      .max(10000, "How many finishers get the reward must be a whole number from 0 to 10000."),
  })
  .refine((c) => Date.parse(c.endsAt) > Date.parse(c.startsAt), "The end must be after the start.")
  .refine((c) => Date.parse(c.settlesAt) >= Date.parse(c.endsAt), "The settle date can't be before the end.")
  .refine((c) => c.universityIds === null || c.universityIds.length > 0, "Choose at least one university, or all of them.")
  .refine((c) => (c.sectionPrizeEn === "") === (c.sectionPrizeBn === ""), "Give the section prize in both English and Bangla, or leave both empty.")
  .refine(
    (c) => c.finisherRewardCount === 0 || (c.finisherRewardEn !== "" && c.finisherRewardBn !== ""),
    "Say what the finishers get, in English and Bangla, or set how many to 0.",
  );

export type CampaignInput = z.input<typeof campaign>;

function refresh(id?: string) {
  revalidatePath("/admin/campaigns");
  if (id) revalidatePath(`/admin/campaigns/${id}`);
}

/**
 * Creates a draft, or saves a campaign. Everything can change at any time,
 * also while it is live (a spelling fix, new criteria).
 */
export async function saveCampaign(id: string | null, input: CampaignInput): Promise<ActionResult<{ id: string }>> {
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
    const body = c;
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

/** A finisher's reward was sent to their phone (§9.2). */
export async function markFinisherSent(campaignId: string, userId: string): Promise<ActionResult> {
  await requireAdmin();
  if (!uuid.safeParse(campaignId).success || !uuid.safeParse(userId).success) return { ok: false, error: "That change isn't valid." };
  try {
    await api(`/admin/campaigns/${campaignId}/finishers/${userId}/sent`, { method: "POST" });
    refresh(campaignId);
    return { ok: true };
  } catch (e) {
    return failure(e);
  }
}

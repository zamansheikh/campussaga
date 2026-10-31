// Shapes of the growth endpoints (docs/GROWTH.md §5). Shared by server pages and client components.

export type CampaignStatus = "draft" | "live" | "ended" | "announced";

export type CampaignPrize = { rankFrom: number; rankTo: number; titleEn: string; titleBn: string };

/**
 * A campaign's point values (docs/GROWTH.md §8.1, §8.5). `busShareDays`,
 * `sectionSetupMax`, `pioneerFirst`, `minOwnCampus` and `minOtherCampus`
 * are limits, the rest are points (0 turns that one off).
 */
export type CampaignScoring = {
  invite: number;
  otherCampus: number;
  pioneer: number;
  friendSection: number;
  joinSection: number;
  bloodDonor: number;
  busShare: number;
  busShareDays: number;
  sectionSetup: number;
  sectionSetupMax: number;
  pioneerFirst: number;
  /** Counted friends at the student's own university needed to be ranked for a prize (0: no minimum). */
  minOwnCampus: number;
  /** Counted friends at other universities needed to be ranked for a prize (0: no minimum). */
  minOtherCampus: number;
};

export type ScoringKey = keyof CampaignScoring;

export const defaultScoring: CampaignScoring = {
  invite: 10,
  otherCampus: 5,
  pioneer: 5,
  friendSection: 3,
  joinSection: 2,
  bloodDonor: 3,
  busShare: 2,
  busShareDays: 10,
  sectionSetup: 15,
  sectionSetupMax: 2,
  pioneerFirst: 20,
  minOwnCampus: 3,
  minOtherCampus: 2,
};

/** Allowed range of each value (the API refuses others with INVALID_SCORING). */
export const scoringRange: Record<ScoringKey, { min: number; max: number }> = {
  invite: { min: 0, max: 100 },
  otherCampus: { min: 0, max: 100 },
  pioneer: { min: 0, max: 100 },
  friendSection: { min: 0, max: 100 },
  joinSection: { min: 0, max: 100 },
  bloodDonor: { min: 0, max: 100 },
  busShare: { min: 0, max: 100 },
  busShareDays: { min: 0, max: 60 },
  sectionSetup: { min: 0, max: 100 },
  sectionSetupMax: { min: 0, max: 10 },
  pioneerFirst: { min: 1, max: 1000 },
  minOwnCampus: { min: 0, max: 20 },
  minOtherCampus: { min: 0, max: 20 },
};

/** The campaign's values over the defaults (an older API sends none). */
export function withDefaults(s?: Partial<CampaignScoring> | null): CampaignScoring {
  const out = { ...defaultScoring };
  for (const k of Object.keys(defaultScoring) as ScoringKey[]) {
    const v = s?.[k];
    if (typeof v === "number" && Number.isFinite(v)) out[k] = v;
  }
  return out;
}

/** The keys that earn points, in the rules' order (the others are limits). */
export const pointKeys = ["invite", "otherCampus", "pioneer", "friendSection", "joinSection", "bloodDonor", "busShare", "sectionSetup"] as const;
export type PointKey = (typeof pointKeys)[number];

/** Short names for a participant's points breakdown. */
export const pointLabel: Record<PointKey, string> = {
  invite: "Invites",
  otherCampus: "Other university",
  pioneer: "Pioneer",
  friendSection: "Friend in a section",
  joinSection: "Joined a section",
  bloodDonor: "Blood donor",
  busShare: "Live bus",
  sectionSetup: "Section setup",
};

/** `GET /admin/campaigns[/{id}]`. `universityIds` null means every university. */
export type AdminCampaign = {
  id: string;
  titleEn: string;
  titleBn: string;
  bodyEn: string;
  bodyBn: string;
  rulesEn: string;
  rulesBn: string;
  startsAt: string;
  endsAt: string;
  settlesAt: string;
  universityIds: string[] | null;
  prizes: CampaignPrize[];
  status: CampaignStatus;
  /** The banner photo, `/campaigns/{id}/banner?v=…` (the website serves that path too), or null. */
  bannerUrl?: string | null;
  /** Point values; missing on an older API (use `withDefaults`). */
  scoring?: Partial<CampaignScoring> | null;
  createdAt?: string;
  updatedAt?: string;
};

/** `GET /campaigns/{id}/public`: both languages, no sign-in. */
export type PublicCampaign = Pick<
  AdminCampaign,
  "id" | "titleEn" | "titleBn" | "bodyEn" | "bodyBn" | "rulesEn" | "rulesBn" | "startsAt" | "endsAt" | "settlesAt" | "prizes" | "bannerUrl" | "scoring"
> & { status?: CampaignStatus };

export type PersonRef = { id: string; name: string | null; email?: string | null; university?: string | { id?: string; name: string } | null };

export type StandingInvite = {
  referred: PersonRef;
  source: "link" | "join";
  createdAt: string;
  verifiedVia?: string | null;
  activeDays: number;
  qualifiedAt: string | null;
  sameDevice: boolean;
  disqualified: boolean;
  /** The friend is at a different university (earns `otherCampus`). */
  otherCampus?: boolean;
  /** The friend was among the first `pioneerFirst` verified students of their university. */
  pioneer?: boolean;
  /** The friend is in a class group now (earns `friendSection`). */
  inSection?: boolean;
};

export type InviteFlag = "same_device" | "burst" | "new_account" | "self_vouched";

export type Standing = {
  /** Null for a participant who isn't eligible (too few friends from other universities); they come after the ranked ones. */
  rank: number | null;
  user: PersonRef;
  /** Points. */
  score: number;
  /** Points per key; missing on an older API. */
  points?: Partial<Record<PointKey, number>> | null;
  hidden: boolean;
  /** In the prize race: has both minimums of counted friends (missing on an older API: treat as eligible). */
  eligible?: boolean;
  /** Counted friends at the student's own university. */
  ownCampus?: number;
  /** Counted friends at other universities. */
  otherCampus?: number;
  invites: StandingInvite[];
  flags: InviteFlag[];
  /** Set when the participant is removed from this campaign (if the API lists them). */
  disqualified?: boolean;
};

export type CampaignWinner = {
  user: PersonRef;
  rank: number;
  prizeEn: string;
  prizeBn?: string;
  announcedAt?: string;
  claimedAt?: string | null;
  deliveredAt?: string | null;
  claim?: { fullName: string; phone: string; address: string; note?: string | null } | null;
};

/** The API sends a winner's person fields flat ({userId, name, email, university}); the panel uses `user`. */
type ApiWinner = Omit<CampaignWinner, "user"> & { user?: PersonRef; userId?: string; name?: string | null; email?: string | null; university?: string | null };

export function normalizeWinner(w: ApiWinner): CampaignWinner {
  const user = w.user ?? { id: w.userId ?? "", name: w.name ?? null, email: w.email ?? null, university: w.university ?? null };
  return { ...w, user };
}

/** `GET /admin/referrals` rows. */
export type AdminReferral = {
  referrer: PersonRef;
  referred: PersonRef;
  source: "link" | "join";
  createdAt: string;
  verifiedVia?: string | null;
  activeDays: number;
  qualifiedAt: string | null;
  sameDevice: boolean;
  disqualified: boolean;
  disqualifiedAt?: string | null;
  reason?: string | null;
  flags: InviteFlag[];
};

export type GrowthStats = { invitesLast7Days?: number; qualifiedLast7Days?: number; liveCampaigns?: number };

/** `GET /users/{id}/profile` (the part the admin user page shows). */
export type UserProfileLite = {
  invitesJoined?: number;
  featuredBadge?: { key: string; tier: number } | null;
  badges?: { key: string; tier: number; earnedAt: string }[];
  roles?: string[];
};

export const statusLabel: Record<CampaignStatus, string> = { draft: "Draft", live: "Live", ended: "Ended", announced: "Winners announced" };
export const statusTone: Record<CampaignStatus, "secondary" | "success" | "warning" | "info"> = {
  draft: "secondary",
  live: "success",
  ended: "warning",
  announced: "info",
};

export const flagLabel: Record<string, string> = { same_device: "Same phone", burst: "Burst", new_account: "New account", self_vouched: "Self-vouched" };

/** What a flag means, for its tooltip. */
export const flagHelp: Record<string, string> = {
  same_device: "A friend's account was used on this student's phone.",
  burst: "10 or more invites within one hour.",
  new_account: "The inviter's account was under 7 days old when they invited.",
  self_vouched: "A friend was verified through this student's own vouch, or by them as CR. Check that the friend is a real classmate.",
};

export const badgeLabel: Record<string, string> = {
  verified: "Verified",
  founding: "Founding student",
  cr: "CR",
  campus_admin: "Campus admin",
  bus_rep: "Bus rep",
  official: "Official",
  blood_donor: "Blood donor",
  life_saver: "Life saver",
  bus_buddy: "Bus buddy",
  section_builder: "Section builder",
  connector: "Connector",
  bug_hunter: "Bug hunter",
  helper: "Helper",
  campus_voice: "Campus voice",
};

export const tierLabel = ["", "Bronze", "Silver", "Gold"];

/** The `university` of a person ref as text. */
export function uniName(u: PersonRef["university"]): string {
  return !u ? "" : typeof u === "string" ? u : u.name;
}

/** The prize title (English) for a rank, or "". */
export function prizeForRank(prizes: CampaignPrize[], rank: number): string {
  return prizes.find((p) => rank >= p.rankFrom && rank <= p.rankTo)?.titleEn ?? "";
}

// Dates are typed and shown in Bangladesh time (UTC+6, no daylight saving).
const DHAKA_MS = 6 * 3600_000;

/** ISO instant -> value for `<input type="datetime-local">` in Bangladesh time. */
export function toDhakaInput(iso: string): string {
  const t = new Date(iso).getTime();
  return Number.isNaN(t) ? "" : new Date(t + DHAKA_MS).toISOString().slice(0, 16);
}

/** `<input type="datetime-local">` value in Bangladesh time -> ISO instant ("" when invalid). */
export function fromDhakaInput(v: string): string {
  const t = Date.parse(`${v}:00Z`);
  return Number.isNaN(t) ? "" : new Date(t - DHAKA_MS).toISOString();
}

/** "own 1/3 · other 0/2": a participant's progress to the prize race, leaving out a part without a minimum. */
export function raceProgress(r: { ownCampus?: number; otherCampus?: number }, minOwn: number, minOther: number): string {
  const parts = [minOwn > 0 ? `own ${r.ownCampus ?? 0}/${minOwn}` : "", minOther > 0 ? `other ${r.otherCampus ?? 0}/${minOther}` : ""];
  return parts.filter(Boolean).join(" · ");
}

/** "3 from their own university and 2 from other universities" (admin wording), or "" with no minimum. */
export function raceRule(minOwn: number, minOther: number): string {
  const parts = [
    minOwn > 0 ? `${minOwn} from their own university` : "",
    minOther > 0 ? `${minOther} from ${minOther === 1 ? "another university" : "other universities"}` : "",
  ];
  return parts.filter(Boolean).join(" and ");
}

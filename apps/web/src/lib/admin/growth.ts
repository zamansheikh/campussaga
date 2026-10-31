// Shapes of the growth endpoints (docs/GROWTH.md §5). Shared by server pages and client components.

export type CampaignStatus = "draft" | "live" | "ended" | "announced";

export type CampaignPrize = { rankFrom: number; rankTo: number; titleEn: string; titleBn: string };

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
  createdAt?: string;
  updatedAt?: string;
};

/** `GET /campaigns/{id}/public`: both languages, no sign-in. */
export type PublicCampaign = Pick<
  AdminCampaign,
  "id" | "titleEn" | "titleBn" | "bodyEn" | "bodyBn" | "rulesEn" | "rulesBn" | "startsAt" | "endsAt" | "settlesAt" | "prizes"
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
};

export type InviteFlag = "same_device" | "burst" | "new_account";

export type Standing = {
  rank: number;
  user: PersonRef;
  score: number;
  hidden: boolean;
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

export const flagLabel: Record<string, string> = { same_device: "Same phone", burst: "Burst", new_account: "New account" };

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

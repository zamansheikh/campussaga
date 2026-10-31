// Sponsors and ads (docs/SPONSORS.md): types, labels, limits and the small
// helpers the admin pages share. The Go API is the source of truth; these
// helpers also read a few alternative shapes so an older or newer server
// doesn't break a page.

export type SponsorCategory = "general" | "health";

export type AdminSponsor = {
  id: string;
  name: string;
  category: SponsorCategory;
  /** Path under the API base ("/sponsors/{id}/logo?v=…"); the website serves it too. */
  logoUrl?: string | null;
  website?: string;
  contactName?: string;
  contactPhone?: string;
  contactEmail?: string;
  notes?: string;
  archivedAt?: string | null;
  createdAt?: string;
  updatedAt?: string;
  /** Its ads: how many are live, and in all. */
  promos?: { live?: number; total?: number };
};

export type PromoKind = "deal" | "card" | "feed" | "line" | "campaign";
export type PromoPlacement = "deals" | "today" | "campus" | "line:bus" | "line:groups" | "line:cgpa" | "line:blood" | "campaign";
export type PromoStatus = "draft" | "live" | "paused" | "ended";
export type LinkKind = "none" | "web" | "app";

export type AdminPromo = {
  id: string;
  /** Filled from `sponsor.id` by {@link promoFrom}. */
  sponsorId: string;
  sponsor?: { id: string; name: string; category?: SponsorCategory; logoUrl?: string | null; archived?: boolean } | null;
  kind: PromoKind;
  placement: PromoPlacement;
  campaignId?: string | null;
  /** Looked up by the page for a campaign sponsor. */
  campaign?: { id: string; titleEn?: string } | null;
  titleEn?: string;
  titleBn?: string;
  bodyEn?: string;
  bodyBn?: string;
  ctaEn?: string;
  ctaBn?: string;
  imageUrl?: string | null;
  linkKind?: LinkKind;
  link?: string | null;
  code?: string | null;
  expiresAt?: string | null;
  termsEn?: string;
  termsBn?: string;
  universityIds?: string[] | null;
  cities?: string[] | null;
  /** A draft may have no dates yet; going live needs both. */
  startsAt: string | null;
  endsAt: string | null;
  status: PromoStatus;
  dailyCap?: number;
  totalViews?: number | null;
  priority?: number;
  /** Reached `totalViews`: still live, but no longer served. */
  delivered?: boolean;
  /** Filled from `stats` by {@link promoFrom}. */
  viewsToday?: number;
  tapsToday?: number;
  views?: number;
  taps?: number;
  stats?: { viewsToday?: number; tapsToday?: number; views?: number; taps?: number };
  createdAt?: string;
  updatedAt?: string;
};

/** An admin ad as the API sends it, with `sponsorId` and the counts lifted up. */
export function promoFrom(raw: AdminPromo): AdminPromo {
  const s = raw.stats ?? {};
  return {
    ...raw,
    sponsorId: raw.sponsorId ?? raw.sponsor?.id ?? "",
    startsAt: raw.startsAt ?? null,
    endsAt: raw.endsAt ?? null,
    viewsToday: raw.viewsToday ?? s.viewsToday ?? 0,
    tapsToday: raw.tapsToday ?? s.tapsToday ?? 0,
    views: raw.views ?? s.views ?? 0,
    taps: raw.taps ?? s.taps ?? 0,
  };
}

export type StatsTotals = { views: number; viewers: number; taps: number; copies: number; hides: number; ctr: number };
export type StatsDay = { day: string; views: number; viewers: number; taps: number; copies: number; hides: number };
export type PromoStats = { days: StatsDay[]; totals: StatsTotals };

/** One ad's totals in a sponsor report. */
export type SponsorStatsRow = StatsTotals & {
  promoId: string;
  titleEn: string;
  kind: PromoKind | string;
  placement: PromoPlacement | string;
  status: PromoStatus | string;
  startsAt?: string | null;
  endsAt?: string | null;
};
export type SponsorStats = { promos: SponsorStatsRow[]; totals: StatsTotals };

// ---- labels ------------------------------------------------------------------

export const categoryLabel: Record<SponsorCategory, string> = { general: "General", health: "Health" };

export const kindInfo: Record<PromoKind, { label: string; hint: string }> = {
  deal: { label: "Student deal", hint: "A discount with a promo code on the Student deals page. Students come looking for these." },
  card: { label: "Today card", hint: "One card a day on Today, after the class routine. Image, a short line and one button." },
  feed: { label: "Campus feed post", hint: "Looks like a post in the main Campus feed, after every 12th post. No comments or likes." },
  line: { label: "Sponsor line", hint: "One quiet line, “Supported by [logo] Brand”, at the bottom of a page." },
  campaign: { label: "Campaign sponsor", hint: "“Powered by [logo] Brand” on a prize campaign’s poster, rules page and share card." },
};

export const kindOrder: PromoKind[] = ["deal", "card", "feed", "line", "campaign"];

export const placementLabel: Record<PromoPlacement, string> = {
  deals: "Student deals",
  today: "Today",
  campus: "Campus feed",
  "line:bus": "Bus routes page",
  "line:groups": "Class groups page",
  "line:cgpa": "CGPA page",
  "line:blood": "Blood page",
  campaign: "Prize campaign",
};

/** Where each kind can go; the first is the default. */
export const placementsFor: Record<PromoKind, PromoPlacement[]> = {
  deal: ["deals"],
  card: ["today"],
  feed: ["campus"],
  line: ["line:bus", "line:groups", "line:cgpa", "line:blood"],
  campaign: ["campaign"],
};

export const statusLabel: Record<PromoStatus, string> = { draft: "Draft", live: "Live", paused: "Paused", ended: "Ended" };
export const statusTone: Record<PromoStatus, "secondary" | "success" | "warning" | "outline"> = {
  draft: "secondary",
  live: "success",
  paused: "warning",
  ended: "outline",
};

/** Field limits from the API (characters). */
export const limits = {
  name: 80,
  website: 300,
  contactName: 80,
  contactPhone: 20,
  contactEmail: 120,
  notes: 1000,
  title: 60,
  body: 140,
  cta: 20,
  link: 500,
  code: 30,
  terms: 500,
} as const;

/** Screens a promo can open in the app (link kind "app"). `/campaigns/{id}` takes a campaign. */
export const appRoutes: { value: string; label: string }[] = [
  { value: "/deals", label: "Student deals" },
  { value: "/explore", label: "Explore" },
  { value: "/bus", label: "Bus routes" },
  { value: "/blood", label: "Blood donation" },
  { value: "/groups", label: "Class groups" },
  { value: "/find-class", label: "Find your class" },
  { value: "/cgpa", label: "CGPA" },
  { value: "/campus", label: "Campus feed" },
  { value: "/campaigns/{id}", label: "A prize campaign…" },
];

export const CAMPAIGN_ROUTE = /^\/campaigns\/([0-9a-f-]{36})$/i;

/** Whether a kind needs texts, an image, a deal block. */
export const kindNeeds: Record<PromoKind, { texts: boolean; image: "required" | "optional" | "none"; deal: boolean; cta: boolean; dailyCap: boolean }> = {
  deal: { texts: true, image: "optional", deal: true, cta: false, dailyCap: false },
  card: { texts: true, image: "required", deal: false, cta: true, dailyCap: true },
  feed: { texts: true, image: "required", deal: false, cta: true, dailyCap: true },
  line: { texts: false, image: "none", deal: false, cta: false, dailyCap: false },
  campaign: { texts: false, image: "none", deal: false, cta: false, dailyCap: false },
};

/** While live only these change (SPONSORS.md §4). */
export const liveEditable = ["endsAt", "totalViews", "dailyCap", "priority"] as const;

/** The status the list shows: "Delivered" when a live ad reached its views. */
export function statusText(p: Pick<AdminPromo, "status" | "delivered">): string {
  return p.status === "live" && p.delivered ? "Delivered" : statusLabel[p.status] ?? p.status;
}

// ---- reading the API ---------------------------------------------------------

/** A list the API may send as an array, `{items}` or `{rows}`. */
export function listOf<T>(r: T[] | { items?: T[]; rows?: T[]; promos?: T[] } | null | undefined): T[] {
  if (!r) return [];
  if (Array.isArray(r)) return r;
  return r.items ?? r.rows ?? r.promos ?? [];
}

const zeroTotals: StatsTotals = { views: 0, viewers: 0, taps: 0, copies: 0, hides: 0, ctr: 0 };

function num(v: unknown): number {
  return typeof v === "number" && Number.isFinite(v) ? v : 0;
}

/** Tap rate, as a share (0–1). */
export function ctrOf(views: number, taps: number): number {
  return views > 0 ? taps / views : 0;
}

export function totalsFrom(t: Partial<StatsTotals> | null | undefined): StatsTotals {
  if (!t) return zeroTotals;
  const views = num(t.views);
  const taps = num(t.taps);
  return {
    views,
    viewers: num(t.viewers),
    taps,
    copies: num(t.copies),
    hides: num(t.hides),
    // The API may send a share or a percentage; recompute to be sure.
    ctr: ctrOf(views, taps),
  };
}

export function promoStatsFrom(r: Partial<PromoStats> | null | undefined): PromoStats {
  const days = (r?.days ?? []).map((d) => ({
    day: String(d.day).slice(0, 10),
    views: num(d.views),
    viewers: num(d.viewers),
    taps: num(d.taps),
    copies: num(d.copies),
    hides: num(d.hides),
  }));
  const totals = r?.totals
    ? totalsFrom(r.totals)
    : totalsFrom(days.reduce<Partial<StatsTotals>>((a, d) => ({
        views: num(a.views) + d.views,
        viewers: num(a.viewers) + d.viewers,
        taps: num(a.taps) + d.taps,
        copies: num(a.copies) + d.copies,
        hides: num(a.hides) + d.hides,
      }), {}));
  return { days, totals };
}

type RawSponsorRow = Partial<SponsorStatsRow> & { id?: string; title?: string; promo?: Partial<AdminPromo> };

export function sponsorStatsFrom(r: unknown): SponsorStats {
  const raw = r as { promos?: RawSponsorRow[]; items?: RawSponsorRow[]; rows?: RawSponsorRow[]; totals?: Partial<StatsTotals> } | RawSponsorRow[] | null;
  const rows: RawSponsorRow[] = Array.isArray(raw) ? raw : (raw?.promos ?? raw?.items ?? raw?.rows ?? []);
  const promos = rows.map((p) => {
    const t = totalsFrom(p);
    return {
      ...t,
      promoId: String(p.promoId ?? p.id ?? p.promo?.id ?? ""),
      titleEn: String(p.titleEn ?? p.title ?? p.promo?.titleEn ?? ""),
      kind: String(p.kind ?? p.promo?.kind ?? ""),
      placement: String(p.placement ?? p.promo?.placement ?? ""),
      status: String(p.status ?? p.promo?.status ?? ""),
      startsAt: p.startsAt ?? p.promo?.startsAt,
      endsAt: p.endsAt ?? p.promo?.endsAt,
    };
  });
  const totals =
    !Array.isArray(raw) && raw?.totals
      ? totalsFrom(raw.totals)
      : totalsFrom(
          promos.reduce<Partial<StatsTotals>>(
            (a, p) => ({
              views: num(a.views) + p.views,
              viewers: num(a.viewers) + p.viewers,
              taps: num(a.taps) + p.taps,
              copies: num(a.copies) + p.copies,
              hides: num(a.hides) + p.hides,
            }),
            {},
          ),
        );
  return { promos, totals };
}

// ---- dates (Bangladesh) --------------------------------------------------------

const DHAKA_MS = 6 * 3600_000;

/** Today's date in Bangladesh, YYYY-MM-DD. */
export function dhakaToday(now = Date.now()): string {
  return new Date(now + DHAKA_MS).toISOString().slice(0, 10);
}

/** YYYY-MM-DD `days` before [date] (a YYYY-MM-DD). */
export function daysBefore(date: string, days: number): string {
  const t = Date.parse(`${date}T00:00:00Z`);
  return new Date(t - days * 24 * 3600_000).toISOString().slice(0, 10);
}

/** A YYYY-MM-DD from a query value, or the fallback. */
export function dateParam(v: string | undefined, fallback: string): string {
  return v && /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(v)) ? v : fallback;
}

/** "1 Nov" for a YYYY-MM-DD. */
export function shortDay(day: string): string {
  return new Date(`${day}T00:00:00Z`).toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: "UTC" });
}

/** "12.4%" for a share. */
export function percentText(share: number): string {
  if (!Number.isFinite(share) || share <= 0) return "0%";
  const p = share * 100;
  return `${p < 10 ? p.toFixed(1) : Math.round(p)}%`;
}

/** Every day from `from` to `to` (YYYY-MM-DD), with zeros where the API sent nothing. */
export function fillDays(days: StatsDay[], from: string, to: string): StatsDay[] {
  const byDay = new Map(days.map((d) => [d.day, d]));
  const out: StatsDay[] = [];
  let t = Date.parse(`${from}T00:00:00Z`);
  const end = Date.parse(`${to}T00:00:00Z`);
  let guard = 0;
  while (t <= end && guard++ < 1000) {
    const day = new Date(t).toISOString().slice(0, 10);
    out.push(byDay.get(day) ?? { day, views: 0, viewers: 0, taps: 0, copies: 0, hides: 0 });
    t += 24 * 3600_000;
  }
  return out;
}

// ---- CSV ---------------------------------------------------------------------

function cell(v: string | number): string {
  const s = String(v);
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

/** CSV text with a BOM, so Excel reads Bangla correctly. */
export function toCsv(head: string[], rows: (string | number)[][]): string {
  return "﻿" + [head, ...rows].map((r) => r.map(cell).join(",")).join("\r\n") + "\r\n";
}

/** A file-name-safe slug. */
export function fileSlug(s: string): string {
  return (
    s
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      .slice(0, 40) || "report"
  );
}

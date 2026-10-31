import { ArrowLeft, CalendarClock, ExternalLink, ImagePlus, Pencil } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";

import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ApiError } from "@/lib/admin/errors";
import {
  type AdminCampaign,
  type CampaignFinisher,
  type CampaignScoring,
  type CampaignWinner,
  defaultSectionChallenge,
  normalizeWinner,
  prizeForRank,
  raceRule,
  type SectionBoardRow,
  type Standing,
  statusLabel,
  statusTone,
  uniName,
  withDefaults,
} from "@/lib/admin/growth";
import { load } from "@/lib/admin/load";
import { api, requestNow, requireAdmin } from "@/lib/admin/session";
import { allUniversities } from "@/lib/admin/universities";
import { formatDateTime, formatNumber } from "@/lib/format";

import { AnnounceWinners, DeliveredButton, FinisherSentButton, PublishButton } from "./campaign-controls";
import { StandingsTable } from "./standings";

export const metadata: Metadata = { title: "Campaign" };

function list<T>(r: T[] | { items?: T[] } | null | undefined): T[] {
  return Array.isArray(r) ? r : (r?.items ?? []);
}

/** For an endpoint an older server doesn't have: null when it answers 404 or 405. */
async function maybe<T>(fn: () => Promise<T>): Promise<T | null> {
  try {
    return await fn();
  } catch (e) {
    if (e instanceof ApiError && (e.status === 404 || e.status === 405)) return null;
    throw e;
  }
}

type Board = SectionBoardRow[] | { rows?: SectionBoardRow[]; items?: SectionBoardRow[] };

export default async function CampaignPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  const eid = encodeURIComponent(id);
  const res = await load(() => api<AdminCampaign>(`/admin/campaigns/${eid}`));
  const c = res.data;
  const [standings, winners, unis, finishers, sections] = c
    ? await Promise.all([
        c.status === "draft" ? undefined : load(async () => list(await api<Standing[] | { items: Standing[] }>(`/admin/campaigns/${eid}/standings`))),
        c.status === "announced" ? load(async () => list(await api<CampaignWinner[] | { items: CampaignWinner[] }>(`/admin/campaigns/${eid}/winners`)).map(normalizeWinner)) : undefined,
        c.universityIds ? load(() => allUniversities()) : undefined,
        c.status === "draft"
          ? undefined
          : load(() => maybe(async () => list(await api<CampaignFinisher[] | { items: CampaignFinisher[] }>(`/admin/campaigns/${eid}/finishers`)))),
        c.status === "draft"
          ? undefined
          : load(() =>
              maybe(async () => {
                const b = await api<Board>(`/admin/campaigns/${eid}/sections`);
                return Array.isArray(b) ? b : (b?.rows ?? b?.items ?? []);
              }),
            ),
      ])
    : [undefined, undefined, undefined, undefined, undefined];
  const now = requestNow();
  const uniNames = new Map((unis?.data ?? []).map((u) => [u.id, u.name]));

  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/campaigns">
          <ArrowLeft /> Campaigns
        </Link>
      </Button>
      {res.error || !c ? (
        <ErrorPanel message={res.error ?? "Not found."} />
      ) : (
        <div className="space-y-6">
          {/* The poster on the left, everything at a glance on the right. */}
          <div className="grid gap-6 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,1fr)] lg:items-stretch">
            {c.bannerUrl ? (
              // The website serves the API's banner path too (src/app/(site)/campaigns/[id]/banner).
              // eslint-disable-next-line @next/next/no-img-element
              <img src={c.bannerUrl} alt="Campaign banner" className="aspect-[2/1] w-full rounded-xl border bg-muted object-cover" />
            ) : (
              <Link
                href={`/admin/campaigns/${c.id}/edit`}
                className="flex aspect-[2/1] w-full flex-col items-center justify-center gap-2 rounded-xl border border-dashed bg-muted/40 text-sm text-muted-foreground hover:bg-muted"
              >
                <ImagePlus className="size-6" aria-hidden />
                No banner yet: add one (2:1, e.g. 1600×800)
              </Link>
            )}
            <div className="flex min-w-0 flex-col gap-4">
              <div className="min-w-0">
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant={statusTone[c.status] ?? "outline"}>{statusLabel[c.status] ?? c.status}</Badge>
                  <span className="inline-flex items-center gap-1.5 text-sm text-muted-foreground">
                    <CalendarClock className="size-4" aria-hidden />
                    {whenText(c, now)}
                  </span>
                </div>
                <h1 className="mt-2 text-2xl font-semibold tracking-tight text-balance">{c.titleEn}</h1>
                <p lang="bn" className="mt-1 text-muted-foreground">
                  {c.titleBn}
                </p>
              </div>
              <dl className="grid grid-cols-2 gap-3">
                <Stat label="Students with points" value={standings?.data ? formatNumber(standings.data.length) : "–"} />
                <Stat
                  label="In the prize race"
                  value={standings?.data ? formatNumber(standings.data.filter((r) => r.rank !== null && r.eligible !== false).length) : "–"}
                />
                <Stat label="Finishers" value={finishers?.data ? formatNumber(finishers.data.length) : "–"} />
                <Stat label="Top prize" value={topPrize(c) ?? "–"} small />
              </dl>
              <div className="mt-auto flex flex-wrap items-center gap-2">
                <Button variant="outline" asChild>
                  <Link href={`/admin/campaigns/${c.id}/edit`}>
                    <Pencil /> Edit
                  </Link>
                </Button>
                {c.status === "draft" ? <PublishButton id={c.id} title={c.titleEn} /> : null}
                {c.status !== "draft" ? (
                  <Button variant="ghost" asChild>
                    <Link href={`/campaigns/${c.id}`} target="_blank">
                      Public rules page <ExternalLink aria-hidden />
                    </Link>
                  </Button>
                ) : null}
              </div>
            </div>
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Dates and reach</CardTitle>
                <CardDescription>Bangladesh time</CardDescription>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-3 text-sm sm:grid-cols-2">
                  <Field label="Starts">{formatDateTime(c.startsAt)}</Field>
                  <Field label="Ends">{formatDateTime(c.endsAt)}</Field>
                  <Field label="Settles">{formatDateTime(c.settlesAt)}</Field>
                  <Field label="Universities">
                    {c.universityIds === null ? "All universities" : c.universityIds.map((u) => uniNames.get(u) ?? u).join(", ") || "None"}
                  </Field>
                  <div className="sm:col-span-2">
                    <Field label="Points">{pointsSummary(withDefaults(c.scoring))}</Field>
                  </div>
                </dl>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Prizes</CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="space-y-1.5 text-sm">
                  {(c.prizes ?? []).map((p, i) => (
                    <li key={i}>
                      <span className="font-medium">{p.rankFrom === p.rankTo ? `Rank ${p.rankFrom}` : `Ranks ${p.rankFrom}–${p.rankTo}`}:</span> {p.titleEn}{" "}
                      <span lang="bn" className="text-muted-foreground">
                        / {p.titleBn}
                      </span>
                    </li>
                  ))}
                  {c.sectionPrizeEn ? (
                    <li>
                      <span className="font-medium">Champion section (picked by you):</span> {c.sectionPrizeEn}{" "}
                      <span lang="bn" className="text-muted-foreground">
                        / {c.sectionPrizeBn}
                      </span>
                    </li>
                  ) : null}
                  {(c.finisherRewardCount ?? 0) > 0 ? (
                    <li>
                      <span className="font-medium">First {c.finisherRewardCount} in the race:</span> {c.finisherRewardEn}{" "}
                      <span lang="bn" className="text-muted-foreground">
                        / {c.finisherRewardBn}
                      </span>
                    </li>
                  ) : null}
                </ul>
              </CardContent>
            </Card>
          </div>

          {c.status !== "draft" ? (
            <section className="space-y-3">
              <div>
                <h2 className="text-lg font-semibold">Standings</h2>
                <p className="text-sm text-muted-foreground">
                  The top 100 by points, then those not eligible yet. Open a row to see the invites; disqualify one that looks like cheating.
                </p>
              </div>
              {standings?.error ? (
                <ErrorPanel message={standings.error} />
              ) : standings?.data && standings.data.length === 0 ? (
                <EmptyState title="No participants yet" />
              ) : standings?.data ? (
                <StandingsTable
                  campaignId={c.id}
                  rows={standings.data}
                  minOwnCampus={withDefaults(c.scoring).minOwnCampus}
                  minOtherCampus={withDefaults(c.scoring).minOtherCampus}
                />
              ) : null}
            </section>
          ) : null}

          {finishers?.error ? (
            <ErrorPanel message={finishers.error} />
          ) : finishers?.data ? (
            <FinishersSection campaign={c} rows={finishers.data} />
          ) : null}

          {sections?.error ? <ErrorPanel message={sections.error} /> : sections?.data ? <TopSections campaign={c} rows={sections.data} /> : null}

          {c.status === "live" || c.status === "ended" ? (
            <section className="space-y-3">
              <div>
                <h2 className="text-lg font-semibold">Announce winners</h2>
                <p className="text-sm text-muted-foreground">
                  Winners are the people in the ranks that have a prize, checked against the standings above. Prizes go by rank only.
                </p>
              </div>
              {now < new Date(c.settlesAt).getTime() ? (
                <p className="rounded-lg border bg-muted/40 px-3 py-2 text-sm text-muted-foreground">
                  Winners can be announced after the settle date, {formatDateTime(c.settlesAt)}.
                </p>
              ) : standings?.data ? (
                <AnnounceWinners
                  campaignId={c.id}
                  prizes={c.prizes ?? []}
                  candidates={standings.data.map((s) => ({
                    id: s.user.id,
                    name: s.user.name || s.user.email || "No name",
                    rank: s.rank,
                    disqualified: s.disqualified,
                    eligible: s.eligible,
                  }))}
                />
              ) : null}
            </section>
          ) : null}

          {c.status === "announced" ? (
            <section className="space-y-3">
              <div>
                <h2 className="text-lg font-semibold">Winners</h2>
                <p className="text-sm text-muted-foreground">Delivery details are sent by the winners and deleted 90 days after delivery.</p>
              </div>
              {winners?.error ? (
                <ErrorPanel message={winners.error} />
              ) : winners?.data && winners.data.length === 0 ? (
                <EmptyState title="No winners recorded" />
              ) : winners?.data ? (
                <ul className="divide-y rounded-xl border bg-card">
                  {winners.data.map((w) => (
                    <li key={w.user.id} className="flex flex-wrap items-start justify-between gap-3 p-4 text-sm">
                      <div className="min-w-0 space-y-1">
                        <p className="font-medium">
                          #{w.rank}{" "}
                          <Link href={`/admin/users/${w.user.id}`} className="hover:underline">
                            {w.user.name || w.user.email || "No name"}
                          </Link>
                          <span className="ms-2 font-normal text-muted-foreground">{uniName(w.user.university)}</span>
                        </p>
                        <p className="text-muted-foreground">Prize: {w.prizeEn || prizeForRank(c.prizes ?? [], w.rank) || "—"}</p>
                        {w.claim ? (
                          <dl className="mt-2 grid gap-x-6 gap-y-1 rounded-lg bg-muted/40 p-3 sm:grid-cols-2">
                            <Field label="Full name">{w.claim.fullName}</Field>
                            <Field label="Phone">{w.claim.phone}</Field>
                            <Field label="Address">{w.claim.address}</Field>
                            {w.claim.note ? <Field label="Note">{w.claim.note}</Field> : null}
                          </dl>
                        ) : (
                          <p className="text-muted-foreground">Hasn&apos;t sent delivery details yet.</p>
                        )}
                      </div>
                      <div className="flex flex-col items-end gap-2">
                        {w.deliveredAt ? (
                          <Badge variant="success">Delivered {formatDateTime(w.deliveredAt)}</Badge>
                        ) : (
                          <>
                            <Badge variant={w.claim || w.claimedAt ? "info" : "secondary"}>{w.claim || w.claimedAt ? "Details received" : "Waiting for details"}</Badge>
                            <DeliveredButton campaignId={c.id} userId={w.user.id} name={w.user.name || "The winner"} />
                          </>
                        )}
                      </div>
                    </li>
                  ))}
                </ul>
              ) : null}
            </section>
          ) : null}
        </div>
      )}
    </>
  );
}

/** Students who entered the prize race, in order, with the first N's reward (§9.2). */
function FinishersSection({ campaign: c, rows }: { campaign: AdminCampaign; rows: CampaignFinisher[] }) {
  const count = c.finisherRewardCount ?? 0;
  const claimed = rows.filter((f) => f.claimedAt).length;
  const sent = rows.filter((f) => f.sentAt).length;
  return (
    <section className="space-y-3">
      <div className="flex flex-wrap items-end justify-between gap-2">
        <div>
          <h2 className="text-lg font-semibold">Race finishers</h2>
          <p className="text-sm text-muted-foreground">
            Students who entered the prize race while it was live, in order. Each gets the Race finisher badge
            {count > 0 ? `; the first ${count} get ${c.finisherRewardEn || "the reward"} and add their mobile number in the app.` : "."}
          </p>
        </div>
        {count > 0 ? (
          <p className="text-sm font-medium tabular-nums">
            Sent {sent} / claimed {claimed} / reward for first {count}
          </p>
        ) : null}
      </div>
      {rows.length === 0 ? (
        <EmptyState title="No finishers yet" />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-12">#</TableHead>
                <TableHead>Student</TableHead>
                <TableHead>Finished</TableHead>
                <TableHead>Reward</TableHead>
                <TableHead>Phone</TableHead>
                <TableHead>Claimed</TableHead>
                <TableHead>Sent</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((f) => (
                <TableRow key={f.user.id}>
                  <TableCell className="font-semibold tabular-nums">{f.position}</TableCell>
                  <TableCell className="max-w-64 whitespace-normal">
                    <Link href={`/admin/users/${f.user.id}`} className="font-medium hover:underline">
                      {f.user.name || f.user.email || "No name"}
                    </Link>
                    <p className="text-xs break-all text-muted-foreground">{[f.user.email, uniName(f.user.university)].filter(Boolean).join(" · ")}</p>
                  </TableCell>
                  <TableCell className="text-sm">{formatDateTime(f.finishedAt)}</TableCell>
                  <TableCell>{f.inReward ? <Badge variant="success">In reward</Badge> : <span className="text-muted-foreground">—</span>}</TableCell>
                  <TableCell className="font-mono text-sm">{f.phone || <span className="font-sans text-muted-foreground">—</span>}</TableCell>
                  <TableCell className="text-sm">{f.claimedAt ? formatDateTime(f.claimedAt) : <span className="text-muted-foreground">—</span>}</TableCell>
                  <TableCell>
                    {f.sentAt ? (
                      <Badge variant="info">Sent {formatDateTime(f.sentAt)}</Badge>
                    ) : f.inReward && f.claimedAt && f.phone ? (
                      <FinisherSentButton campaignId={c.id} userId={f.user.id} name={f.user.name || "the student"} phone={f.phone} />
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </section>
  );
}

/** The top sections board of the section challenge (§9.1). */
function TopSections({ campaign: c, rows }: { campaign: AdminCampaign; rows: SectionBoardRow[] }) {
  const goal = defaultSectionChallenge;
  return (
    <section className="space-y-3">
      <div>
        <h2 className="text-lg font-semibold">Top sections</h2>
        <p className="text-sm text-muted-foreground">
          By verified members. A Champion section has {goal.members}+ verified members and {goal.slots}+ classes; all its members get the badge.
          {c.sectionPrizeEn ? ` Pick the section that wins "${c.sectionPrizeEn}" from here.` : ""}
        </p>
      </div>
      {rows.length === 0 ? (
        <EmptyState title="No sections yet" />
      ) : (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-12">#</TableHead>
                <TableHead>Section</TableHead>
                <TableHead className="text-end">Verified members</TableHead>
                <TableHead className="text-end">Classes</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.groupId}>
                  <TableCell className="font-semibold tabular-nums">{r.rank}</TableCell>
                  <TableCell className="max-w-80 whitespace-normal">
                    <p className="font-medium">{r.name}</p>
                    <p className="text-xs text-muted-foreground">{uniName(r.university)}</p>
                  </TableCell>
                  <TableCell className="text-end tabular-nums">{r.members}</TableCell>
                  <TableCell className="text-end tabular-nums">{r.slots}</TableCell>
                  <TableCell>{r.champion ? <Badge variant="success">Champion</Badge> : null}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </section>
  );
}

/** One line of the campaign's point values, leaving out the ones turned off. */
function pointsSummary(s: CampaignScoring): string {
  const parts: [number, string][] = [
    [s.invite, `${s.invite} per friend`],
    [s.otherCampus, `+${s.otherCampus} other university`],
    [s.pioneer, `+${s.pioneer} pioneer (first ${s.pioneerFirst})`],
    [s.friendSection, `+${s.friendSection} friend in a section`],
    [s.joinSection, `${s.joinSection} joined a section`],
    [s.bloodDonor, `${s.bloodDonor} blood donor`],
    [s.busShareDays > 0 ? s.busShare : 0, `${s.busShare} a live bus day (up to ${s.busShareDays})`],
    [s.sectionSetupMax > 0 ? s.sectionSetup : 0, `${s.sectionSetup} a section set up (up to ${s.sectionSetupMax})`],
  ];
  const earn =
    parts
      .filter(([v]) => v > 0)
      .map(([, t]) => t)
      .join(" · ") || "Nothing earns points";
  const race = raceRule(s.minOwnCampus, s.minOtherCampus);
  return race ? `${earn}. To win, counted friends: ${race}.` : earn;
}

/** One number at a glance. [small] for a short text value (the top prize). */
function Stat({ label, value, small = false }: { label: string; value: string; small?: boolean }) {
  return (
    <div className="rounded-xl border bg-card px-4 py-3">
      <dt className="truncate text-xs text-muted-foreground">{label}</dt>
      <dd className={small ? "mt-1 truncate text-sm font-semibold" : "mt-1 text-xl font-semibold tabular-nums"} title={value}>
        {value}
      </dd>
    </div>
  );
}

/** The prize for rank 1 (or the lowest rank). */
function topPrize(c: AdminCampaign): string | null {
  const first = [...(c.prizes ?? [])].sort((a, b) => a.rankFrom - b.rankFrom)[0];
  return first?.titleEn ?? null;
}

/** "Starts in 3 days", "Ends in 5 h", "Ended 2 days ago" or "Winners announced". */
function whenText(c: AdminCampaign, now: number): string {
  if (c.status === "announced") return "Winners announced";
  const starts = Date.parse(c.startsAt);
  const ends = Date.parse(c.endsAt);
  const span = (ms: number) => {
    const h = Math.round(Math.abs(ms) / 3_600_000);
    if (h < 1) return "less than an hour";
    if (h < 48) return `${h} h`;
    return `${Math.round(h / 24)} days`;
  };
  if (c.status === "draft") return now < starts ? `Draft · would start in ${span(starts - now)}` : "Draft";
  if (now < starts) return `Starts in ${span(starts - now)}`;
  if (now < ends) return `Ends in ${span(ends - now)}`;
  return `Ended ${span(now - ends)} ago`;
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="mt-0.5 font-medium break-words whitespace-pre-line">{children}</dd>
    </div>
  );
}

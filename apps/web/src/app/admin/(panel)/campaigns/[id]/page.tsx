import { ArrowLeft, ExternalLink, Pencil } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";

import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  type AdminCampaign,
  type CampaignScoring,
  type CampaignWinner,
  normalizeWinner,
  prizeForRank,
  type Standing,
  statusLabel,
  statusTone,
  uniName,
  withDefaults,
} from "@/lib/admin/growth";
import { load } from "@/lib/admin/load";
import { api, requestNow, requireAdmin } from "@/lib/admin/session";
import { allUniversities } from "@/lib/admin/universities";
import { formatDateTime } from "@/lib/format";

import { AnnounceWinners, DeliveredButton, PublishButton } from "./campaign-controls";
import { StandingsTable } from "./standings";

export const metadata: Metadata = { title: "Campaign" };

function list<T>(r: T[] | { items?: T[] } | null | undefined): T[] {
  return Array.isArray(r) ? r : (r?.items ?? []);
}

export default async function CampaignPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  const eid = encodeURIComponent(id);
  const res = await load(() => api<AdminCampaign>(`/admin/campaigns/${eid}`));
  const c = res.data;
  const [standings, winners, unis] = c
    ? await Promise.all([
        c.status === "draft" ? undefined : load(async () => list(await api<Standing[] | { items: Standing[] }>(`/admin/campaigns/${eid}/standings`))),
        c.status === "announced" ? load(async () => list(await api<CampaignWinner[] | { items: CampaignWinner[] }>(`/admin/campaigns/${eid}/winners`)).map(normalizeWinner)) : undefined,
        c.universityIds ? load(() => allUniversities()) : undefined,
      ])
    : [undefined, undefined, undefined];
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
          {c.bannerUrl ? (
            // The website serves the API's banner path too (src/app/(site)/campaigns/[id]/banner).
            // eslint-disable-next-line @next/next/no-img-element
            <img src={c.bannerUrl} alt="Campaign banner" className="aspect-[2/1] w-full max-w-xl rounded-xl border bg-muted object-cover" />
          ) : null}
          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div className="min-w-0">
              <h1 className="text-2xl font-semibold tracking-tight">{c.titleEn}</h1>
              <p lang="bn" className="text-muted-foreground">
                {c.titleBn}
              </p>
              <div className="mt-2 flex flex-wrap items-center gap-2">
                <Badge variant={statusTone[c.status] ?? "outline"}>{statusLabel[c.status] ?? c.status}</Badge>
                {!c.bannerUrl && c.status !== "announced" ? (
                  <Link href={`/admin/campaigns/${c.id}/edit`} className="text-sm text-muted-foreground hover:text-foreground hover:underline">
                    No banner yet: add one
                  </Link>
                ) : null}
                {c.status !== "draft" ? (
                  <Link href={`/campaigns/${c.id}`} target="_blank" className="inline-flex items-center gap-1 text-sm text-primary hover:underline">
                    Public rules page <ExternalLink className="size-3.5" aria-hidden />
                  </Link>
                ) : null}
              </div>
            </div>
            <div className="flex flex-wrap gap-2">
              {c.status !== "announced" ? (
                <Button variant="outline" asChild>
                  <Link href={`/admin/campaigns/${c.id}/edit`}>
                    <Pencil /> Edit
                  </Link>
                </Button>
              ) : null}
              {c.status === "draft" ? <PublishButton id={c.id} title={c.titleEn} /> : null}
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
                </ul>
              </CardContent>
            </Card>
          </div>

          {c.status !== "draft" ? (
            <section className="space-y-3">
              <div>
                <h2 className="text-lg font-semibold">Standings</h2>
                <p className="text-sm text-muted-foreground">
                  The top 100 by points. Open a row to see the invites; disqualify one that looks like cheating.
                </p>
              </div>
              {standings?.error ? (
                <ErrorPanel message={standings.error} />
              ) : standings?.data && standings.data.length === 0 ? (
                <EmptyState title="No participants yet" />
              ) : standings?.data ? (
                <StandingsTable campaignId={c.id} rows={standings.data} />
              ) : null}
            </section>
          ) : null}

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
                  candidates={standings.data.map((s) => ({ id: s.user.id, name: s.user.name || s.user.email || "No name", rank: s.rank, disqualified: s.disqualified }))}
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
  return (
    parts
      .filter(([v]) => v > 0)
      .map(([, t]) => t)
      .join(" · ") || "Nothing earns points"
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="mt-0.5 font-medium break-words whitespace-pre-line">{children}</dd>
    </div>
  );
}

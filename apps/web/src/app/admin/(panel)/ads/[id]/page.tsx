import { AlertTriangle, ArrowLeft, Download } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

import { DateRange } from "@/components/admin/date-range";
import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { PromoPreview } from "@/components/admin/promo-preview";
import { StatTiles } from "@/components/admin/stat-tiles";
import { StatsChart } from "@/components/admin/stats-chart";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ApiError } from "@/lib/admin/errors";
import type { AdminCampaign } from "@/lib/admin/growth";
import { load } from "@/lib/admin/load";
import { api, query, requestNow, requireAdmin } from "@/lib/admin/session";
import {
  type AdminPromo,
  appRoutes,
  CAMPAIGN_ROUTE,
  categoryLabel,
  ctrOf,
  dateParam,
  daysBefore,
  dhakaToday,
  fillDays,
  kindInfo,
  kindNeeds,
  percentText,
  placementLabel,
  promoFrom,
  promoStatsFrom,
  shortDay,
  statusText,
  statusTone,
} from "@/lib/admin/sponsors";
import { allUniversities } from "@/lib/admin/universities";
import { formatDateTime, formatNumber } from "@/lib/format";

import { AdControls } from "../ad-controls";

export const metadata = { title: "Ad" };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** What an ad still needs before it can go live. */
function missingFor(p: AdminPromo, now: number): string[] {
  const needs = kindNeeds[p.kind];
  const out: string[] = [];
  if (needs.texts && !p.titleEn?.trim()) out.push("an English title");
  if (needs.image === "required" && !p.imageUrl) out.push("an image");
  if (p.kind === "campaign" && !p.campaignId) out.push("a campaign");
  if (!p.startsAt) out.push("a start date");
  if (!p.endsAt) out.push("an end date");
  else if (Date.parse(p.endsAt) <= now) out.push("an end date in the future");
  if (p.sponsor?.archived) out.push("a sponsor that isn't archived");
  return out;
}

function linkText(p: AdminPromo): string {
  if (!p.link || p.linkKind === "none" || !p.linkKind) return "None";
  if (p.linkKind === "web") return p.link;
  const m = CAMPAIGN_ROUTE.exec(p.link);
  if (m) return `App: a prize campaign`;
  return `App: ${appRoutes.find((r) => r.value === p.link)?.label ?? p.link}`;
}

export default async function AdPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ from?: string; to?: string }> }) {
  await requireAdmin();
  const { id } = await params;
  if (!UUID.test(id)) notFound();
  const sp = await searchParams;

  const res = await load(async () => {
    try {
      const promo = promoFrom(await api<AdminPromo>(`/admin/promos/${id}`));
      // A campaign sponsor shows its campaign's title.
      if (promo.campaignId) {
        const c = await api<AdminCampaign>(`/admin/campaigns/${promo.campaignId}`).catch(() => null);
        if (c) promo.campaign = { id: c.id, titleEn: c.titleEn };
      }
      return promo;
    } catch (e) {
      if (e instanceof ApiError && e.status === 404) notFound();
      throw e;
    }
  });
  if (res.error || !res.data) return <ErrorPanel message={res.error ?? "No data."} />;
  const p = res.data;

  const now = requestNow();
  const today = dhakaToday(now);
  const start = p.startsAt ? dhakaToday(Date.parse(p.startsAt)) : daysBefore(today, 29);
  const end = p.endsAt && dhakaToday(Date.parse(p.endsAt)) < today ? dhakaToday(Date.parse(p.endsAt)) : today;
  const defaultFrom = start > daysBefore(end, 29) ? start : daysBefore(end, 29);
  const from = dateParam(sp.from, defaultFrom <= end ? defaultFrom : end);
  const to = dateParam(sp.to, end);

  const [stats, unis] = await Promise.all([
    load(async () => promoStatsFrom(await api(`/admin/promos/${id}/stats${query({ from, to })}`))),
    p.universityIds?.length ? load(() => allUniversities()) : Promise.resolve({ data: [] as { id: string; name: string }[] }),
  ]);
  const uniNames = new Map((unis.data ?? []).map((u) => [u.id, u.name]));
  const days = stats.data ? fillDays(stats.data.days, from, to) : [];
  const missing = p.status === "draft" || p.status === "paused" ? missingFor(p, now) : [];
  const title = p.titleEn || (p.kind === "line" ? "Sponsor line" : p.kind === "campaign" ? "Campaign sponsor" : "Untitled ad");

  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/ads">
          <ArrowLeft /> Ads
        </Link>
      </Button>
      <PageHeader
        title={title}
        description={
          <span className="flex flex-wrap items-center gap-2">
            <Badge variant={p.status === "live" && p.delivered ? "info" : (statusTone[p.status] ?? "outline")}>{statusText(p)}</Badge>
            <span>
              {kindInfo[p.kind]?.label ?? p.kind} · {placementLabel[p.placement] ?? p.placement}
              {p.sponsor ? (
                <>
                  {" · "}
                  <Link href={`/admin/sponsors/${p.sponsor.id}`} className="text-primary hover:underline">
                    {p.sponsor.name}
                  </Link>
                </>
              ) : null}
            </span>
          </span>
        }
        actions={<AdControls promo={p} missing={missing} startsLater={p.startsAt ? Date.parse(p.startsAt) > now : false} />}
      />

      {missing.length ? (
        <p className="mb-6 flex items-start gap-2 rounded-lg bg-warning-soft px-3 py-2 text-sm text-warning">
          <AlertTriangle className="mt-0.5 size-4 shrink-0" aria-hidden />
          <span>
            Before it can go live, add {missing.join(", ")}.{" "}
            <Link href={`/admin/ads/${p.id}/edit`} className="font-medium underline">
              Edit the ad
            </Link>
          </span>
        </p>
      ) : null}
      {p.status === "live" && p.delivered ? (
        <p className="mb-6 rounded-lg bg-info-soft px-3 py-2 text-sm text-info">
          This ad reached its {formatNumber(p.totalViews ?? 0)} views and is no longer shown. Raise the total views to show it again.
        </p>
      ) : null}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_380px] lg:items-start">
        <div className="min-w-0 space-y-6">
          <Card>
            <CardHeader className="gap-3">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <CardTitle className="text-base">Report</CardTitle>
                  <CardDescription>Bangladesh days. Only students count; the team&apos;s own views don&apos;t.</CardDescription>
                </div>
                <Button variant="outline" size="sm" asChild>
                  <a href={`/admin/ads/${p.id}/report.csv${query({ from, to })}`} download>
                    <Download /> CSV
                  </a>
                </Button>
              </div>
              <DateRange
                from={from}
                to={to}
                presets={[
                  { label: "7 days", from: daysBefore(end, 6), to: end },
                  { label: "30 days", from: daysBefore(end, 29), to: end },
                  { label: "Whole run", from: start <= end ? start : end, to: end },
                ]}
              />
            </CardHeader>
            <CardContent className="space-y-5">
              {stats.error ? (
                <p className="text-sm text-muted-foreground">The numbers can&apos;t be loaded right now. {stats.error}</p>
              ) : stats.data ? (
                <>
                  <StatTiles totals={stats.data.totals} copies={p.kind === "deal"} />
                  {stats.data.totals.views === 0 && stats.data.totals.taps === 0 ? (
                    <p className="rounded-lg border border-dashed px-3 py-6 text-center text-sm text-muted-foreground">
                      No views in these days{p.status === "draft" ? ": the ad isn't published yet." : "."}
                    </p>
                  ) : (
                    <StatsChart days={days} />
                  )}
                  <details className="group rounded-lg border">
                    <summary className="cursor-pointer px-3 py-2 text-sm font-medium select-none">Daily numbers</summary>
                    <div className="max-h-80 overflow-auto border-t">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Day</TableHead>
                            <TableHead className="text-right">Views</TableHead>
                            <TableHead className="text-right">Students</TableHead>
                            <TableHead className="text-right">Taps</TableHead>
                            <TableHead className="text-right">Tap rate</TableHead>
                            {p.kind === "deal" ? <TableHead className="text-right">Copies</TableHead> : null}
                            <TableHead className="text-right">Hidden</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {[...days].reverse().map((d) => (
                            <TableRow key={d.day}>
                              <TableCell>{shortDay(d.day)}</TableCell>
                              <TableCell className="text-right tabular-nums">{formatNumber(d.views)}</TableCell>
                              <TableCell className="text-right tabular-nums">{formatNumber(d.viewers)}</TableCell>
                              <TableCell className="text-right tabular-nums">{formatNumber(d.taps)}</TableCell>
                              <TableCell className="text-right tabular-nums">{percentText(ctrOf(d.views, d.taps))}</TableCell>
                              {p.kind === "deal" ? <TableCell className="text-right tabular-nums">{formatNumber(d.copies)}</TableCell> : null}
                              <TableCell className="text-right tabular-nums">{formatNumber(d.hides)}</TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  </details>
                </>
              ) : null}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Details</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="grid gap-x-6 gap-y-4 text-sm sm:grid-cols-2">
                <Item label="Sponsor">
                  {p.sponsor ? (
                    <>
                      <Link href={`/admin/sponsors/${p.sponsor.id}`} className="text-primary hover:underline">
                        {p.sponsor.name}
                      </Link>
                      {p.sponsor.category ? <span className="text-muted-foreground"> · {categoryLabel[p.sponsor.category]}</span> : null}
                    </>
                  ) : (
                    "—"
                  )}
                </Item>
                <Item label="Where">
                  {kindInfo[p.kind]?.label ?? p.kind} · {placementLabel[p.placement] ?? p.placement}
                  {p.kind === "campaign" && p.campaignId ? (
                    <>
                      {" · "}
                      <Link href={`/admin/campaigns/${p.campaignId}`} className="text-primary hover:underline">
                        {p.campaign?.titleEn ?? "the campaign"}
                      </Link>
                    </>
                  ) : null}
                </Item>
                <Item label="Runs">
                  {formatDateTime(p.startsAt)} – {formatDateTime(p.endsAt)}
                </Item>
                <Item label="Link">
                  {p.linkKind === "web" && p.link ? (
                    <a href={p.link} target="_blank" rel="noopener noreferrer" className="break-all text-primary hover:underline">
                      {p.link}
                    </a>
                  ) : (
                    linkText(p)
                  )}
                </Item>
                <Item label="Who sees it">
                  {p.universityIds?.length || p.cities?.length ? (
                    <>
                      {p.universityIds?.length ? <span className="block">{p.universityIds.map((u) => uniNames.get(u) ?? u).join(", ")}</span> : null}
                      {p.cities?.length ? <span className="block text-muted-foreground">In {p.cities.join(", ")}</span> : null}
                    </>
                  ) : (
                    "All students"
                  )}
                </Item>
                <Item label="Delivery">
                  {kindNeeds[p.kind].dailyCap ? `${p.dailyCap ?? 2} a day per student · ` : ""}
                  {p.totalViews ? `${formatNumber(p.totalViews)} views in total` : "no total limit"} · priority {p.priority ?? 5}/10
                </Item>
                {p.kind === "deal" ? (
                  <Item label="Deal">
                    {p.code ? <span className="font-mono font-semibold tracking-wider">{p.code}</span> : "No code"}
                    {p.expiresAt ? <span className="text-muted-foreground"> · valid till {formatDateTime(p.expiresAt)}</span> : null}
                  </Item>
                ) : null}
                <Item label="Changed">{formatDateTime(p.updatedAt ?? p.createdAt)}</Item>
              </dl>
            </CardContent>
          </Card>
        </div>

        <aside className="lg:sticky lg:top-20">
          <Card>
            <CardContent>
              <PromoPreview
                data={{
                  kind: p.kind,
                  placement: p.placement,
                  sponsorName: p.sponsor?.name ?? "",
                  sponsorLogoUrl: p.sponsor?.logoUrl,
                  titleEn: p.titleEn ?? "",
                  titleBn: p.titleBn ?? "",
                  bodyEn: p.bodyEn ?? "",
                  bodyBn: p.bodyBn ?? "",
                  ctaEn: p.ctaEn ?? "",
                  ctaBn: p.ctaBn ?? "",
                  imageUrl: p.imageUrl,
                  code: p.code ?? "",
                  expiresAt: p.expiresAt ?? null,
                  termsEn: p.termsEn ?? "",
                  termsBn: p.termsBn ?? "",
                  hasLink: Boolean(p.link) && p.linkKind !== "none",
                  campaignTitle: p.campaign?.titleEn,
                }}
              />
            </CardContent>
          </Card>
        </aside>
      </div>
    </>
  );
}

function Item({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="min-w-0">
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd className="mt-0.5">{children}</dd>
    </div>
  );
}

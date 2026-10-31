import { ArrowLeft, Download, Plus, Printer } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

import { DateRange } from "@/components/admin/date-range";
import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { StatTiles } from "@/components/admin/stat-tiles";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ApiError } from "@/lib/admin/errors";
import { load } from "@/lib/admin/load";
import { api, query, requestNow, requireAdmin } from "@/lib/admin/session";
import {
  type AdminPromo,
  type AdminSponsor,
  categoryLabel,
  dateParam,
  daysBefore,
  dhakaToday,
  kindInfo,
  listOf,
  percentText,
  placementLabel,
  promoFrom,
  sponsorStatsFrom,
  statusText,
  statusTone,
  type PromoKind,
  type PromoPlacement,
  type PromoStatus,
} from "@/lib/admin/sponsors";
import type { Paged } from "@/lib/admin/types";
import { formatDate, formatNumber } from "@/lib/format";

import { SponsorForm } from "../sponsor-form";
import { SponsorLogo } from "../sponsor-logo";
import { ArchiveSponsorButton, RestoreSponsorButton, SponsorLogoField } from "./sponsor-controls";

export const metadata = { title: "Sponsor" };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function SponsorPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ from?: string; to?: string }> }) {
  await requireAdmin();
  const { id } = await params;
  if (!UUID.test(id)) notFound();
  const sp = await searchParams;
  const today = dhakaToday(requestNow());
  const to = dateParam(sp.to, today);
  const from = dateParam(sp.from, daysBefore(to, 29));

  const res = await load(async () => {
    try {
      return await api<AdminSponsor>(`/admin/sponsors/${id}`);
    } catch (e) {
      if (e instanceof ApiError && e.status === 404) notFound();
      throw e;
    }
  });
  if (res.error || !res.data) return <ErrorPanel message={res.error ?? "No data."} />;
  const s = res.data;
  const [ads, stats] = await Promise.all([
    load(async () => listOf(await api<Paged<AdminPromo> | AdminPromo[]>(`/admin/promos${query({ sponsorId: id, pageSize: 100 })}`)).map(promoFrom)),
    load(async () => sponsorStatsFrom(await api(`/admin/sponsors/${id}/stats${query({ from, to })}`))),
  ]);
  const liveAds = (ads.data ?? []).filter((a) => a.status === "live").length;
  const archived = Boolean(s.archivedAt);

  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/sponsors">
          <ArrowLeft /> Sponsors
        </Link>
      </Button>
      <PageHeader
        title={s.name}
        description={
          <span className="flex flex-wrap items-center gap-2">
            <SponsorLogo url={s.logoUrl} name={s.name} className="size-6" />
            <Badge variant={s.category === "health" ? "info" : "secondary"}>{categoryLabel[s.category] ?? s.category}</Badge>
            {archived ? <Badge variant="outline">Archived {formatDate(s.archivedAt)}</Badge> : null}
            <span>
              {formatNumber(liveAds)} live {liveAds === 1 ? "ad" : "ads"}
            </span>
          </span>
        }
        actions={
          <>
            {!archived ? (
              <Button asChild>
                <Link href={`/admin/ads/new?sponsorId=${s.id}`}>
                  <Plus /> New ad
                </Link>
              </Button>
            ) : null}
            {!archived ? <ArchiveSponsorButton id={s.id} name={s.name} liveAds={liveAds} /> : <RestoreSponsorButton id={s.id} name={s.name} />}
          </>
        }
      />

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-[minmax(0,1fr)_400px] xl:items-start">
        <div className="min-w-0 space-y-6">
          <Card>
            <CardHeader className="gap-3">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <CardTitle className="text-base">Report for the sponsor</CardTitle>
                  <CardDescription>Totals per ad, Bangladesh days. No student is ever named.</CardDescription>
                </div>
                <div className="flex flex-wrap gap-2">
                  <Button variant="outline" size="sm" asChild>
                    <a href={`/admin/sponsors/${s.id}/report.csv${query({ from, to })}`} download>
                      <Download /> CSV
                    </a>
                  </Button>
                  <Button variant="outline" size="sm" asChild>
                    <Link href={`/admin/sponsor-report/${s.id}${query({ from, to })}`} target="_blank">
                      <Printer /> Printable report
                    </Link>
                  </Button>
                </div>
              </div>
              <DateRange
                from={from}
                to={to}
                presets={[
                  { label: "7 days", from: daysBefore(today, 6), to: today },
                  { label: "30 days", from: daysBefore(today, 29), to: today },
                  { label: "90 days", from: daysBefore(today, 89), to: today },
                ]}
              />
            </CardHeader>
            <CardContent className="space-y-5">
              {stats.error ? (
                <p className="text-sm text-muted-foreground">The numbers can&apos;t be loaded right now. {stats.error}</p>
              ) : stats.data ? (
                <>
                  <StatTiles totals={stats.data.totals} copies={stats.data.promos.some((p) => p.kind === "deal")} />
                  {stats.data.promos.length === 0 ? (
                    <p className="rounded-lg border border-dashed px-3 py-6 text-center text-sm text-muted-foreground">No ads ran in these days.</p>
                  ) : (
                    <div className="overflow-x-auto rounded-lg border">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Ad</TableHead>
                            <TableHead className="text-right">Views</TableHead>
                            <TableHead className="hidden text-right sm:table-cell">Students</TableHead>
                            <TableHead className="text-right">Taps</TableHead>
                            <TableHead className="text-right">Tap rate</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {stats.data.promos.map((p) => (
                            <TableRow key={p.promoId || p.titleEn}>
                              <TableCell className="max-w-64">
                                {p.promoId ? (
                                  <Link href={`/admin/ads/${p.promoId}`} className="block truncate font-medium hover:underline">
                                    {p.titleEn || kindInfo[p.kind as PromoKind]?.label || "Ad"}
                                  </Link>
                                ) : (
                                  <span className="block truncate font-medium">{p.titleEn || "Ad"}</span>
                                )}
                                <span className="block truncate text-xs text-muted-foreground">
                                  {kindInfo[p.kind as PromoKind]?.label ?? p.kind} · {placementLabel[p.placement as PromoPlacement] ?? p.placement}
                                </span>
                              </TableCell>
                              <TableCell className="text-right tabular-nums">{formatNumber(p.views)}</TableCell>
                              <TableCell className="hidden text-right tabular-nums sm:table-cell">{formatNumber(p.viewers)}</TableCell>
                              <TableCell className="text-right tabular-nums">{formatNumber(p.taps)}</TableCell>
                              <TableCell className="text-right tabular-nums">{percentText(p.ctr)}</TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  )}
                </>
              ) : null}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Ads</CardTitle>
              <CardDescription>Every ad of this sponsor, newest first.</CardDescription>
            </CardHeader>
            <CardContent>
              {ads.error ? (
                <p className="text-sm text-muted-foreground">{ads.error}</p>
              ) : (ads.data ?? []).length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  No ads yet.{" "}
                  {!archived ? (
                    <Link href={`/admin/ads/new?sponsorId=${s.id}`} className="text-primary hover:underline">
                      Create the first one
                    </Link>
                  ) : null}
                </p>
              ) : (
                <ul className="divide-y">
                  {(ads.data ?? []).map((a) => (
                    <li key={a.id} className="relative flex items-center gap-3 py-2.5">
                      <div className="min-w-0 flex-1">
                        <Link href={`/admin/ads/${a.id}`} className="block truncate text-sm font-medium after:absolute after:inset-0 hover:underline">
                          {a.titleEn || kindInfo[a.kind]?.label || "Ad"}
                        </Link>
                        <p className="truncate text-xs text-muted-foreground">
                          {kindInfo[a.kind]?.label ?? a.kind} · {placementLabel[a.placement] ?? a.placement} · {formatDate(a.startsAt)} – {formatDate(a.endsAt)}
                        </p>
                      </div>
                      <Badge variant={a.status === "live" && a.delivered ? "info" : (statusTone[a.status as PromoStatus] ?? "outline")}>{statusText(a)}</Badge>
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <SponsorLogoField id={s.id} logoUrl={s.logoUrl} disabled={archived} />
          <SponsorForm sponsor={s} compact />
        </div>
      </div>
    </>
  );
}

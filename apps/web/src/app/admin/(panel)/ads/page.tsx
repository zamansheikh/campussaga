import { ImageIcon, Plus } from "lucide-react";
import Link from "next/link";

import { ListFilters } from "@/components/admin/list-filters";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Pagination, pageParam } from "@/components/admin/pagination";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, query, requireAdmin } from "@/lib/admin/session";
import {
  type AdminPromo,
  type AdminSponsor,
  ctrOf,
  kindInfo,
  kindOrder,
  listOf,
  percentText,
  placementLabel,
  promoFrom,
  type PromoPlacement,
  statusLabel,
  statusText,
  statusTone,
} from "@/lib/admin/sponsors";
import type { Paged } from "@/lib/admin/types";
import { formatDate, formatNumber } from "@/lib/format";

export const metadata = { title: "Ads" };

const PAGE_SIZE = 25;

type Search = { q?: string; status?: string; kind?: string; placement?: string; sponsorId?: string; page?: string };

export default async function AdsPage({ searchParams }: { searchParams: Promise<Search> }) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const [res, sponsors] = await Promise.all([
    load(async () => {
      const r = await api<Paged<AdminPromo> | AdminPromo[]>(
        `/admin/promos${query({ q: sp.q, status: sp.status, kind: sp.kind, placement: sp.placement, sponsorId: sp.sponsorId, page, pageSize: PAGE_SIZE })}`,
      );
      const paged = Array.isArray(r) ? { items: r, total: r.length, page: 1, pageSize: r.length || PAGE_SIZE } : r;
      return { ...paged, items: paged.items.map(promoFrom) };
    }),
    load(async () => listOf(await api<Paged<AdminSponsor> | AdminSponsor[]>(`/admin/sponsors${query({ pageSize: 100 })}`))),
  ]);
  const filtered = Boolean(sp.q || sp.status || sp.kind || sp.placement || sp.sponsorId);
  return (
    <>
      <PageHeader
        title="Ads"
        description="Sponsored content students see in the app: deals, a Today card, Campus feed posts, sponsor lines and campaign sponsors."
        actions={
          <>
            <Button variant="outline" asChild>
              <Link href="/admin/sponsors">Sponsors</Link>
            </Button>
            <Button asChild>
              <Link href="/admin/ads/new">
                <Plus /> New ad
              </Link>
            </Button>
          </>
        }
      />
      <ListFilters
        searchPlaceholder="Search ads"
        selects={[
          { name: "status", label: "Statuses", options: Object.entries(statusLabel).map(([value, label]) => ({ value, label })) },
          { name: "kind", label: "Kinds", options: kindOrder.map((k) => ({ value: k, label: kindInfo[k].label })) },
          {
            name: "placement",
            label: "Places",
            options: (Object.keys(placementLabel) as PromoPlacement[]).map((p) => ({ value: p, label: placementLabel[p] })),
          },
          { name: "sponsorId", label: "Sponsors", options: (sponsors.data ?? []).map((s) => ({ value: s.id, label: s.name })) },
        ]}
      />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.items.length === 0 ? (
        <EmptyState title={filtered ? "No ads match" : "No ads yet"}>
          {filtered ? "Try other filters." : "Add a sponsor, then create a draft ad, check the preview, and publish it."}
        </EmptyState>
      ) : res.data ? (
        <>
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Ad</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="hidden md:table-cell">Runs</TableHead>
                  <TableHead className="hidden text-right lg:table-cell">Today</TableHead>
                  <TableHead className="hidden text-right sm:table-cell">Total</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {res.data.items.map((p) => {
                  const views = p.views ?? 0;
                  const taps = p.taps ?? 0;
                  return (
                    <TableRow key={p.id} className="relative">
                      <TableCell className="max-w-80">
                        <div className="flex items-center gap-3">
                          <Thumb promo={p} />
                          <div className="min-w-0">
                            <Link
                              href={`/admin/ads/${p.id}`}
                              className="block truncate font-medium after:absolute after:inset-0 hover:underline focus-visible:outline-none"
                            >
                              {p.titleEn || (p.kind === "line" ? "Sponsor line" : p.kind === "campaign" ? "Campaign sponsor" : "Untitled")}
                            </Link>
                            <p className="truncate text-xs text-muted-foreground">
                              {p.sponsor?.name ?? "—"} · {kindInfo[p.kind]?.label ?? p.kind}
                              {p.kind === "line" ? ` · ${placementLabel[p.placement] ?? p.placement}` : ""}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={p.status === "live" && p.delivered ? "info" : (statusTone[p.status] ?? "outline")}>{statusText(p)}</Badge>
                      </TableCell>
                      <TableCell className="hidden text-muted-foreground md:table-cell">
                        {formatDate(p.startsAt)} – {formatDate(p.endsAt)}
                      </TableCell>
                      <TableCell className="hidden text-right tabular-nums lg:table-cell">
                        {formatNumber(p.viewsToday ?? 0)} <span className="text-muted-foreground">{plural(p.viewsToday ?? 0, "view")}</span>
                        <br />
                        {formatNumber(p.tapsToday ?? 0)} <span className="text-muted-foreground">{plural(p.tapsToday ?? 0, "tap")}</span>
                      </TableCell>
                      <TableCell className="hidden text-right tabular-nums sm:table-cell">
                        {formatNumber(views)} <span className="text-muted-foreground">{plural(views, "view")}</span>
                        <br />
                        {formatNumber(taps)} <span className="text-muted-foreground">{plural(taps, "tap")} · {percentText(ctrOf(views, taps))}</span>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
          <Pagination basePath="/admin/ads" params={{ q: sp.q, status: sp.status, kind: sp.kind, placement: sp.placement, sponsorId: sp.sponsorId }} page={res.data.page} pageSize={res.data.pageSize} total={res.data.total} />
        </>
      ) : null}
    </>
  );
}

/** The ad's image, or the sponsor's logo, small. */
function Thumb({ promo }: { promo: AdminPromo }) {
  const wide = promo.imageUrl;
  const logo = promo.sponsor?.logoUrl;
  if (wide) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={wide} alt="" className="h-9 w-[4.5rem] shrink-0 rounded-md border object-cover" />;
  }
  if (logo) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={logo} alt="" className="size-9 shrink-0 rounded-full border bg-white object-contain" />;
  }
  return (
    <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-md border bg-muted text-muted-foreground">
      <ImageIcon className="size-4" aria-hidden />
    </span>
  );
}

/** "view" or "views" for [n]. */
function plural(n: number, word: string): string {
  return n === 1 ? word : `${word}s`;
}

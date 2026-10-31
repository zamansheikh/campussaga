import { Plus } from "lucide-react";
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
import { type AdminSponsor, categoryLabel } from "@/lib/admin/sponsors";
import type { Paged } from "@/lib/admin/types";
import { formatDate, formatNumber } from "@/lib/format";

import { SponsorLogo } from "./sponsor-logo";

export const metadata = { title: "Sponsors" };

const PAGE_SIZE = 25;

function host(url?: string) {
  if (!url) return "";
  try {
    return new URL(url).host.replace(/^www\./, "");
  } catch {
    return url;
  }
}

export default async function SponsorsPage({ searchParams }: { searchParams: Promise<{ q?: string; archived?: string; page?: string }> }) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const archived = sp.archived === "yes";
  const res = await load(async () => {
    const r = await api<Paged<AdminSponsor> | AdminSponsor[]>(`/admin/sponsors${query({ q: sp.q, archived: archived ? "true" : undefined, page, pageSize: PAGE_SIZE })}`);
    return Array.isArray(r) ? { items: r, total: r.length, page: 1, pageSize: r.length || PAGE_SIZE } : r;
  });
  return (
    <>
      <PageHeader
        title="Sponsors"
        description="Brands that advertise to students. Their contact details stay with the team; sponsors only ever get totals."
        actions={
          <>
            <Button variant="outline" asChild>
              <Link href="/admin/ads">Ads</Link>
            </Button>
            <Button asChild>
              <Link href="/admin/sponsors/new">
                <Plus /> New sponsor
              </Link>
            </Button>
          </>
        }
      />
      <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <ListFilters searchPlaceholder="Search sponsors" />
        <nav aria-label="Which sponsors" className="inline-flex shrink-0 self-start rounded-lg border bg-muted p-0.5 text-sm">
          {(
            [
              ["Active", undefined],
              ["Archived", "yes"],
            ] as const
          ).map(([label, value]) => {
            const on = (value === "yes") === archived;
            return (
              <Link
                key={label}
                href={`/admin/sponsors${query({ q: sp.q, archived: value })}`}
                aria-current={on ? "page" : undefined}
                className={on ? "rounded-md bg-background px-3 py-1.5 font-medium shadow-sm" : "rounded-md px-3 py-1.5 text-muted-foreground hover:text-foreground"}
              >
                {label}
              </Link>
            );
          })}
        </nav>
      </div>
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.items.length === 0 ? (
        <EmptyState title={sp.q || archived ? "No sponsors match" : "No sponsors yet"}>
          {sp.q || archived ? "Try another search." : "Add a brand with its logo, then create its ads."}
        </EmptyState>
      ) : res.data ? (
        <>
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Sponsor</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead className="hidden text-right sm:table-cell">Live ads</TableHead>
                  <TableHead className="hidden md:table-cell">Contact</TableHead>
                  <TableHead className="hidden lg:table-cell">Added</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {res.data.items.map((s) => (
                  <TableRow key={s.id} className="relative">
                    <TableCell className="max-w-72">
                      <div className="flex items-center gap-3">
                        <SponsorLogo url={s.logoUrl} name={s.name} />
                        <div className="min-w-0">
                          <Link href={`/admin/sponsors/${s.id}`} className="block truncate font-medium after:absolute after:inset-0 hover:underline focus-visible:outline-none">
                            {s.name}
                          </Link>
                          <p className="truncate text-xs text-muted-foreground">{host(s.website) || "No website"}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="flex flex-wrap gap-1">
                        <Badge variant={s.category === "health" ? "info" : "secondary"}>{categoryLabel[s.category] ?? s.category}</Badge>
                        {s.archivedAt ? <Badge variant="outline">Archived</Badge> : null}
                      </span>
                    </TableCell>
                    <TableCell className="hidden text-right tabular-nums sm:table-cell">
                      {formatNumber(s.promos?.live ?? 0)}
                      {s.promos?.total !== undefined ? <span className="text-muted-foreground"> of {formatNumber(s.promos.total)}</span> : null}
                    </TableCell>
                    <TableCell className="hidden max-w-56 md:table-cell">
                      <p className="truncate">{s.contactName || "—"}</p>
                      <p className="truncate text-xs text-muted-foreground">{s.contactPhone || s.contactEmail || ""}</p>
                    </TableCell>
                    <TableCell className="hidden text-muted-foreground lg:table-cell">{formatDate(s.createdAt)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <Pagination basePath="/admin/sponsors" params={{ q: sp.q, archived: sp.archived }} page={res.data.page} pageSize={res.data.pageSize} total={res.data.total} />
        </>
      ) : null}
    </>
  );
}

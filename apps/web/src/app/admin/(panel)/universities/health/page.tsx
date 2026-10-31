import { ArrowDown, ArrowLeft } from "lucide-react";
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
import type { Paged, UniversityHealth } from "@/lib/admin/types";
import { formatNumber } from "@/lib/format";

export const metadata = { title: "University health" };

const PAGE_SIZE = 25;
const sorts = [
  { value: "attention", label: "Needs attention" },
  { value: "students", label: "Students" },
  { value: "verifiedPct", label: "Verified %" },
] as const;

const reasonLabel: Record<string, string> = {
  no_campus_admin: "No campus admin",
  sections_without_cr: "Sections without a CR",
  reports_waiting: "Reports waiting",
  low_verified: "Few verified",
};

type Search = { q?: string; sort?: string; page?: string };

export default async function UniversityHealthPage({ searchParams }: { searchParams: Promise<Search> }) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const sort = sorts.find((s) => s.value === sp.sort)?.value ?? "attention";
  const res = await load(() => api<Paged<UniversityHealth>>(`/admin/universities/health${query({ sort, q: sp.q, page, pageSize: PAGE_SIZE })}`));
  const sortHref = (value: string) => `/admin/universities/health${query({ sort: value === "attention" ? undefined : value, q: sp.q })}`;

  return (
    <>
      <PageHeader
        title="University health"
        description={res.data ? `${formatNumber(res.data.total)} universities. Find the ones that need a campus admin or a CR.` : "Which universities need help."}
        actions={
          <Button variant="outline" asChild>
            <Link href="/admin/universities">
              <ArrowLeft /> Universities
            </Link>
          </Button>
        }
      />
      <nav aria-label="Sort by" className="mb-4 flex flex-wrap items-center gap-2 text-sm">
        <span className="text-muted-foreground">Sort by</span>
        {sorts.map((s) => (
          <Button key={s.value} variant={s.value === sort ? "secondary" : "ghost"} size="sm" asChild>
            <Link href={sortHref(s.value)} aria-current={s.value === sort ? "true" : undefined}>
              {s.value === sort ? <ArrowDown /> : null}
              {s.label}
            </Link>
          </Button>
        ))}
      </nav>
      <ListFilters searchPlaceholder="University name" />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.items.length === 0 ? (
        <EmptyState title="No universities found">Try a different search.</EmptyState>
      ) : res.data ? (
        <>
          <div className="overflow-x-auto rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>University</TableHead>
                  <TableHead className="text-end">Students</TableHead>
                  <TableHead className="text-end">Verified</TableHead>
                  <TableHead className="text-end">Campus admins</TableHead>
                  <TableHead className="text-end">Sections</TableHead>
                  <TableHead className="text-end">With a CR</TableHead>
                  <TableHead className="text-end">Bus routes</TableHead>
                  <TableHead className="text-end">Reports</TableHead>
                  <TableHead className="text-end">Escalations</TableHead>
                  <TableHead>Attention</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {res.data.items.map((u) => (
                  <TableRow key={u.id} className="align-top">
                    <TableCell className="min-w-48 max-w-64 whitespace-normal font-medium">
                      <Link href={`/admin/universities?campusAdminsFor=${u.id}`} className="hover:underline">
                        {u.name}
                      </Link>
                    </TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(u.students)}</TableCell>
                    <TableCell className="text-end tabular-nums">{Math.round(u.verifiedPct)}%</TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(u.campusAdmins)}</TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(u.sections)}</TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(u.sectionsWithCr)}</TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(u.busRoutes)}</TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(u.openReports)}</TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(u.openEscalations)}</TableCell>
                    <TableCell className="min-w-44 whitespace-normal">
                      <div className="flex flex-wrap gap-1">
                        {(u.attention ?? []).length === 0 ? (
                          <span className="text-xs text-muted-foreground">Fine</span>
                        ) : (
                          u.attention.map((a) => (
                            <Badge key={a} variant="warning">
                              {reasonLabel[a] ?? a}
                            </Badge>
                          ))
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <Pagination
            basePath="/admin/universities/health"
            params={{ q: sp.q, sort: sort === "attention" ? undefined : sort }}
            page={page}
            pageSize={res.data.pageSize || PAGE_SIZE}
            total={res.data.total}
          />
        </>
      ) : null}
    </>
  );
}

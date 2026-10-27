import Link from "next/link";

import { ListFilters } from "@/components/admin/list-filters";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Pagination, pageParam } from "@/components/admin/pagination";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, query } from "@/lib/admin/session";
import type { AdminGroup, Paged } from "@/lib/admin/types";
import { allUniversities } from "@/lib/admin/universities";
import { formatDate, formatNumber } from "@/lib/format";

export const metadata = { title: "Class groups" };

const PAGE_SIZE = 25;

type Search = { q?: string; universityId?: string; page?: string };

export default async function GroupsPage({ searchParams }: { searchParams: Promise<Search> }) {
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const [groups, unis] = await Promise.all([
    load(() =>
      api<Paged<AdminGroup>>(
        `/admin/groups${query({ q: sp.q, universityId: sp.universityId, page, pageSize: PAGE_SIZE })}`,
      ),
    ),
    load(() => allUniversities()),
  ]);
  return (
    <>
      <PageHeader
        title="Class groups"
        description={groups.data ? `${formatNumber(groups.data.total)} groups match` : "Every class group (one section's routine)."}
      />
      <ListFilters
        searchPlaceholder="Department, batch or join code"
        universities={unis.data?.map((u) => ({ id: u.id, slug: u.slug, name: u.name }))}
      />
      {groups.error ? (
        <ErrorPanel message={groups.error} />
      ) : groups.data && groups.data.items.length === 0 ? (
        <EmptyState title="No class groups found">Try a different search or university.</EmptyState>
      ) : groups.data ? (
        <>
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Group</TableHead>
                  <TableHead className="hidden md:table-cell">University</TableHead>
                  <TableHead className="hidden lg:table-cell">CR</TableHead>
                  <TableHead className="text-end">Members</TableHead>
                  <TableHead className="hidden text-end sm:table-cell">Classes</TableHead>
                  <TableHead className="hidden xl:table-cell">Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {groups.data.items.map((g) => (
                  <TableRow key={g.id} className="relative">
                    <TableCell className="max-w-72">
                      <Link
                        href={`/admin/groups/${g.id}`}
                        className="font-medium whitespace-normal after:absolute after:inset-0 hover:underline focus-visible:outline-none"
                      >
                        {g.title}
                      </Link>
                      <p className="text-xs text-muted-foreground">
                        {g.semester} · <span className="font-mono">{g.joinCode}</span>
                      </p>
                    </TableCell>
                    <TableCell className="hidden max-w-56 truncate md:table-cell">{g.university.name}</TableCell>
                    <TableCell className="hidden max-w-48 lg:table-cell">
                      {g.crs.length === 0 ? (
                        <Badge variant="warning">No CR</Badge>
                      ) : (
                        <span className="block truncate">{g.crs.map((c) => c.name || c.email).join(", ")}</span>
                      )}
                    </TableCell>
                    <TableCell className="text-end tabular-nums">{formatNumber(g.members)}</TableCell>
                    <TableCell className="hidden text-end tabular-nums sm:table-cell">{formatNumber(g.slots)}</TableCell>
                    <TableCell className="hidden text-muted-foreground xl:table-cell">{formatDate(g.createdAt)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <Pagination
            basePath="/admin/groups"
            params={{ q: sp.q, universityId: sp.universityId }}
            page={page}
            pageSize={groups.data.pageSize || PAGE_SIZE}
            total={groups.data.total}
          />
        </>
      ) : null}
    </>
  );
}

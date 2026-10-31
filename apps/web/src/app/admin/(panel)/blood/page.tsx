import Link from "next/link";

import { ListFilters } from "@/components/admin/list-filters";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Pagination, pageParam } from "@/components/admin/pagination";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, query, requestNow, requireAdmin } from "@/lib/admin/session";
import type { BloodRequest, Paged } from "@/lib/admin/types";
import { allUniversities } from "@/lib/admin/universities";
import { formatDateTime, formatNumber, timeAgo } from "@/lib/format";
import { cn } from "@/lib/utils";

import { CloseRequestButton } from "./close-button";

export const metadata = { title: "Blood donation" };

const PAGE_SIZE = 25;
const tabs = [
  { value: "open", label: "Open" },
  { value: "fulfilled", label: "Fulfilled" },
  { value: "closed", label: "Closed" },
  { value: "all", label: "All" },
] as const;

const statusTone: Record<string, "success" | "warning" | "outline"> = { open: "warning", fulfilled: "success", closed: "outline" };
const statusLabel: Record<string, string> = { open: "Open", fulfilled: "Fulfilled", closed: "Closed" };

type Search = { q?: string; status?: string; universityId?: string; page?: string };

export default async function BloodPage({ searchParams }: { searchParams: Promise<Search> }) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const status = tabs.find((t) => t.value === sp.status)?.value ?? "open";
  const [res, unis] = await Promise.all([
    load(() =>
      api<Paged<BloodRequest>>(
        `/admin/blood/requests${query({ status, universityId: sp.universityId, q: sp.q, page, pageSize: PAGE_SIZE })}`,
      ),
    ),
    load(() => allUniversities()),
  ]);
  const now = requestNow();
  const tabHref = (value: string) =>
    `/admin/blood${query({ status: value === "open" ? undefined : value, universityId: sp.universityId, q: sp.q })}`;

  return (
    <>
      <PageHeader
        title="Blood donation"
        description={
          res.data
            ? `${formatNumber(res.data.total)} requests match`
            : "Blood requests students have posted. Close one that is fake or a duplicate."
        }
      />
      <nav aria-label="Status" className="mb-4 inline-flex w-fit flex-wrap gap-1 rounded-lg bg-muted p-1">
        {tabs.map((t) => (
          <Link
            key={t.value}
            href={tabHref(t.value)}
            aria-current={t.value === status ? "page" : undefined}
            className={cn(
              "rounded-md px-3 py-1.5 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground",
              "focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
              t.value === status && "bg-background text-foreground shadow-sm",
            )}
          >
            {t.label}
          </Link>
        ))}
      </nav>
      <ListFilters
        searchPlaceholder="Hospital, area, contact or email"
        universities={unis.data?.map((u) => ({ id: u.id, slug: u.slug, name: u.name }))}
      />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.items.length === 0 ? (
        <EmptyState title="No blood requests found">Try a different tab, search or university.</EmptyState>
      ) : res.data ? (
        <>
          <div className="overflow-x-auto rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Group</TableHead>
                  <TableHead className="text-end">Units</TableHead>
                  <TableHead>Hospital</TableHead>
                  <TableHead>Needed by</TableHead>
                  <TableHead className="hidden lg:table-cell">University</TableHead>
                  <TableHead className="hidden lg:table-cell">Requester</TableHead>
                  <TableHead className="hidden text-end md:table-cell">Notified</TableHead>
                  <TableHead className="hidden text-end md:table-cell">Responses</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="w-0" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {res.data.items.map((r) => (
                  <TableRow key={r.id} className="align-top">
                    <TableCell>
                      <Badge variant="destructive">{r.bloodGroup}</Badge>
                    </TableCell>
                    <TableCell className="text-end tabular-nums">{r.units}</TableCell>
                    <TableCell className="min-w-56 max-w-72 whitespace-normal">
                      <p className="font-medium">{r.hospital}</p>
                      {r.area ? <p className="text-xs text-muted-foreground">{r.area}</p> : null}
                      {r.note ? (
                        <p className="mt-1 line-clamp-2 text-xs text-muted-foreground" title={r.note}>
                          {r.note}
                        </p>
                      ) : null}
                    </TableCell>
                    <TableCell className="whitespace-normal">
                      <p className="tabular-nums">{formatDateTime(r.neededBy)}</p>
                      {r.urgent ? (
                        <Badge variant="warning" className="mt-1">
                          Urgent
                        </Badge>
                      ) : null}
                    </TableCell>
                    <TableCell className="hidden max-w-44 truncate lg:table-cell">{r.university?.name}</TableCell>
                    <TableCell className="hidden max-w-56 lg:table-cell">
                      {r.requester ? (
                        <>
                          <Link href={`/admin/users/${r.requester.id}`} className="block truncate font-medium hover:underline">
                            {r.requester.name || r.requester.email}
                          </Link>
                          {r.requester.name ? (
                            <p className="truncate text-xs text-muted-foreground">{r.requester.email}</p>
                          ) : null}
                        </>
                      ) : (
                        <span className="text-muted-foreground">Deleted account</span>
                      )}
                      {/* The contact on the request (often the requester). */}
                      <p className="mt-1 truncate text-xs text-muted-foreground">
                        {r.contactName && r.contactName !== r.requester?.name ? `${r.contactName} · ` : ""}
                        {r.contactPhone}
                      </p>
                    </TableCell>
                    <TableCell className="hidden text-end tabular-nums md:table-cell">{formatNumber(r.notified)}</TableCell>
                    <TableCell className="hidden text-end tabular-nums md:table-cell">{formatNumber(r.responses)}</TableCell>
                    <TableCell>
                      <Badge variant={statusTone[r.status] ?? "outline"}>{statusLabel[r.status] ?? r.status}</Badge>
                      <p className="mt-1 text-xs whitespace-nowrap text-muted-foreground">{timeAgo(r.createdAt, now)}</p>
                    </TableCell>

                    <TableCell>
                      {r.status === "open" ? (
                        <CloseRequestButton requestId={r.id} summary={`The ${r.bloodGroup} request at ${r.hospital}`} />
                      ) : null}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <Pagination
            basePath="/admin/blood"
            params={{ status: status === "open" ? undefined : status, universityId: sp.universityId, q: sp.q }}
            page={page}
            pageSize={res.data.pageSize || PAGE_SIZE}
            total={res.data.total}
          />
        </>
      ) : null}
    </>
  );
}

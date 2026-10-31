import { ListFilters } from "@/components/admin/list-filters";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Pagination, pageParam } from "@/components/admin/pagination";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { type AdminReferral, flagLabel, uniName } from "@/lib/admin/growth";
import { load } from "@/lib/admin/load";
import { api, query, requireAdmin } from "@/lib/admin/session";
import type { Paged } from "@/lib/admin/types";
import { formatDateTime, formatNumber } from "@/lib/format";

import { InviteActions } from "../campaigns/invite-actions";

export const metadata = { title: "Referrals" };

const PAGE_SIZE = 25;

export default async function ReferralsPage({ searchParams }: { searchParams: Promise<{ q?: string; flag?: string; page?: string }> }) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const res = await load(() => api<Paged<AdminReferral>>(`/admin/referrals${query({ q: sp.q, flag: sp.flag, page, pageSize: PAGE_SIZE })}`));
  return (
    <>
      <PageHeader
        title="Referrals"
        description={res.data ? `${formatNumber(res.data.total)} invites match` : "Every invite, with the reasons it looks fine or suspicious."}
      />
      <ListFilters
        searchPlaceholder="Name or email of either student"
        selects={[
          {
            name: "flag",
            label: "Flags",
            options: Object.entries(flagLabel).map(([value, label]) => ({ value, label })),
          },
        ]}
      />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.items.length === 0 ? (
        <EmptyState title="No invites found">Try a different search or flag.</EmptyState>
      ) : res.data ? (
        <>
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Invited by</TableHead>
                  <TableHead>Friend</TableHead>
                  <TableHead className="hidden md:table-cell">Progress</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {res.data.items.map((r) => (
                  <TableRow key={r.referred.id} className="align-top">
                    <TableCell className="max-w-56 whitespace-normal">
                      <p className="font-medium">{r.referrer.name || r.referrer.email || "No name"}</p>
                      <p className="truncate text-xs text-muted-foreground">{uniName(r.referrer.university)}</p>
                    </TableCell>
                    <TableCell className="max-w-56 whitespace-normal">
                      <p className="font-medium">{r.referred.name || r.referred.email || "No name"}</p>
                      <p className="truncate text-xs text-muted-foreground">{uniName(r.referred.university)}</p>
                    </TableCell>
                    <TableCell className="hidden text-xs text-muted-foreground md:table-cell">
                      {r.source === "join" ? "Class invite" : "Personal link"} · {formatDateTime(r.createdAt)}
                      <br />
                      verified via {r.verifiedVia || "not yet"} · {r.activeDays} of 3 active days
                    </TableCell>
                    <TableCell className="whitespace-normal">
                      <div className="flex flex-wrap gap-1">
                        {r.disqualified ? <Badge variant="destructive">Disqualified</Badge> : r.qualifiedAt ? <Badge variant="success">Qualified</Badge> : <Badge variant="secondary">Pending</Badge>}
                        {(r.flags ?? []).map((f) => (
                          <Badge key={f} variant="warning">
                            {flagLabel[f] ?? f}
                          </Badge>
                        ))}
                      </div>
                      {r.disqualified && r.reason ? <p className="mt-1 text-xs text-muted-foreground">{r.reason}</p> : null}
                    </TableCell>
                    <TableCell className="text-end">
                      <InviteActions referredId={r.referred.id} referredName={r.referred.name || "this student"} disqualified={r.disqualified} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <Pagination basePath="/admin/referrals" params={{ q: sp.q, flag: sp.flag }} page={page} pageSize={res.data.pageSize || PAGE_SIZE} total={res.data.total} />
        </>
      ) : null}
    </>
  );
}

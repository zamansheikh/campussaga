import Link from "next/link";

import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Pagination, pageParam } from "@/components/admin/pagination";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, query, requireAdmin } from "@/lib/admin/session";
import type { AuditEntry, Paged } from "@/lib/admin/types";
import { formatDateTime } from "@/lib/format";

export const metadata = { title: "Audit log" };

const PAGE_SIZE = 50;

const actions: Record<string, string> = {
  "admin.sign_in": "Signed in",
  "user.update": "Changed a user",
  "user.delete": "Deleted a user",
  "university.create": "Added a university",
  "university.update": "Changed a university",
  "university.domains": "Changed university domains",
  "group.member.role": "Changed a member's role",
  "group.member.remove": "Removed a member",
  "group.delete": "Deleted a group",
  "config.update": "Changed a setting",
  "push.send": "Sent a push",
  "issue.status": "Changed an issue's status",
  "issue.official_reply": "Posted an official reply",
  "moderation.approve": "Approved a post",
  "moderation.hide": "Hid a post",
  "moderation.remove": "Removed a post",
  "moderation.restore": "Restored a post",
  "moderation.ban": "Banned a post's author",
  "moderation.dismiss": "Dismissed reports",
  "blood.close": "Closed a blood request",
  "transport.live.end": "Ended live bus sharing",
  "staff.add": "Added staff",
  "staff.remove": "Removed staff",
};

function targetHref(
  type: string | null,
  id: string | null,
): string | undefined {
  if (!id) return undefined;
  if (type === "user") return `/admin/users/${id}`;
  if (type === "group") return `/admin/groups/${id}`;
  if (type === "issue") return `/admin/moderation/issues/${id}`;
  return undefined;
}

export default async function AuditPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string }>;
}) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const res = await load(() =>
    api<Paged<AuditEntry>>(
      `/admin/audit${query({ page, pageSize: PAGE_SIZE })}`,
    ),
  );
  return (
    <>
      <PageHeader
        title="Audit log"
        description="Every admin, moderator and official action, newest first. Entries can't be edited or deleted, and never say who wrote a post."
      />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.items.length === 0 ? (
        <EmptyState title="Nothing recorded yet" />
      ) : res.data ? (
        <>
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>When</TableHead>
                  <TableHead>Admin</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead className="hidden md:table-cell">
                    Details
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {res.data.items.map((a) => {
                  const href = targetHref(a.targetType, a.targetId);
                  const hasMeta = a.meta && Object.keys(a.meta).length > 0;
                  return (
                    <TableRow key={a.id} className="align-top">
                      <TableCell className="text-muted-foreground tabular-nums">
                        {formatDateTime(a.createdAt)}
                      </TableCell>
                      <TableCell className="max-w-48">
                        {a.actor ? (
                          <>
                            <p className="truncate font-medium">
                              {a.actor.name || a.actor.email}
                            </p>
                            {a.actor.name ? (
                              <p className="truncate text-xs text-muted-foreground">
                                {a.actor.email}
                              </p>
                            ) : null}
                          </>
                        ) : (
                          <span className="text-muted-foreground">
                            Deleted admin
                          </span>
                        )}
                      </TableCell>
                      <TableCell className="max-w-56 whitespace-normal">
                        <p>{actions[a.action] ?? a.action}</p>
                        <Badge
                          variant="outline"
                          className="mt-1 font-mono text-[11px]"
                        >
                          {a.action}
                        </Badge>
                        {a.targetId ? (
                          <p className="mt-1 truncate text-xs text-muted-foreground">
                            {a.targetType}:{" "}
                            {href ? (
                              <Link
                                href={href}
                                className="font-mono hover:underline"
                              >
                                {a.targetId}
                              </Link>
                            ) : (
                              <span className="font-mono">{a.targetId}</span>
                            )}
                          </p>
                        ) : null}
                      </TableCell>
                      <TableCell className="hidden max-w-md md:table-cell">
                        {hasMeta ? (
                          <details className="group">
                            <summary className="cursor-pointer text-sm text-primary select-none hover:underline">
                              Show details
                            </summary>
                            <pre className="mt-2 max-h-64 overflow-auto rounded-md bg-muted p-2 text-xs whitespace-pre-wrap">
                              {JSON.stringify(a.meta, null, 2)}
                            </pre>
                          </details>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
          <Pagination
            basePath="/admin/audit"
            params={{}}
            page={page}
            pageSize={res.data.pageSize || PAGE_SIZE}
            total={res.data.total}
          />
        </>
      ) : null}
    </>
  );
}

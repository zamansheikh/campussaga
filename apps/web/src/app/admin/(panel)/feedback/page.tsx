import Link from "next/link";

import { ListFilters } from "@/components/admin/list-filters";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Pagination, pageParam } from "@/components/admin/pagination";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { feedbackKindLabel, feedbackKindTone, feedbackStatusLabel, feedbackStatusTone, universityName } from "@/lib/admin/feedback";
import { load } from "@/lib/admin/load";
import { api, query, requestNow, requireAdmin } from "@/lib/admin/session";
import type { FeedbackItem, Paged } from "@/lib/admin/types";
import { formatNumber, timeAgo } from "@/lib/format";
import { cn } from "@/lib/utils";

export const metadata = { title: "Feedback" };

const PAGE_SIZE = 25;
const tabs = [
  { value: "open", label: "Open" },
  { value: "closed", label: "Closed" },
  { value: "all", label: "All" },
] as const;

type Search = { q?: string; status?: string; kind?: string; page?: string };

export default async function FeedbackPage({ searchParams }: { searchParams: Promise<Search> }) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const tab = tabs.find((t) => t.value === sp.status)?.value ?? "open";
  const kind = ["bug", "idea", "other"].includes(sp.kind ?? "") ? sp.kind : undefined;
  const res = await load(() =>
    api<Paged<FeedbackItem>>(`/admin/feedback${query({ status: tab === "all" ? undefined : tab, kind, q: sp.q, page, pageSize: PAGE_SIZE })}`),
  );
  const now = requestNow();
  const tabHref = (value: string) => `/admin/feedback${query({ status: value === "open" ? undefined : value, kind, q: sp.q })}`;

  return (
    <>
      <PageHeader
        title="Feedback"
        description={res.data ? `${formatNumber(res.data.total)} match` : "Bug reports and ideas from students. Reply, and the student gets a push."}
      />
      <nav aria-label="Status" className="mb-4 inline-flex w-fit flex-wrap gap-1 rounded-lg bg-muted p-1">
        {tabs.map((t) => (
          <Link
            key={t.value}
            href={tabHref(t.value)}
            aria-current={t.value === tab ? "page" : undefined}
            className={cn(
              "rounded-md px-3 py-1.5 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground",
              "focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
              t.value === tab && "bg-background text-foreground shadow-sm",
            )}
          >
            {t.label}
          </Link>
        ))}
      </nav>
      <ListFilters
        searchPlaceholder="Message or email"
        selects={[
          {
            name: "kind",
            label: "Kinds",
            options: [
              { value: "bug", label: "Bugs" },
              { value: "idea", label: "Ideas" },
              { value: "other", label: "Other" },
            ],
          },
        ]}
      />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.items.length === 0 ? (
        <EmptyState title="No feedback found">Try a different tab, kind or search.</EmptyState>
      ) : res.data ? (
        <>
          <div className="overflow-x-auto rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-0">
                    <span className="sr-only">Unread</span>
                  </TableHead>
                  <TableHead>Feedback</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="hidden md:table-cell">Student</TableHead>
                  <TableHead className="hidden lg:table-cell">App</TableHead>
                  <TableHead className="text-end">When</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {res.data.items.map((f) => {
                  const unread = f.teamUnread > 0 || f.status === "new";
                  return (
                    <TableRow key={f.id} className="align-top">
                      <TableCell>
                        {unread ? <span className="mt-1.5 block size-2.5 rounded-full bg-primary" role="img" aria-label="Unread" /> : null}
                      </TableCell>
                      <TableCell className="min-w-56 max-w-lg whitespace-normal">
                        <Badge variant={feedbackKindTone[f.kind] ?? "outline"} className="mb-1">
                          {feedbackKindLabel[f.kind] ?? f.kind}
                        </Badge>
                        <Link href={`/admin/feedback/${f.id}`} className={cn("line-clamp-2 block hover:underline", unread && "font-medium")}>
                          {f.message}
                        </Link>
                        {f.images?.length ? <p className="mt-1 text-xs text-muted-foreground">{f.images.length} screenshot{f.images.length === 1 ? "" : "s"}</p> : null}
                      </TableCell>
                      <TableCell>
                        <Badge variant={feedbackStatusTone[f.status] ?? "outline"}>{feedbackStatusLabel[f.status] ?? f.status}</Badge>
                      </TableCell>
                      <TableCell className="hidden max-w-56 whitespace-normal md:table-cell">
                        {f.user ? (
                          <>
                            <Link href={`/admin/users/${f.user.id}`} className="block truncate text-sm hover:underline">
                              {f.user.name || f.user.email}
                            </Link>
                            {universityName(f.user.university) ? <p className="truncate text-xs text-muted-foreground">{universityName(f.user.university)}</p> : null}
                          </>
                        ) : (
                          <span className="text-muted-foreground">Deleted account</span>
                        )}
                      </TableCell>
                      <TableCell className="hidden text-xs text-muted-foreground lg:table-cell">
                        {f.appVersion ? `${f.appVersion}${f.build ? ` (${f.build})` : ""}` : "—"}
                        {f.platform ? <span className="block capitalize">{f.platform}</span> : null}
                      </TableCell>
                      <TableCell className="text-end text-xs whitespace-nowrap text-muted-foreground">{timeAgo(f.lastMessageAt ?? f.createdAt, now)}</TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
          <Pagination
            basePath="/admin/feedback"
            params={{ status: tab === "open" ? undefined : tab, kind, q: sp.q }}
            page={page}
            pageSize={res.data.pageSize || PAGE_SIZE}
            total={res.data.total}
          />
        </>
      ) : null}
    </>
  );
}

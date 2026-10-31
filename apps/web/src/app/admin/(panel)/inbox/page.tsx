import { CheckCircle2, MessageSquareText, ShieldHalf } from "lucide-react";
import Link from "next/link";

import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { getInbox } from "@/lib/admin/inbox";
import { load } from "@/lib/admin/load";
import { requestNow, requireAdmin } from "@/lib/admin/session";
import type { AutoVouchBlock, Escalation } from "@/lib/admin/types";
import { allUniversities } from "@/lib/admin/universities";
import { formatNumber, timeAgo } from "@/lib/format";

import { ApproveDomainDialog, RejectDomainButton, ResolveButton } from "./inbox-actions";

export const metadata = { title: "Needs attention" };

const kindLabel: Record<string, string> = { student: "A student", section: "A section", report: "A report", other: "Other" };

export default async function InboxPage() {
  await requireAdmin();
  const [res, unis] = await Promise.all([getInbox(), load(() => allUniversities())]);
  const now = requestNow();
  const inbox = res.data;
  const universities = (unis.data ?? []).map((u) => ({ id: u.id, slug: u.slug, name: u.name }));
  const escalations = inbox?.escalations ?? [];
  const requests = inbox?.domainRequests ?? [];
  const without = inbox?.universitiesWithoutCampusAdmin ?? [];
  const blocks = inbox?.autoVouchBlocks ?? [];
  const reports = inbox?.reportsWaiting ?? 0;
  const feedback = inbox?.feedbackNew ?? 0;
  const nothing = inbox && escalations.length + requests.length + without.length + blocks.length + reports + feedback === 0;

  return (
    <>
      <PageHeader title="Needs attention" description="What campus admins and students sent to the VarsityKotha team, and where a university needs help." />
      {res.error || !inbox ? (
        <ErrorPanel message={res.error ?? "No data."} />
      ) : (
        <div className="space-y-6">
          {nothing ? (
            <div className="flex items-center gap-3 rounded-xl border bg-card p-4 text-sm">
              <CheckCircle2 className="size-5 text-success" aria-hidden /> Nothing needs you right now.
            </div>
          ) : null}

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Open escalations ({formatNumber(escalations.length)})</CardTitle>
              <CardDescription>Campus admins asked the team for help.</CardDescription>
            </CardHeader>
            <CardContent>
              {escalations.length === 0 ? (
                <p className="text-sm text-muted-foreground">None open.</p>
              ) : (
                <ul className="divide-y">
                  {escalations.map((e) => (
                    <li key={e.id} className="flex flex-col gap-2 py-3 sm:flex-row sm:items-start sm:justify-between">
                      <div className="min-w-0 space-y-1">
                        <p className="flex flex-wrap items-center gap-2 text-sm font-medium">
                          <Link href={`/admin/universities`} className="hover:underline">
                            {escalationUniversity(e)}
                          </Link>
                          <Badge variant="outline">{kindLabel[e.kind] ?? e.kind}</Badge>
                        </p>
                        <p className="text-sm whitespace-pre-wrap break-words">{e.note}</p>
                        <p className="text-xs text-muted-foreground">
                          {escalationWho(e)} · {timeAgo(e.createdAt, now)}
                          {e.kind === "student" && e.targetId ? (
                            <>
                              {" "}
                              ·{" "}
                              <Link href={`/admin/users/${e.targetId}`} className="hover:underline">
                                Open the student
                              </Link>
                            </>
                          ) : null}
                        </p>
                      </div>
                      <ResolveButton escalationId={e.id} />
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Domain requests ({formatNumber(requests.length)})</CardTitle>
              <CardDescription>Students whose university email isn&apos;t recognized yet.</CardDescription>
            </CardHeader>
            <CardContent>
              {requests.length === 0 ? (
                <p className="text-sm text-muted-foreground">None open.</p>
              ) : (
                <ul className="divide-y">
                  {requests.map((r) => (
                    <li key={r.id} className="flex flex-col gap-2 py-3 sm:flex-row sm:items-start sm:justify-between">
                      <div className="min-w-0 space-y-1">
                        <p className="flex flex-wrap items-center gap-2 text-sm font-medium">
                          <span className="font-mono">{r.domain}</span>
                          {r.mxOk ? <Badge variant="success">Receives email</Badge> : <Badge variant="warning">No mail server found</Badge>}
                        </p>
                        <p className="truncate text-sm text-muted-foreground">{r.email}</p>
                        <p className="text-sm">
                          {r.universityName ? <>They wrote: &ldquo;{r.universityName}&rdquo;</> : r.universityId ? "They picked a university" : "No university given"}
                          <span className="text-xs text-muted-foreground"> · {timeAgo(r.createdAt, now)}</span>
                        </p>
                      </div>
                      <div className="flex shrink-0 gap-2">
                        <ApproveDomainDialog requestId={r.id} domain={r.domain} universityId={r.universityId} universities={universities} />
                        <RejectDomainButton requestId={r.id} domain={r.domain} />
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Universities without a campus admin ({formatNumber(without.length)})</CardTitle>
              <CardDescription>With at least 5 students. Open one to appoint a trusted, verified student.</CardDescription>
            </CardHeader>
            <CardContent>
              {without.length === 0 ? (
                <p className="text-sm text-muted-foreground">Every bigger university has one.</p>
              ) : (
                <ul className="divide-y">
                  {without.map((u) => (
                    <li key={u.id} className="flex items-center justify-between gap-3 py-2.5">
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium">{u.name}</p>
                        <p className="text-xs text-muted-foreground">{formatNumber(u.students)} students</p>
                      </div>
                      <Button variant="outline" size="sm" asChild>
                        <Link href={`/admin/universities?campusAdminsFor=${u.id}`}>Appoint</Link>
                      </Button>
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Automatic vouch blocks, last 14 days ({formatNumber(blocks.length)})</CardTitle>
              <CardDescription>People blocked from vouching or confirming after two of their students lost verification.</CardDescription>
            </CardHeader>
            <CardContent>
              {blocks.length === 0 ? (
                <p className="text-sm text-muted-foreground">None.</p>
              ) : (
                <ul className="divide-y">
                  {blocks.map((b) => (
                    <li key={b.userId} className="flex items-center justify-between gap-3 py-2.5">
                      <div className="min-w-0">
                        <Link href={`/admin/users/${b.userId}`} className="truncate text-sm font-medium hover:underline">
                          {blockName(b)}
                        </Link>
                        {b.reason ? <p className="truncate text-xs text-muted-foreground">{b.reason}</p> : null}
                      </div>
                      <span className="shrink-0 text-xs text-muted-foreground">{timeAgo(b.createdAt, now)}</span>
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>

          <div className="grid gap-4 sm:grid-cols-2">
            <Link
              href="/admin/moderation"
              className="flex items-center gap-3 rounded-xl border bg-card p-4 transition-colors hover:bg-muted/50 focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
            >
              <ShieldHalf className="size-5 text-muted-foreground" aria-hidden />
              <span className="text-sm">
                <span className="block text-xl font-semibold tabular-nums">{formatNumber(reports)}</span>
                Reports waiting in Moderation
              </span>
            </Link>
            <Link
              href="/admin/feedback"
              className="flex items-center gap-3 rounded-xl border bg-card p-4 transition-colors hover:bg-muted/50 focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
            >
              <MessageSquareText className="size-5 text-muted-foreground" aria-hidden />
              <span className="text-sm">
                <span className="block text-xl font-semibold tabular-nums">{formatNumber(feedback)}</span>
                Feedback, new or with a reply
              </span>
            </Link>
          </div>
        </div>
      )}
    </>
  );
}

function escalationUniversity(e: Escalation): string {
  return e.university?.name ?? e.universityName ?? "A university";
}

function escalationWho(e: Escalation): string {
  return `From ${e.createdBy?.name ?? e.createdByName ?? "a campus admin"}`;
}

function blockName(b: AutoVouchBlock): string {
  return b.user?.name ?? b.name ?? "A student";
}

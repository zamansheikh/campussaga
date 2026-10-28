import { ArrowLeft, EyeOff, Flag, Lock, MapPin, MessageSquare, ShieldAlert, ThumbsUp } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

import { CheckedPhoto } from "@/components/admin/moderation/checked-photo";
import { ModerationButtons } from "@/components/admin/moderation/moderation-buttons";
import { ErrorPanel } from "@/components/admin/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ApiError } from "@/lib/admin/errors";
import { load } from "@/lib/admin/load";
import { api, getAdmin, requestNow } from "@/lib/admin/session";
import type { ModerationIssue, VoiceComment, VoiceReport } from "@/lib/admin/types";
import {
  actorLabel,
  authorName,
  categoryLabel,
  handleText,
  holdReasonLabel,
  label,
  reportReasonLabel,
  reportStateLabel,
  statusLabel,
  statusTone,
  visibilityLabel,
  visibilityTone,
} from "@/lib/admin/voice";
import { formatDateTime, formatNumber, timeAgo } from "@/lib/format";

export const metadata = { title: "Moderation item" };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function ModerationIssuePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!UUID.test(id)) notFound();
  await getAdmin();
  const res = await load(async () => {
    try {
      return await api<ModerationIssue>(`/moderation/issues/${id}`);
    } catch (e) {
      if (e instanceof ApiError && e.code === "ISSUE_NOT_FOUND") notFound();
      throw e;
    }
  });
  const now = requestNow();

  return (
    <>
      <Button variant="ghost" size="sm" className="-ms-2 mb-3" asChild>
        <Link href="/admin/moderation">
          <ArrowLeft /> Moderation
        </Link>
      </Button>
      {res.error || !res.data ? (
        <ErrorPanel message={res.error ?? "No data."} />
      ) : (
        <IssueView issue={res.data} now={now} />
      )}
    </>
  );
}

function IssueView({ issue, now }: { issue: ModerationIssue; now: number }) {
  const issueReports = issue.reports.filter((r) => r.targetType === "issue");
  const openReports = issueReports.filter((r) => r.state === "open").length;
  return (
    <div className="space-y-6">
      <div
        role="note"
        className="flex items-start gap-3 rounded-xl border border-primary/30 bg-primary-soft/40 p-3 text-sm"
      >
        <EyeOff className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden />
        <p>
          <span className="font-medium">Authors are anonymous — no one can see who wrote this.</span>{" "}
          <span className="text-muted-foreground">
            Not you, not the university. Moderate what is written, and ban without knowing who.
          </span>
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-[1fr_20rem]">
        <div className="min-w-0 space-y-6">
          <section aria-labelledby="issue-title">
            <div className="flex flex-wrap items-center gap-1.5">
              <Badge variant="soft">{label(categoryLabel, issue.category)}</Badge>
              {issue.private ? (
                <Badge variant="warning">
                  <Lock aria-hidden /> Private safety report
                </Badge>
              ) : null}
              <Badge variant={statusTone[issue.status] ?? "outline"}>{label(statusLabel, issue.status)}</Badge>
              <Badge variant={visibilityTone[issue.visibility] ?? "outline"}>{label(visibilityLabel, issue.visibility)}</Badge>
            </div>
            <h1 id="issue-title" className="mt-3 text-2xl font-semibold tracking-tight">
              {issue.title}
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              {issue.author ? `Posted with a name: ${authorName(issue.author)}` : "Anonymous"} · about{" "}
              {timeAgo(issue.createdAt, now)}
              {issue.locationLabel ? (
                <>
                  {" · "}
                  <MapPin className="inline size-3.5 align-[-2px]" aria-hidden /> {issue.locationLabel}
                </>
              ) : null}
            </p>
            {issue.holdReason ? (
              <p className="mt-3 flex items-start gap-2 rounded-md bg-warning-soft p-2 text-sm text-warning">
                <ShieldAlert className="mt-0.5 size-4 shrink-0" aria-hidden />
                {issue.holdReason === "reports" || issue.holdReason === "moderator"
                  ? label(holdReasonLabel, issue.holdReason)
                  : `Held by the automatic check: ${label(holdReasonLabel, issue.holdReason)}`}
              </p>
            ) : null}
            {issue.removedReason ? (
              <p className="mt-3 rounded-md bg-destructive/10 p-2 text-sm text-destructive">
                Removed: {issue.removedReason}
              </p>
            ) : null}
            <p className="mt-4 text-[15px] leading-relaxed whitespace-pre-line">{issue.body}</p>
          </section>

          {issue.images.length > 0 ? (
            <section aria-label="Photos">
              <ul className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                {issue.images.map((img, i) => (
                  <li key={img.id}>
                    <CheckedPhoto
                      id={img.id}
                      width={img.width}
                      height={img.height}
                      index={i}
                      count={issue.images.length}
                      check={issue.photoChecks?.find((c) => c.imageId === img.id)}
                    />
                  </li>
                ))}
              </ul>
            </section>
          ) : null}

          <section aria-labelledby="timeline-title">
            <h2 id="timeline-title" className="mb-2 text-base font-semibold">
              Timeline
            </h2>
            {issue.timeline.length === 0 ? (
              <p className="text-sm text-muted-foreground">No status changes yet.</p>
            ) : (
              <ol className="space-y-3 border-s ps-4">
                {issue.timeline.map((t, i) => (
                  <li key={i} className="relative">
                    <span className="absolute top-1.5 -start-[21px] size-2.5 rounded-full bg-primary" aria-hidden />
                    <p className="text-sm">
                      <span className="font-medium">{label(statusLabel, t.to)}</span>
                      <span className="text-muted-foreground">
                        {" "}
                        from {label(statusLabel, t.from)} · {t.actorTitle || label(actorLabel, t.actorKind)} ·{" "}
                        {formatDateTime(t.createdAt)}
                      </span>
                    </p>
                    {t.note ? <p className="mt-0.5 text-sm text-muted-foreground whitespace-pre-line">{t.note}</p> : null}
                  </li>
                ))}
              </ol>
            )}
          </section>

          <section aria-labelledby="comments-title">
            <h2 id="comments-title" className="mb-2 flex items-center gap-2 text-base font-semibold">
              <MessageSquare className="size-4 text-muted-foreground" aria-hidden /> Comments
              <span className="font-normal text-muted-foreground">({formatNumber(issue.comments.length)})</span>
            </h2>
            {issue.comments.length === 0 ? (
              <p className="text-sm text-muted-foreground">No comments.</p>
            ) : (
              <ul className="space-y-3">
                {issue.comments.map((c) => (
                  <CommentRow
                    key={c.id}
                    comment={c}
                    issueId={issue.id}
                    reports={issue.reports.filter((r) => r.targetType === "comment" && r.targetId === c.id)}
                    now={now}
                  />
                ))}
              </ul>
            )}
          </section>
        </div>

        <aside className="space-y-4 lg:sticky lg:top-20 lg:self-start" aria-label="Moderation">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Actions</CardTitle>
              <CardDescription>On the issue itself. Comments have their own.</CardDescription>
            </CardHeader>
            <CardContent>
              <ModerationButtons
                target={{ type: "issue", id: issue.id, issueId: issue.id }}
                visibility={issue.visibility}
                openReports={openReports}
              />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <Flag className="size-4 text-muted-foreground" aria-hidden /> Reports
              </CardTitle>
              <CardDescription>Who reported is never shown.</CardDescription>
            </CardHeader>
            <CardContent>
              {issueReports.length === 0 ? (
                <p className="text-sm text-muted-foreground">No reports on this issue.</p>
              ) : (
                <ReportList reports={issueReports} now={now} />
              )}
            </CardContent>
          </Card>

          <Card>
            <CardContent className="grid grid-cols-3 gap-2 pt-0 text-center">
              <Count icon={ThumbsUp} label="Me too" value={issue.meTooCount} />
              <Count icon={MessageSquare} label="Comments" value={issue.commentCount} />
              <Count icon={Flag} label="Open reports" value={openReports} />
            </CardContent>
          </Card>
        </aside>
      </div>
    </div>
  );
}

function ReportList({ reports, now }: { reports: VoiceReport[]; now: number }) {
  return (
    <ul className="space-y-3">
      {reports.map((r, i) => (
        <li key={i} className="text-sm">
          <div className="flex items-center justify-between gap-2">
            <span className="flex flex-wrap items-center gap-1">
              <Badge variant={r.state === "open" ? "destructive" : "outline"}>{label(reportReasonLabel, r.reason)}</Badge>
              {r.state !== "open" ? (
                <span className="text-xs text-muted-foreground">{label(reportStateLabel, r.state)}</span>
              ) : null}
            </span>
            <span className="text-xs text-muted-foreground">{timeAgo(r.createdAt, now)}</span>
          </div>
          {r.details ? <p className="mt-1 text-muted-foreground whitespace-pre-line">{r.details}</p> : null}
        </li>
      ))}
    </ul>
  );
}

function CommentRow({
  comment: c,
  issueId,
  reports,
  now,
}: {
  comment: VoiceComment;
  issueId: string;
  reports: VoiceReport[];
  now: number;
}) {
  const official = c.kind === "official";
  const openReports = reports.filter((r) => r.state === "open").length;
  const who = official
    ? [authorName(c.author), c.officialTitle].filter(Boolean).join(" · ") || "University official"
    : c.author
      ? (authorName(c.author) ?? "")
      : handleText(c.handle);
  return (
    <li id={`comment-${c.id}`} className="scroll-mt-20 rounded-xl border bg-card p-3 target:ring-2 target:ring-primary">
      <div className="flex flex-wrap items-center gap-1.5 text-sm">
        <span className="font-medium">{who}</span>
        {official ? <Badge variant="info">Official</Badge> : null}
        {c.isIssueAuthor ? <Badge variant="outline">Author</Badge> : null}
        {c.visibility !== "visible" ? (
          <Badge variant={visibilityTone[c.visibility] ?? "outline"}>{label(visibilityLabel, c.visibility)}</Badge>
        ) : null}
        <span className="ms-auto text-xs text-muted-foreground">{formatDateTime(c.createdAt)}</span>
      </div>
      <p className="mt-1.5 text-sm whitespace-pre-line">{c.body}</p>
      {c.removedReason ? <p className="mt-1 text-xs text-destructive">Removed: {c.removedReason}</p> : null}
      {reports.length > 0 ? (
        <details className="mt-2 rounded-md bg-muted/50 p-2">
          <summary className="cursor-pointer text-xs font-medium select-none">
            {openReports > 0 ? `${openReports} open report${openReports === 1 ? "" : "s"}` : "Reports"} (who reported is
            never shown)
          </summary>
          <div className="mt-2">
            <ReportList reports={reports} now={now} />
          </div>
        </details>
      ) : null}
      <div className="mt-3">
        <ModerationButtons
          target={{ type: "comment", id: c.id, issueId }}
          visibility={c.visibility}
          canBan={!official}
          openReports={openReports}
        />
      </div>
    </li>
  );
}

function Count({
  icon: Icon,
  label: text,
  value,
}: {
  icon: React.ComponentType<{ className?: string; "aria-hidden"?: boolean }>;
  label: string;
  value: number;
}) {
  return (
    <div>
      <Icon className="mx-auto size-4 text-muted-foreground" aria-hidden />
      <p className="mt-1 text-lg font-semibold tabular-nums">{formatNumber(value)}</p>
      <p className="text-xs text-muted-foreground">{text}</p>
    </div>
  );
}

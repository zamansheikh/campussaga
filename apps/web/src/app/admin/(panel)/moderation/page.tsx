import { ChevronLeft, ChevronRight, EyeOff, Lock, MessageSquare, ShieldAlert } from "lucide-react";
import Link from "next/link";

import { UniversityFilter } from "@/components/admin/moderation/university-filter";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { load } from "@/lib/admin/load";
import { api, getAdmin, query, requestNow } from "@/lib/admin/session";
import type { CursorPage, QueueItem, QueueKind, UniversityRef } from "@/lib/admin/types";
import {
  categoryLabel,
  holdReasonLabel,
  isQueueKind,
  label,
  queueTabs,
  reportReasonLabel,
  statusLabel,
  statusTone,
  visibilityLabel,
  visibilityTone,
} from "@/lib/admin/voice";
import { timeAgo } from "@/lib/format";
import { cn } from "@/lib/utils";

export const metadata = { title: "Moderation" };

type Search = { kind?: string; universityId?: string; cursor?: string };

export default async function ModerationPage({ searchParams }: { searchParams: Promise<Search> }) {
  const sp = await searchParams;
  const kind: QueueKind = isQueueKind(sp.kind) ? sp.kind : "held";
  await getAdmin();
  const [queue, unis] = await Promise.all([
    load(() =>
      api<CursorPage<QueueItem>>(
        `/moderation/queue${query({ kind, universityId: sp.universityId, cursor: sp.cursor })}`,
      ),
    ),
    // The public list: moderators can't read the admin one.
    load(() => api<{ universities: UniversityRef[] }>("/universities")),
  ]);
  const now = requestNow();
  const tab = queueTabs.find((t) => t.kind === kind)!;
  const href = (k: QueueKind) => `/admin/moderation${query({ kind: k === "held" ? undefined : k, universityId: sp.universityId })}`;

  return (
    <>
      <PageHeader
        title="Moderation"
        description="Campus Voice posts that need a look. Authors are anonymous: nobody, including you, can see who wrote them."
      />

      <div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <nav aria-label="Queue" className="inline-flex w-fit flex-wrap gap-1 rounded-lg bg-muted p-1">
          {queueTabs.map((t) => (
            <Link
              key={t.kind}
              href={href(t.kind)}
              aria-current={t.kind === kind ? "page" : undefined}
              className={cn(
                "rounded-md px-3 py-1.5 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground",
                "focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
                t.kind === kind && "bg-background text-foreground shadow-sm",
              )}
            >
              {t.kind === "private" ? <Lock className="me-1 inline size-3.5 align-[-2px]" aria-hidden /> : null}
              {t.label}
            </Link>
          ))}
        </nav>
        {unis.data ? <UniversityFilter universities={unis.data.universities} /> : null}
      </div>
      <p className="mb-4 text-sm text-muted-foreground">{tab.hint}</p>

      {queue.error ? (
        <ErrorPanel message={queue.error} />
      ) : queue.data && queue.data.items.length === 0 ? (
        <EmptyState title={sp.cursor ? "No more items" : "Nothing to review"}>
          {sp.cursor ? null : "New items show up here as students post and report."}
        </EmptyState>
      ) : queue.data ? (
        <>
          <ul className="space-y-3">
            {queue.data.items.map((item) => (
              <QueueRow key={`${item.targetType}:${item.comment?.id ?? item.issue.id}`} item={item} now={now} />
            ))}
          </ul>
          <div className="mt-4 flex items-center justify-end gap-2">
            {sp.cursor ? (
              <Button variant="outline" size="sm" asChild>
                <Link href={href(kind)}>
                  <ChevronLeft /> First page
                </Link>
              </Button>
            ) : null}
            {queue.data.nextCursor ? (
              <Button variant="outline" size="sm" asChild>
                <Link
                  href={`/admin/moderation${query({
                    kind: kind === "held" ? undefined : kind,
                    universityId: sp.universityId,
                    cursor: queue.data.nextCursor,
                  })}`}
                >
                  Next page <ChevronRight />
                </Link>
              </Button>
            ) : null}
          </div>
        </>
      ) : null}
    </>
  );
}

function QueueRow({ item, now }: { item: QueueItem; now: number }) {
  const { issue, comment } = item;
  const isComment = item.targetType === "comment" && comment;
  const visibility = isComment ? comment.visibility : issue.visibility;
  const reasons = Object.entries(item.reasons ?? {}).filter(([, n]) => n > 0);
  const text = isComment ? comment.body : issue.preview;
  return (
    <li className="relative rounded-xl border bg-card p-4 transition-colors hover:border-primary/40">
      <div className="flex flex-wrap items-center gap-1.5">
        <Badge variant="outline">
          {isComment ? <MessageSquare aria-hidden /> : null}
          {isComment ? "Comment" : "Issue"}
        </Badge>
        <Badge variant="soft">{label(categoryLabel, issue.category)}</Badge>
        {issue.private ? (
          <Badge variant="warning">
            <Lock aria-hidden /> Private
          </Badge>
        ) : null}
        <Badge variant={visibilityTone[visibility] ?? "outline"}>
          {visibility === "hidden" ? <EyeOff aria-hidden /> : null}
          {label(visibilityLabel, visibility)}
        </Badge>
        {!isComment ? <Badge variant={statusTone[issue.status] ?? "outline"}>{label(statusLabel, issue.status)}</Badge> : null}
        <span className="ms-auto text-xs text-muted-foreground">
          {item.university.name} · {timeAgo(item.createdAt, now)}
        </span>
      </div>

      <Link
        href={`/admin/moderation/issues/${issue.id}${isComment ? `#comment-${comment.id}` : ""}`}
        className="mt-2 block font-medium after:absolute after:inset-0 hover:underline focus-visible:outline-none"
      >
        {issue.title}
      </Link>
      {isComment ? <p className="text-xs text-muted-foreground">Comment on this issue:</p> : null}
      <p className="mt-1 line-clamp-2 text-sm text-muted-foreground whitespace-pre-line">{text}</p>

      {item.holdReason || reasons.length > 0 ? (
        <div className="mt-3 flex flex-wrap items-center gap-1.5">
          {item.holdReason ? (
            <Badge variant="warning" className="whitespace-normal">
              <ShieldAlert aria-hidden /> {label(holdReasonLabel, item.holdReason)}
            </Badge>
          ) : null}
          {reasons.map(([reason, n]) => (
            <Badge key={reason} variant="destructive">
              {label(reportReasonLabel, reason)} × {n}
            </Badge>
          ))}
        </div>
      ) : null}
    </li>
  );
}

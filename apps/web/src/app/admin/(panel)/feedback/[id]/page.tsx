import { ArrowLeft } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";

import { ErrorPanel } from "@/components/admin/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { feedbackKindLabel, feedbackKindTone, feedbackStatusLabel, feedbackStatusTone, universityName } from "@/lib/admin/feedback";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import type { FeedbackDetail } from "@/lib/admin/types";
import { formatDateTime } from "@/lib/format";
import { cn } from "@/lib/utils";

import { FeedbackImages, ReplyBox, StatusSelect } from "./feedback-controls";

export const metadata: Metadata = { title: "Feedback" };

export default async function FeedbackDetailPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  // Opening it marks it seen and clears the unread count.
  const res = await load(() => api<FeedbackDetail>(`/admin/feedback/${encodeURIComponent(id)}`));
  const f = res.data;

  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/feedback">
          <ArrowLeft /> Feedback
        </Link>
      </Button>
      {res.error || !f ? (
        <ErrorPanel message={res.error ?? "Not found."} />
      ) : (
        <div className="grid gap-4 lg:grid-cols-3">
          <div className="space-y-4 lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex flex-wrap items-center gap-2 text-base">
                  <Badge variant={feedbackKindTone[f.kind] ?? "outline"}>{feedbackKindLabel[f.kind] ?? f.kind}</Badge>
                  <Badge variant={feedbackStatusTone[f.status] ?? "outline"}>{feedbackStatusLabel[f.status] ?? f.status}</Badge>
                  <span className="text-sm font-normal text-muted-foreground">{formatDateTime(f.createdAt)}</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-sm whitespace-pre-wrap break-words">{f.message}</p>
                {f.images?.length ? <FeedbackImages images={f.images} /> : null}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-base">Conversation</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {(f.messages ?? []).length === 0 ? (
                  <p className="text-sm text-muted-foreground">No messages yet.</p>
                ) : (
                  <ul className="space-y-3">
                    {f.messages.map((m) => (
                      <li key={m.id} className={cn("flex", m.fromTeam && "justify-end")}>
                        <div className={cn("max-w-[85%] rounded-xl px-3 py-2 text-sm", m.fromTeam ? "bg-primary-soft text-primary-soft-foreground" : "bg-muted")}>
                          <p className="mb-0.5 text-xs text-muted-foreground">
                            {m.fromTeam ? m.author?.name || "VarsityKotha team" : f.user?.name || "Student"} · {formatDateTime(m.createdAt)}
                          </p>
                          <p className="whitespace-pre-wrap break-words">{m.body}</p>
                        </div>
                      </li>
                    ))}
                  </ul>
                )}
                <ReplyBox feedbackId={f.id} closed={f.status === "done" || f.status === "wont_do"} />
              </CardContent>
            </Card>
          </div>

          <div className="space-y-4">
            <Card className="h-fit">
              <CardContent className="pt-6">
                <StatusSelect feedbackId={f.id} status={f.status} />
              </CardContent>
            </Card>
            <Card className="h-fit">
              <CardHeader>
                <CardTitle className="text-base">Student and device</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="space-y-3 text-sm">
                  <Field label="Student">
                    {f.user ? (
                      <Link href={`/admin/users/${f.user.id}`} className="hover:underline">
                        {f.user.name || f.user.email}
                      </Link>
                    ) : (
                      "Deleted account"
                    )}
                    {f.user?.name ? <span className="block text-xs font-normal text-muted-foreground">{f.user.email}</span> : null}
                  </Field>
                  <Field label="University">{universityName(f.user?.university) ?? "—"}</Field>
                  <Field label="App">{f.appVersion ? `${f.appVersion}${f.build ? ` (build ${f.build})` : ""}` : "—"}</Field>
                  <Field label="Phone">{f.device || "—"}</Field>
                  <Field label="System">
                    {/* The app sends "Android 17": add the platform only when the OS text lacks it. */}
                    {f.os && f.platform && f.os.toLowerCase().includes(f.platform.toLowerCase()) ? (
                      f.os
                    ) : (
                      <>
                        <span className="capitalize">{f.platform ?? ""}</span> {f.os ?? ""}
                      </>
                    )}
                  </Field>
                </dl>
              </CardContent>
            </Card>
          </div>
        </div>
      )}
    </>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="mt-0.5 font-medium break-words">{children}</dd>
    </div>
  );
}

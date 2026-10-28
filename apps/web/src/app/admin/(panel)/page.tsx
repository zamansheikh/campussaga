import { Building2, Megaphone, Smartphone, UserCheck, UserRoundPlus, Users, UsersRound } from "lucide-react";
import Link from "next/link";

import { SignupsChart } from "@/components/admin/dashboard/signups-chart";
import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import type { Stats, VoiceStats } from "@/lib/admin/types";
import { formatNumber } from "@/lib/format";

export const metadata = { title: "Dashboard" };

export default async function DashboardPage() {
  await requireAdmin();
  const { data: s, error } = await load(() => api<Stats>("/admin/stats"));
  return (
    <>
      <PageHeader title="Dashboard" description="How VarsityKotha is doing right now." />
      {error || !s ? (
        <ErrorPanel message={error ?? "No data."} />
      ) : (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <Stat
              icon={Users}
              label="Students"
              value={s.users.total}
              href="/admin/users"
              hint={`${formatNumber(s.users.newLast7Days)} new in the last 7 days`}
            />
            <Stat
              icon={UserCheck}
              label="Verified"
              value={s.users.verified}
              href="/admin/users?status=verified"
              hint={`${formatNumber(s.users.notVerified)} not verified · ${percent(s.users.verified, s.users.total)} verified`}
            />
            <Stat
              icon={UsersRound}
              label="Class groups"
              value={s.groups.total}
              href="/admin/groups"
              hint={`${formatNumber(s.groups.memberships)} memberships · ${formatNumber(s.groups.slots)} weekly classes`}
            />
            <Stat
              icon={Smartphone}
              label="Phones with push"
              value={s.devices.android + s.devices.ios}
              href="/admin/push"
              hint={`${formatNumber(s.devices.android)} Android · ${formatNumber(s.devices.ios)} iPhone`}
            />
          </div>

          <div className="grid gap-4 lg:grid-cols-3">
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <UserRoundPlus className="size-4 text-muted-foreground" /> Sign-ups, last 30 days
                </CardTitle>
                <CardDescription>
                  {formatNumber(s.signupsByDay.reduce((a, d) => a + d.count, 0))} new accounts (Bangladesh time)
                </CardDescription>
              </CardHeader>
              <CardContent>
                <SignupsChart data={s.signupsByDay} />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <Building2 className="size-4 text-muted-foreground" /> Top universities
                </CardTitle>
                <CardDescription>
                  {formatNumber(s.universities.active)} active of {formatNumber(s.universities.total)}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {s.topUniversities.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No students yet.</p>
                ) : (
                  <ol className="space-y-3">
                    {s.topUniversities.map((u) => {
                      const max = s.topUniversities[0]?.users || 1;
                      return (
                        <li key={u.id}>
                          <Link
                            href={`/admin/users?universityId=${u.id}`}
                            className="group block rounded-md focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
                          >
                            <div className="flex items-baseline justify-between gap-2 text-sm">
                              <span className="truncate group-hover:underline">{u.name}</span>
                              <span className="shrink-0 tabular-nums text-muted-foreground">
                                {formatNumber(u.users)}
                              </span>
                            </div>
                            <div className="mt-1 h-1.5 rounded-full bg-muted">
                              <div
                                className="h-1.5 rounded-full bg-primary"
                                style={{ width: `${Math.max(4, (u.users / max) * 100)}%` }}
                              />
                            </div>
                          </Link>
                        </li>
                      );
                    })}
                  </ol>
                )}
              </CardContent>
            </Card>
          </div>

          {s.voice ? <VoiceCard v={s.voice} /> : null}

          <div className="grid gap-4 sm:grid-cols-3">
            <MiniStat label="Admins" value={s.users.admins} href="/admin/users?status=admin" />
            <MiniStat label="Blocked accounts" value={s.users.blocked} href="/admin/users?status=blocked" />
            <MiniStat label="Announcements" value={s.groups.announcements} />
          </div>
        </div>
      )}
    </>
  );
}

/** Campus Voice at a glance, with the moderation work waiting. */
function VoiceCard({ v }: { v: VoiceStats }) {
  const waiting = v.held + v.reported;
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <Megaphone className="size-4 text-muted-foreground" /> Campus Voice
        </CardTitle>
        <CardDescription>
          {formatNumber(v.issuesLast7Days)} new issues in the last 7 days ·{" "}
          {waiting === 0 ? "nothing waiting for moderation" : `${formatNumber(waiting)} waiting for moderation`}
        </CardDescription>
      </CardHeader>
      <CardContent className="grid gap-3 sm:grid-cols-4">
        <MiniStat label="Open" value={v.open} />
        <MiniStat label="Solved" value={v.solved} />
        <MiniStat label="Held for review" value={v.held} href="/admin/moderation" />
        <MiniStat label="Reported" value={v.reported} href="/admin/moderation?kind=reported" />
      </CardContent>
    </Card>
  );
}

function percent(a: number, b: number) {
  return b === 0 ? "0%" : `${Math.round((a / b) * 100)}%`;
}

function Stat({
  icon: Icon,
  label,
  value,
  hint,
  href,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: number;
  hint: string;
  href: string;
}) {
  return (
    <Link
      href={href}
      className="rounded-xl focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
    >
      <Card className="h-full transition-colors hover:border-primary/40">
        <CardContent className="pt-0">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-muted-foreground">{label}</p>
            <span className="inline-flex size-8 items-center justify-center rounded-lg bg-primary-soft text-primary-soft-foreground">
              <Icon className="size-4" />
            </span>
          </div>
          <p className="mt-2 text-3xl font-semibold tracking-tight tabular-nums">{formatNumber(value)}</p>
          <p className="mt-1 text-xs text-muted-foreground">{hint}</p>
        </CardContent>
      </Card>
    </Link>
  );
}

function MiniStat({ label, value, href }: { label: string; value: number; href?: string }) {
  const body = (
    <div className="flex items-center justify-between rounded-xl border bg-card px-4 py-3">
      <span className="text-sm text-muted-foreground">{label}</span>
      <span className="font-semibold tabular-nums">{formatNumber(value)}</span>
    </div>
  );
  return href ? (
    <Link href={href} className="rounded-xl hover:opacity-90 focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none">
      {body}
    </Link>
  ) : (
    body
  );
}

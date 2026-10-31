import { ArrowLeft, Smartphone } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";

import { ErrorPanel } from "@/components/admin/notice";
import { UserBadges } from "@/components/admin/user-badges";
import { UserAvatar } from "@/components/admin/user-avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { load } from "@/lib/admin/load";
import { api, getAdmin, requestNow, requireAdmin } from "@/lib/admin/session";
import { badgeLabel, tierLabel, type UserProfileLite } from "@/lib/admin/growth";
import type { AdminUserDetail, CampusAdmin } from "@/lib/admin/types";
import { allUniversities } from "@/lib/admin/universities";
import { formatDateTime, timeAgo } from "@/lib/format";

import { UserActions } from "./user-actions";

export const metadata: Metadata = { title: "User" };

export default async function UserPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  const [me, res, unis] = await Promise.all([
    getAdmin(),
    load(() => api<AdminUserDetail>(`/admin/users/${encodeURIComponent(id)}`)),
    load(() => allUniversities()),
  ]);
  const now = requestNow();
  // Whether they are a campus admin of their university (the list is small: 5 at most).
  const uni = res.data?.university;
  const admins = uni ? await load(() => api<CampusAdmin[] | { items: CampusAdmin[] }>(`/admin/campus-admins?universityId=${uni.id}`)) : undefined;
  const adminList = admins?.data ? (Array.isArray(admins.data) ? admins.data : admins.data.items ?? []) : [];
  const isCampusAdmin = adminList.some((a) => a.user.id === id);
  // Badges and invites come from the student profile; if that can't be read (older API, blocked user) the card is simply left out.
  const profile = res.data ? await load(() => api<UserProfileLite>(`/users/${encodeURIComponent(id)}/profile`)) : undefined;

  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/users">
          <ArrowLeft /> Users
        </Link>
      </Button>
      {res.error || !res.data ? (
        <ErrorPanel message={res.error ?? "Not found."} />
      ) : (
        <UserView
          user={res.data}
          now={now}
          isSelf={me.id === res.data.id}
          isCampusAdmin={isCampusAdmin}
          profile={profile?.data}
          universities={(unis.data ?? []).map((u) => ({ id: u.id, slug: u.slug, name: u.name }))}
        />
      )}
    </>
  );
}

function UserView({
  user,
  now,
  isSelf,
  isCampusAdmin,
  profile,
  universities,
}: {
  user: AdminUserDetail;
  now: number;
  isSelf: boolean;
  isCampusAdmin: boolean;
  profile?: UserProfileLite;
  universities: { id: string; slug: string; name: string }[];
}) {
  const name = user.displayName || "No name yet";
  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
        <UserAvatar user={user} className="size-14" textClassName="text-lg" />
        <div className="min-w-0">
          <h1 className="text-2xl font-semibold tracking-tight">
            {name}
            {isSelf ? <span className="ms-2 text-base font-normal text-muted-foreground">(you)</span> : null}
          </h1>
          <p className="truncate text-muted-foreground">{user.email}</p>
          <div className="mt-2">
            <UserBadges user={user} />
          </div>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="space-y-4 lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Profile</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="grid gap-x-6 gap-y-3 text-sm sm:grid-cols-2">
                <Field label="University">{user.university?.name ?? "Not chosen"}</Field>
                <Field label="University email">{user.universityEmail ?? "—"}</Field>
                <Field label="Department">{user.department ?? "—"}</Field>
                <Field label="Batch">{user.batch ?? "—"}</Field>
                <Field label="Verified">{user.verifiedAt ? formatDateTime(user.verifiedAt) : "No"}</Field>
                <Field label="Role">{user.role}</Field>
                <Field label="Joined">{formatDateTime(user.createdAt)}</Field>
                <Field label="Last active">{timeAgo(user.lastActiveAt, now)}</Field>
                <Field label="Signed in on">
                  {user.activeSessions} {user.activeSessions === 1 ? "device" : "devices"}
                </Field>
                {user.blockedAt ? <Field label="Blocked">{formatDateTime(user.blockedAt)}</Field> : null}
              </dl>
            </CardContent>
          </Card>

          {profile ? (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Badges and invites</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3 text-sm">
                <p>
                  <span className="font-medium">{profile.invitesJoined ?? 0}</span>{" "}
                  <span className="text-muted-foreground">friends joined with their invite (qualified)</span>
                </p>
                {(profile.badges ?? []).length === 0 ? (
                  <p className="text-muted-foreground">No public badges.</p>
                ) : (
                  <div className="flex flex-wrap gap-1.5">
                    {(profile.badges ?? []).map((b) => (
                      <Badge key={b.key} variant={profile.featuredBadge?.key === b.key ? "soft" : "outline"}>
                        {badgeLabel[b.key] ?? b.key}
                        {b.tier > 0 ? ` · ${tierLabel[b.tier] ?? b.tier}` : ""}
                        {profile.featuredBadge?.key === b.key ? " · featured" : ""}
                      </Badge>
                    ))}
                  </div>
                )}
                <p className="text-xs text-muted-foreground">Public badges only; private ones are seen by the student alone.</p>
              </CardContent>
            </Card>
          ) : null}

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Class groups ({user.memberships.length})</CardTitle>
            </CardHeader>
            <CardContent>
              {user.memberships.length === 0 ? (
                <p className="text-sm text-muted-foreground">Not in any class group.</p>
              ) : (
                <ul className="divide-y">
                  {user.memberships.map((m) => (
                    <li key={m.groupId} className="flex items-center justify-between gap-3 py-2.5">
                      <Link href={`/admin/groups/${m.groupId}`} className="truncate text-sm font-medium hover:underline">
                        {m.title}
                      </Link>
                      {m.role === "cr" ? <Badge variant="soft">CR</Badge> : <Badge variant="outline">Member</Badge>}
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Phones with push ({user.devices.length})</CardTitle>
            </CardHeader>
            <CardContent>
              {user.devices.length === 0 ? (
                <p className="text-sm text-muted-foreground">No phone registered for notifications.</p>
              ) : (
                <ul className="space-y-2">
                  {user.devices.map((d, i) => (
                    <li key={i} className="flex items-center gap-2 text-sm">
                      <Smartphone className="size-4 text-muted-foreground" aria-hidden />
                      <span className="capitalize">{d.platform === "ios" ? "iPhone" : d.platform}</span>
                      <span className="text-muted-foreground">· since {formatDateTime(d.createdAt)}</span>
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </Card>
        </div>

        <Card className="h-fit">
          <CardHeader>
            <CardTitle className="text-base">Actions</CardTitle>
          </CardHeader>
          <CardContent>
            <UserActions user={user} isSelf={isSelf} isCampusAdmin={isCampusAdmin} universities={universities} />
          </CardContent>
        </Card>
      </div>
    </div>
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

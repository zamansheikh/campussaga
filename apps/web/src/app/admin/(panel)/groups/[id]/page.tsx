import { ArrowLeft } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";

import { ErrorPanel } from "@/components/admin/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import type { AdminGroupDetail } from "@/lib/admin/types";
import { formatDate, formatDateTime, formatNumber } from "@/lib/format";

import { DeleteGroup, MemberActions } from "./member-actions";

export const metadata: Metadata = { title: "Class group" };

export default async function GroupPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  const res = await load(() => api<AdminGroupDetail>(`/admin/groups/${encodeURIComponent(id)}`));
  const g = res.data;
  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/groups">
          <ArrowLeft /> Class groups
        </Link>
      </Button>
      {res.error || !g ? (
        <ErrorPanel message={res.error ?? "Not found."} />
      ) : (
        <div className="space-y-6">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h1 className="text-2xl font-semibold tracking-tight">{g.title}</h1>
              <p className="text-muted-foreground">{g.university.name}</p>
            </div>
            <DeleteGroup groupId={g.id} title={g.title} joinCode={g.joinCode} />
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <Info label="Join code">
              <span className="font-mono text-lg tracking-widest">{g.joinCode}</span>
            </Info>
            <Info label="Semester">{g.semester}</Info>
            <Info label="Members">
              {formatNumber(g.members)} · {g.crs.length} CR
            </Info>
            <Info label="Weekly classes">{formatNumber(g.slots)}</Info>
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Members</CardTitle>
              <p className="text-sm text-muted-foreground">
                {g.department} · batch {g.batch}
                {g.section ? ` · section ${g.section}` : ""} · created {formatDate(g.createdAt)}
              </p>
            </CardHeader>
            <CardContent className="px-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="ps-6">Student</TableHead>
                    <TableHead>Role</TableHead>
                    <TableHead className="hidden md:table-cell">Joined</TableHead>
                    <TableHead className="w-12 pe-6">
                      <span className="sr-only">Actions</span>
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {g.memberList.map((m) => (
                    <TableRow key={m.userId}>
                      <TableCell className="max-w-64 ps-6">
                        <Link href={`/admin/users/${m.userId}`} className="font-medium hover:underline">
                          {m.name || "No name yet"}
                        </Link>
                        <p className="truncate text-xs text-muted-foreground">{m.email}</p>
                      </TableCell>
                      <TableCell>
                        <span className="flex flex-wrap gap-1">
                          {m.role === "cr" ? <Badge variant="soft">CR</Badge> : <Badge variant="outline">Member</Badge>}
                          {m.verified ? null : <Badge variant="warning">Not verified</Badge>}
                        </span>
                      </TableCell>
                      <TableCell className="hidden text-muted-foreground md:table-cell">
                        {formatDateTime(m.joinedAt)}
                      </TableCell>
                      <TableCell className="pe-6">
                        <MemberActions groupId={g.id} member={m} />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </div>
      )}
    </>
  );
}

function Info({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl border bg-card px-4 py-3">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="mt-1 font-medium">{children}</p>
    </div>
  );
}

import Link from "next/link";

import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import type { StaffItem } from "@/lib/admin/types";
import { allUniversities } from "@/lib/admin/universities";
import { formatDate } from "@/lib/format";

import { AddStaffDialog } from "./add-staff-dialog";
import { RemoveStaffButton } from "./remove-staff-button";

export const metadata = { title: "Staff" };

export default async function StaffPage() {
  await requireAdmin();
  const [staff, unis] = await Promise.all([
    load(() => api<{ items: StaffItem[] }>("/admin/staff")),
    load(() => allUniversities()),
  ]);
  const universities = (unis.data ?? []).map((u) => ({ id: u.id, slug: u.slug, name: u.name }));
  return (
    <>
      <PageHeader
        title="Staff"
        description="University officials answer Campus Voice issues in the app; moderators review posts here. Neither can see who wrote anything."
        actions={<AddStaffDialog universities={universities} />}
      />
      {staff.error ? (
        <ErrorPanel message={staff.error} />
      ) : staff.data && staff.data.items.length === 0 ? (
        <EmptyState title="No staff yet">
          Add moderators and at least one university official before turning Campus Voice on.
        </EmptyState>
      ) : staff.data ? (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Person</TableHead>
                <TableHead>Role</TableHead>
                <TableHead className="hidden md:table-cell">University</TableHead>
                <TableHead className="hidden lg:table-cell">Public title</TableHead>
                <TableHead className="hidden lg:table-cell">Since</TableHead>
                <TableHead className="w-0">
                  <span className="sr-only">Actions</span>
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {staff.data.items.map((s) => {
                const name = s.user.displayName || s.user.email;
                return (
                  <TableRow key={s.user.id}>
                    <TableCell className="max-w-64">
                      <Link href={`/admin/users/${s.user.id}`} className="font-medium hover:underline">
                        {s.user.displayName || "No name yet"}
                      </Link>
                      <p className="truncate text-xs text-muted-foreground">{s.user.email}</p>
                    </TableCell>
                    <TableCell>
                      <Badge variant={s.kind === "authority" ? "info" : "soft"}>
                        {s.kind === "authority" ? "Official" : "Moderator"}
                      </Badge>
                      <p className="mt-1 truncate text-xs text-muted-foreground md:hidden">
                        {s.university?.name ?? (s.kind === "moderator" ? "All universities" : "")}
                      </p>
                    </TableCell>
                    <TableCell className="hidden max-w-56 truncate md:table-cell">
                      {s.university?.name ?? <span className="text-muted-foreground">All universities</span>}
                    </TableCell>
                    <TableCell className="hidden lg:table-cell">
                      {s.title || <span className="text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell className="hidden text-muted-foreground lg:table-cell">{formatDate(s.createdAt)}</TableCell>
                    <TableCell className="text-end">
                      <RemoveStaffButton userId={s.user.id} name={name} kind={s.kind} />
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      ) : null}
    </>
  );
}

import Link from "next/link";

import { ListFilters } from "@/components/admin/list-filters";
import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Pagination, pageParam } from "@/components/admin/pagination";
import { UserBadges } from "@/components/admin/user-badges";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, query, requestNow, requireAdmin } from "@/lib/admin/session";
import type { AdminUser, Paged } from "@/lib/admin/types";
import { allUniversities } from "@/lib/admin/universities";
import { formatDate, formatNumber, timeAgo } from "@/lib/format";

export const metadata = { title: "Users" };

const PAGE_SIZE = 25;
const statuses = [
  { value: "verified", label: "Verified" },
  { value: "notVerified", label: "Not verified" },
  { value: "blocked", label: "Blocked" },
  { value: "admin", label: "Admins" },
];

type Search = { q?: string; status?: string; universityId?: string; page?: string };

export default async function UsersPage({ searchParams }: { searchParams: Promise<Search> }) {
  await requireAdmin();
  const sp = await searchParams;
  const page = pageParam(sp.page);
  const [users, unis] = await Promise.all([
    load(() =>
      api<Paged<AdminUser>>(
        `/admin/users${query({ q: sp.q, status: sp.status, universityId: sp.universityId, page, pageSize: PAGE_SIZE })}`,
      ),
    ),
    load(() => allUniversities()),
  ]);
  const now = requestNow();
  return (
    <>
      <PageHeader
        title="Users"
        description={users.data ? `${formatNumber(users.data.total)} accounts match` : "Every VarsityKotha account."}
      />
      <ListFilters
        searchPlaceholder="Email or name"
        selects={[{ name: "status", label: "Statuses", options: statuses }]}
        universities={unis.data?.map((u) => ({ id: u.id, slug: u.slug, name: u.name }))}
      />
      {users.error ? (
        <ErrorPanel message={users.error} />
      ) : users.data && users.data.items.length === 0 ? (
        <EmptyState title="No users found">Try a different search or filter.</EmptyState>
      ) : users.data ? (
        <>
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead className="hidden md:table-cell">University</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="hidden text-end lg:table-cell">Groups</TableHead>
                  <TableHead className="hidden lg:table-cell">Joined</TableHead>
                  <TableHead className="hidden xl:table-cell">Last active</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.data.items.map((u) => (
                  <TableRow key={u.id} className="relative">
                    <TableCell className="max-w-64">
                      <Link
                        href={`/admin/users/${u.id}`}
                        className="font-medium after:absolute after:inset-0 hover:underline focus-visible:outline-none"
                      >
                        {u.displayName || "No name yet"}
                      </Link>
                      <p className="truncate text-xs text-muted-foreground">{u.email}</p>
                    </TableCell>
                    <TableCell className="hidden max-w-56 truncate md:table-cell">
                      {u.university?.name ?? <span className="text-muted-foreground">Not chosen</span>}
                    </TableCell>
                    <TableCell>
                      <UserBadges user={u} />
                    </TableCell>
                    <TableCell className="hidden text-end tabular-nums lg:table-cell">{u.groups}</TableCell>
                    <TableCell className="hidden text-muted-foreground lg:table-cell">{formatDate(u.createdAt)}</TableCell>
                    <TableCell className="hidden text-muted-foreground xl:table-cell">
                      {timeAgo(u.lastActiveAt, now)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <Pagination
            basePath="/admin/users"
            params={{ q: sp.q, status: sp.status, universityId: sp.universityId }}
            page={page}
            pageSize={users.data.pageSize || PAGE_SIZE}
            total={users.data.total}
          />
        </>
      ) : null}
    </>
  );
}

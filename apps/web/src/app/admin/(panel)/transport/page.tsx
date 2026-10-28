import Link from "next/link";

import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { load } from "@/lib/admin/load";
import { api, query, requireAdmin } from "@/lib/admin/session";
import { type BusRoute, type TransportRep, clock12 } from "@/lib/admin/transport";
import { allUniversities } from "@/lib/admin/universities";
import { formatDate, formatDateTime } from "@/lib/format";

import { AddRepDialog, RemoveRepButton } from "./rep-buttons";
import { RouteDialog } from "./route-dialog";
import { UniversitySelect } from "./university-select";

export const metadata = { title: "Bus routes" };

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function TransportPage({ searchParams }: { searchParams: Promise<{ universityId?: string }> }) {
  await requireAdmin();
  const sp = await searchParams;
  const universityId = sp.universityId && uuid.test(sp.universityId) ? sp.universityId : null;
  const [unis, routes, reps] = await Promise.all([
    load(() => allUniversities()),
    // No university chosen: every university's routes.
    load(() => api<{ routes: BusRoute[] }>(`/admin/transport/routes${query({ universityId })}`)),
    load(() => api<{ items: TransportRep[] }>(`/admin/transport/reps${query({ universityId })}`)),
  ]);
  const universities = (unis.data ?? []).map((u) => ({ id: u.id, slug: u.slug, name: u.name }));
  const university = universities.find((u) => u.id === universityId);
  const uniName = new Map(universities.map((u) => [u.id, u.name]));
  const all = !universityId;
  const list = [...(routes.data?.routes ?? [])].sort(
    (a, b) =>
      (uniName.get(a.universityId) ?? "").localeCompare(uniName.get(b.universityId) ?? "") ||
      a.name.localeCompare(b.name),
  );

  return (
    <>
      <PageHeader
        title="Bus routes"
        description="Each university's buses: stops, times and the students (transport reps) who keep them up to date in the app."
        actions={<RouteDialog universityId={universityId ?? undefined} />}
      />
      <div className="mb-4">
        <UniversitySelect universities={universities} />
      </div>

      {unis.error ? <ErrorPanel message={unis.error} /> : null}

      {routes.error ? (
        <ErrorPanel message={routes.error} />
      ) : routes.data && list.length === 0 ? (
        <EmptyState title="No bus routes yet">
          {all
            ? "Choose a university to add its first route, or name a transport rep to do it from the app."
            : `Add the first route for ${university?.name ?? "this university"}, or name a transport rep to do it from the app.`}
        </EmptyState>
      ) : routes.data ? (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Route</TableHead>
                {all ? <TableHead className="hidden md:table-cell">University</TableHead> : null}
                <TableHead className="hidden sm:table-cell">Stops</TableHead>
                <TableHead>Departures</TableHead>
                <TableHead className="hidden md:table-cell">First bus</TableHead>
                <TableHead className="hidden lg:table-cell">Updated</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {list.map((r) => {
                const first = r.trips
                  .filter((t) => t.direction === "to_campus")
                  .map((t) => t.departs)
                  .sort()[0];
                return (
                  <TableRow key={r.id}>
                    <TableCell className="max-w-72">
                      <div className="flex items-center gap-2">
                        <span className="size-3 shrink-0 rounded-full" style={{ backgroundColor: r.color }} aria-hidden />
                        <Link href={`/admin/transport/${r.id}`} className="truncate font-medium hover:underline">
                          {r.name}
                        </Link>
                        {r.active ? null : <Badge variant="outline">Hidden</Badge>}
                      </div>
                      {r.stops.length > 1 ? (
                        <p className="truncate ps-5 text-xs text-muted-foreground">
                          {r.stops[0]?.name} → {r.stops.at(-1)?.name}
                        </p>
                      ) : null}
                    </TableCell>
                    {all ? (
                      <TableCell className="hidden max-w-56 truncate md:table-cell">
                        <Link href={`/admin/transport?universityId=${r.universityId}`} className="hover:underline">
                          {uniName.get(r.universityId) ?? "—"}
                        </Link>
                      </TableCell>
                    ) : null}
                    <TableCell className="hidden sm:table-cell">{r.stops.length}</TableCell>
                    <TableCell>{r.trips.length}</TableCell>
                    <TableCell className="hidden md:table-cell">
                      {first ? clock12(first) : <span className="text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell className="hidden text-muted-foreground lg:table-cell">
                      {formatDateTime(r.updatedAt)}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>
      ) : null}

      <section className="mt-10" aria-labelledby="reps-title">
        <div className="mb-3 flex flex-wrap items-end justify-between gap-2">
          <div>
            <h2 id="reps-title" className="text-lg font-semibold">
              Transport reps
            </h2>
            <p className="text-sm text-muted-foreground">
              Students who edit {university ? `${university.name}'s` : "their university's"} bus routes in the app.
            </p>
          </div>
          <AddRepDialog universities={universities} universityId={universityId} />
        </div>
        {reps.error ? (
          <ErrorPanel message={reps.error} />
        ) : reps.data && reps.data.items.length === 0 ? (
          <EmptyState title="No transport reps yet">
            Name a student who knows the buses; they can keep times up to date from the app.
          </EmptyState>
        ) : reps.data ? (
          <div className="overflow-hidden rounded-xl border bg-card">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Person</TableHead>
                  <TableHead className="hidden md:table-cell">University</TableHead>
                  <TableHead className="hidden lg:table-cell">Since</TableHead>
                  <TableHead className="w-0">
                    <span className="sr-only">Actions</span>
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {reps.data.items.map((p) => (
                  <TableRow key={p.userId}>
                    <TableCell className="max-w-64">
                      <Link href={`/admin/users/${p.userId}`} className="font-medium hover:underline">
                        {p.name || "No name yet"}
                      </Link>
                      <p className="truncate text-xs text-muted-foreground">{p.email}</p>
                      <p className="truncate text-xs text-muted-foreground md:hidden">{p.university}</p>
                    </TableCell>
                    <TableCell className="hidden max-w-56 truncate md:table-cell">{p.university}</TableCell>
                    <TableCell className="hidden text-muted-foreground lg:table-cell">{formatDate(p.createdAt)}</TableCell>
                    <TableCell className="text-end">
                      <RemoveRepButton userId={p.userId} name={p.name || p.email} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        ) : null}
      </section>
    </>
  );
}

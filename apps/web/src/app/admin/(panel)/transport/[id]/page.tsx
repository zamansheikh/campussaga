import { ArrowLeft } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";

import { ErrorPanel } from "@/components/admin/notice";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import type { BusRoute } from "@/lib/admin/transport";
import { allUniversities } from "@/lib/admin/universities";
import { formatDateTime } from "@/lib/format";

import { DeleteRouteButton } from "../rep-buttons";
import { RouteDialog } from "../route-dialog";
import { StopsEditor } from "./stops-editor";
import { TripsEditor } from "./trips-editor";

export const metadata: Metadata = { title: "Bus route" };

export default async function BusRoutePage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  const [res, unis] = await Promise.all([
    load(() => api<BusRoute>(`/transport/routes/${encodeURIComponent(id)}`)),
    load(() => allUniversities()),
  ]);
  const r = res.data;
  const university = unis.data?.find((u) => u.id === r?.universityId);
  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href={r ? `/admin/transport?universityId=${r.universityId}` : "/admin/transport"}>
          <ArrowLeft /> Bus routes
        </Link>
      </Button>
      {res.error || !r ? (
        <ErrorPanel message={res.error ?? "Not found."} />
      ) : (
        <div className="space-y-6">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span className="size-4 shrink-0 rounded-full" style={{ backgroundColor: r.color }} aria-hidden />
                <h1 className="truncate text-2xl font-semibold tracking-tight">{r.name}</h1>
                {r.active ? null : <Badge variant="outline">Hidden from students</Badge>}
              </div>
              <p className="text-muted-foreground">
                {university?.name ?? "University"} · updated {formatDateTime(r.updatedAt)}
              </p>
              {r.notes ? <p className="mt-2 max-w-prose text-sm whitespace-pre-line">{r.notes}</p> : null}
            </div>
            <div className="flex shrink-0 gap-2">
              {/* Keyed so the dialog's form starts from the saved route after each save. */}
              <RouteDialog key={r.updatedAt} route={r} />
              <DeleteRouteButton routeId={r.id} name={r.name} universityId={r.universityId} />
            </div>
          </div>

          <StopsEditor routeId={r.id} stops={r.stops} />
          <TripsEditor routeId={r.id} trips={r.trips} />
        </div>
      )}
    </>
  );
}

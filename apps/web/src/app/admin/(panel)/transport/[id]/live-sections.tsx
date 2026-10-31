import { Bus } from "lucide-react";

import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { type BusRoute, type BusRun, clock12, type RouteActivity } from "@/lib/admin/transport";
import { formatNumber } from "@/lib/format";

import { EndSharingButton } from "./end-sharing-button";

const directionLabel = { to_campus: "To campus", from_campus: "From campus" } as const;
const dir = (d: string) => directionLabel[d as keyof typeof directionLabel] ?? d;

function ago(iso: string, now: number): string {
  const s = Math.max(0, Math.round((now - new Date(iso).getTime()) / 1000));
  return s < 90 ? `${s} s ago` : `${Math.round(s / 60)} min ago`;
}

function delay(min: number | null): React.ReactNode {
  if (min == null) return <span className="text-muted-foreground">Unknown</span>;
  if (min <= 0) return min === 0 ? "On time" : `${-min} min early`;
  return <span className="text-warning">{min} min late</span>;
}

/** Live now and what riders say, for one route. `activity` may be an error from an older API. */
export function RouteActivitySections({
  route,
  activity,
  error,
  now,
}: {
  route: BusRoute;
  activity?: RouteActivity;
  error?: string;
  now: number;
}) {
  if (error || !activity) {
    return (
      <section aria-label="Live buses">
        <ErrorPanel message={error ?? "No data."} />
      </section>
    );
  }
  const runs = activity.live?.runs ?? [];
  const trips = activity.insights?.trips ?? [];
  const stopName = (id: string | null) => (id ? route.stops.find((s) => s.id === id)?.name : undefined);
  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-start justify-between gap-4">
          <div>
            <CardTitle className="flex items-center gap-2 text-base">
              <Bus className="size-4 text-muted-foreground" /> Live now
            </CardTitle>
            <CardDescription>
              {runs.length === 0 ? "No bus is being shared" : `${formatNumber(runs.length)} on the road`} ·{" "}
              {formatNumber(activity.sharesLast7Days ?? 0)} shares in the last 7 days
            </CardDescription>
          </div>
          {runs.length > 0 ? <EndSharingButton routeId={route.id} name={route.name} /> : null}
        </CardHeader>
        <CardContent>
          {runs.length === 0 ? (
            <EmptyState title="Nothing live">When students share the bus they are on, it shows up here.</EmptyState>
          ) : (
            <div className="overflow-hidden rounded-xl border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Run</TableHead>
                    <TableHead className="text-end">Riders</TableHead>
                    <TableHead>Next stop</TableHead>
                    <TableHead>How late</TableHead>
                    <TableHead>Updated</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {runs.map((r: BusRun, i) => (
                    <TableRow key={`${r.direction}-${r.departs ?? "x"}-${i}`}>
                      <TableCell>
                        <span className="font-medium">{dir(r.direction)}</span>
                        <span className="text-muted-foreground">
                          {" · "}
                          {r.departs ? clock12(r.departs) : "Not on the timetable"}
                        </span>
                      </TableCell>
                      <TableCell className="text-end tabular-nums">{r.riders}</TableCell>
                      <TableCell>
                        {stopName(r.nextStopId) ?? <span className="text-muted-foreground">{r.nextStopId ? "Unknown stop" : "None"}</span>}
                      </TableCell>
                      <TableCell>{delay(r.delayMin)}</TableCell>
                      <TableCell className="text-muted-foreground tabular-nums">{ago(r.updatedAt, now)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">What riders say</CardTitle>
          <CardDescription>
            Ratings from the last 180 days · {formatNumber(activity.ratingsLast30Days ?? 0)} in the last 30 days
          </CardDescription>
        </CardHeader>
        <CardContent>
          {trips.length === 0 ? (
            <EmptyState title="No ratings yet">After a trip, riders say in one tap how it went.</EmptyState>
          ) : (
            <div className="overflow-hidden rounded-xl border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Trip</TableHead>
                    <TableHead className="text-end">Votes</TableHead>
                    <TableHead className="text-end">On time</TableHead>
                    <TableHead className="text-end">Late</TableHead>
                    <TableHead className="text-end">Didn&apos;t come</TableHead>
                    <TableHead className="text-end">Crowded</TableHead>
                    <TableHead>Measured delay</TableHead>
                    <TableHead className="text-end">Measured runs</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {trips.map((t) => (
                    <TableRow key={`${t.direction}-${t.departs}`}>
                      <TableCell>
                        <Badge variant="outline" className="me-2">
                          {dir(t.direction)}
                        </Badge>
                        {clock12(t.departs)}
                      </TableCell>
                      <TableCell className="text-end tabular-nums">{t.votes}</TableCell>
                      <TableCell className="text-end tabular-nums">{t.onTime}</TableCell>
                      <TableCell className="text-end tabular-nums">{t.late}</TableCell>
                      <TableCell className="text-end tabular-nums">{t.noShow}</TableCell>
                      <TableCell className="text-end tabular-nums">{t.crowded}</TableCell>
                      <TableCell>{delay(t.delayMin)}</TableCell>
                      <TableCell className="text-end tabular-nums">{t.runs}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </>
  );
}

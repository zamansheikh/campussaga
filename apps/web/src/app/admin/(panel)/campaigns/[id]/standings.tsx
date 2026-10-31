"use client";

import { ChevronDown, ChevronRight, EyeOff } from "lucide-react";
import Link from "next/link";
import { Fragment, useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { flagHelp, flagLabel, pointKeys, pointLabel, raceProgress, raceRule, type Standing, uniName } from "@/lib/admin/growth";
import { formatDateTime } from "@/lib/format";

import { InviteActions, ParticipantActions } from "../invite-actions";

/** The top of the standings; a row opens to the participant's invites. */
export function StandingsTable({
  campaignId,
  rows,
  minOwnCampus,
  minOtherCampus,
}: {
  campaignId: string;
  rows: Standing[];
  minOwnCampus: number;
  minOtherCampus: number;
}) {
  const [open, setOpen] = useState<string | null>(null);
  return (
    <div className="overflow-hidden rounded-xl border bg-card">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-12">#</TableHead>
            <TableHead>Student</TableHead>
            <TableHead className="text-end">Points</TableHead>
            <TableHead>Flags</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((r, i) => {
            const isOpen = open === r.user.id;
            // The not-eligible come after the ranked ones; a divider marks where they start.
            const firstNotEligible = r.eligible === false && rows[i - 1]?.eligible !== false;
            return (
              <Fragment key={r.user.id}>
                {firstNotEligible ? (
                  <TableRow className="bg-muted/40 hover:bg-muted/40">
                    <TableCell colSpan={4} className="py-2 text-xs font-medium whitespace-normal text-muted-foreground">
                      Not eligible yet: they need counted friends: {raceRule(minOwnCampus, minOtherCampus) || "per the campaign's minimums"}. Not
                      ranked, so they can&apos;t win.
                    </TableCell>
                  </TableRow>
                ) : null}
                <StandingRow
                  campaignId={campaignId}
                  r={r}
                  race={raceProgress(r, minOwnCampus, minOtherCampus)}
                  isOpen={isOpen}
                  toggle={() => setOpen(isOpen ? null : r.user.id)}
                />
              </Fragment>
            );
          })}
        </TableBody>
      </Table>
    </div>
  );
}

function StandingRow({ campaignId, r, race, isOpen, toggle }: { campaignId: string; r: Standing; race: string; isOpen: boolean; toggle: () => void }) {
  const Chevron = isOpen ? ChevronDown : ChevronRight;
  return (
    <>
      <TableRow className={r.disqualified ? "opacity-60" : undefined}>
        <TableCell className="font-semibold tabular-nums">{r.rank ?? <span className="text-muted-foreground">—</span>}</TableCell>
        <TableCell className="max-w-72 whitespace-normal">
          <button
            type="button"
            onClick={toggle}
            aria-expanded={isOpen}
            className="flex items-center gap-1.5 rounded-sm text-start font-medium hover:underline focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
          >
            <Chevron className="size-4 shrink-0 text-muted-foreground" aria-hidden />
            {r.user.name || r.user.email || "No name"}
          </button>
          <p className="ps-5.5 text-xs break-all text-muted-foreground">
            {[r.user.email, uniName(r.user.university)].filter(Boolean).join(" · ")}
          </p>
        </TableCell>
        <TableCell className="text-end whitespace-normal">
          <p className="font-semibold tabular-nums">{r.score}</p>
          <PointsBreakdown points={r.points} />
        </TableCell>
        <TableCell className="whitespace-normal">
          <div className="flex flex-wrap gap-1">
            {r.hidden ? (
              <Badge variant="outline">
                <EyeOff /> Hidden
              </Badge>
            ) : null}
            {r.disqualified ? <Badge variant="destructive">Disqualified</Badge> : null}
            {r.eligible === false ? (
              <Badge variant="secondary">Not eligible{race ? `: ${race}` : ""}</Badge>
            ) : null}
            {(r.flags ?? []).map((f) => (
              <Flag key={f} flag={f} />
            ))}
          </div>
        </TableCell>
      </TableRow>
      {isOpen ? (
        <TableRow className="bg-muted/30 hover:bg-muted/30">
          <TableCell />
          <TableCell colSpan={3} className="whitespace-normal">
            <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
              <Link href={`/admin/users/${r.user.id}`} className="text-sm font-medium text-primary hover:underline">
                Open user page
              </Link>
              <ParticipantActions campaignId={campaignId} userId={r.user.id} name={r.user.name || r.user.email || "This person"} disqualified={Boolean(r.disqualified)} />
            </div>
            {r.invites.length === 0 ? (
              <p className="text-sm text-muted-foreground">No invites.</p>
            ) : (
              <ul className="divide-y rounded-lg border bg-card">
                {r.invites.map((i) => (
                  <li key={i.referred.id} className="flex flex-wrap items-start justify-between gap-3 p-3 text-sm">
                    <div className="min-w-0 space-y-1">
                      <p className="font-medium">
                        {i.referred.name || "No name"}
                        <span className="ms-2 font-normal text-muted-foreground">{uniName(i.referred.university)}</span>
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {i.source === "join" ? "Via class invite" : "Via personal link"} · joined {formatDateTime(i.createdAt)} · verified via{" "}
                        {i.verifiedVia || "not yet"} · {i.activeDays} of 3 active days
                      </p>
                      <div className="flex flex-wrap gap-1">
                        {i.qualifiedAt ? <Badge variant="success">Qualified {formatDateTime(i.qualifiedAt)}</Badge> : <Badge variant="secondary">Not qualified</Badge>}
                        {i.sameDevice ? <Badge variant="warning">Same phone</Badge> : null}
                        {i.disqualified ? <Badge variant="destructive">Disqualified</Badge> : null}
                        {i.otherCampus ? <Badge variant="info">Other university</Badge> : null}
                        {i.pioneer ? <Badge variant="info">Pioneer</Badge> : null}
                        {i.inSection ? <Badge variant="soft">In a section</Badge> : null}
                      </div>
                    </div>
                    <InviteActions referredId={i.referred.id} referredName={i.referred.name || "this student"} disqualified={i.disqualified} />
                  </li>
                ))}
              </ul>
            )}
          </TableCell>
        </TableRow>
      ) : null}
    </>
  );
}

/** "Invites 30 · Other university 5 · Live bus 4": only the keys that earned points (nothing on an older API). */
function PointsBreakdown({ points }: { points: Standing["points"] }) {
  const parts = pointKeys.filter((k) => (points?.[k] ?? 0) > 0);
  if (parts.length === 0) return null;
  return (
    <p className="mt-0.5 ms-auto max-w-56 text-xs leading-snug text-muted-foreground">
      {parts.map((k, i) => (
        <Fragment key={k}>
          {/* The line breaks between items, never inside one. */}
          {i > 0 ? " · " : null}
          <span className="whitespace-nowrap">
            {pointLabel[k]} <span className="tabular-nums">{points?.[k]}</span>
          </span>
        </Fragment>
      ))}
    </p>
  );
}

/** A flag, with what it means on hover or focus. */
function Flag({ flag }: { flag: string }) {
  const help = flagHelp[flag];
  const badge = (
    <Badge variant="warning" tabIndex={help ? 0 : undefined}>
      {flagLabel[flag] ?? flag}
    </Badge>
  );
  if (!help) return badge;
  return (
    <Tooltip>
      <TooltipTrigger asChild>{badge}</TooltipTrigger>
      <TooltipContent className="max-w-64">{help}</TooltipContent>
    </Tooltip>
  );
}

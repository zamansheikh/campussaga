"use client";

import { Megaphone, PackageCheck, Plus, Rocket, X } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { type CampaignPrize, prizeForRank } from "@/lib/admin/growth";

import { announceWinners, markDelivered, publishCampaign } from "../actions";

export function PublishButton({ id, title }: { id: string; title: string }) {
  const router = useRouter();
  return (
    <ConfirmAction
      trigger={
        <Button>
          <Rocket /> Publish
        </Button>
      }
      title="Publish this campaign?"
      description={
        <>
          <p>
            &quot;{title}&quot; goes live for students. After this, only the end and settle dates, the rules and the prizes can change.
          </p>
          <p>Check the dates, the universities and the prizes first.</p>
        </>
      }
      confirmLabel="Publish"
      action={() => publishCampaign(id)}
      success="Campaign published"
      onDone={() => router.refresh()}
    />
  );
}

export function DeliveredButton({ campaignId, userId, name }: { campaignId: string; userId: string; name: string }) {
  const router = useRouter();
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline" size="sm">
          <PackageCheck /> Mark delivered
        </Button>
      }
      title="Mark this prize as delivered?"
      description={<p>{name} received the prize. Their contact details are deleted 90 days after this.</p>}
      confirmLabel="Mark delivered"
      action={() => markDelivered(campaignId, userId)}
      success="Marked as delivered"
      onDone={() => router.refresh()}
    />
  );
}

/** `eligible` false: too few friends from other universities, no rank, can't win. */
type Candidate = { id: string; name: string; rank: number | null; disqualified?: boolean; eligible?: boolean };

/** Can win: ranked, eligible and not disqualified. */
function canWin(c: Candidate): c is Candidate & { rank: number } {
  return c.rank !== null && c.eligible !== false && !c.disqualified;
}
type Row = { key: number; userId: string; rank: string };

/**
 * Announce winners: starts from the standings' ranks that have a prize (not
 * disqualified people), lets the admin change who gets which rank, and asks
 * before sending.
 */
export function AnnounceWinners({ campaignId, prizes, candidates }: { campaignId: string; prizes: CampaignPrize[]; candidates: Candidate[] }) {
  const router = useRouter();
  const [rows, setRows] = useState<Row[]>(() =>
    candidates.filter((c) => canWin(c) && prizeForRank(prizes, c.rank)).map((c, i) => ({ key: i, userId: c.id, rank: String(c.rank) })),
  );
  const [nextKey, setNextKey] = useState(candidates.length + 1);
  const byId = new Map(candidates.map((c) => [c.id, c]));
  const winners = rows.map((r) => ({ userId: r.userId, rank: Number(r.rank) }));
  const notEligible = rows.filter((r) => byId.get(r.userId)?.eligible === false);
  const valid =
    winners.length > 0 &&
    notEligible.length === 0 &&
    winners.every((w) => w.userId && Number.isInteger(w.rank) && w.rank >= 1) &&
    new Set(winners.map((w) => w.userId)).size === winners.length &&
    new Set(winners.map((w) => w.rank)).size === winners.length;

  function patch(key: number, change: Partial<Row>) {
    setRows((rs) => rs.map((r) => (r.key === key ? { ...r, ...change } : r)));
  }

  return (
    <div className="space-y-3">
      <div className="divide-y rounded-xl border bg-card">
        {rows.length === 0 ? <p className="p-4 text-sm text-muted-foreground">No winners yet. Add the people who won.</p> : null}
        {rows.map((r) => {
          const rank = Number(r.rank);
          const prize = Number.isInteger(rank) ? prizeForRank(prizes, rank) : "";
          return (
            <div key={r.key} className="flex flex-wrap items-center gap-2 p-3">
              <Input
                aria-label="Rank"
                type="number"
                min={1}
                className="w-20"
                value={r.rank}
                onChange={(e) => patch(r.key, { rank: e.target.value })}
              />
              <select
                aria-label="Winner"
                className="h-9 min-w-0 flex-1 rounded-md border border-input bg-background px-3 text-sm"
                value={r.userId}
                onChange={(e) => patch(r.key, { userId: e.target.value })}
              >
                {candidates.map((c) => (
                  <option key={c.id} value={c.id} disabled={c.eligible === false}>
                    {c.rank === null ? "—" : `#${c.rank}`} {c.name}
                    {c.disqualified ? " (disqualified)" : ""}
                    {c.eligible === false ? " (not eligible)" : ""}
                  </option>
                ))}
              </select>
              <span className="w-full text-xs text-muted-foreground sm:w-56">{prize ? `Prize: ${prize}` : "No prize for this rank"}</span>
              <Button variant="ghost" size="icon" aria-label="Remove" onClick={() => setRows((rs) => rs.filter((x) => x.key !== r.key))}>
                <X />
              </Button>
            </div>
          );
        })}
      </div>
      <div className="flex flex-wrap gap-2">
        <Button
          variant="outline"
          disabled={candidates.length === 0}
          onClick={() => {
            const used = new Set(rows.map((r) => r.userId));
            const next = candidates.find((c) => !used.has(c.id) && canWin(c)) ?? candidates.find(canWin);
            if (!next) return;
            setRows((rs) => [...rs, { key: nextKey, userId: next.id, rank: String(next.rank ?? "") }]);
            setNextKey(nextKey + 1);
          }}
        >
          <Plus /> Add a winner
        </Button>
        <ConfirmAction
          trigger={
            <Button disabled={!valid}>
              <Megaphone /> Announce winners
            </Button>
          }
          title="Announce these winners?"
          description={
            <>
              <p>Each winner gets a notification and can send their delivery details. You can&apos;t change the winners afterwards.</p>
              <ul className="list-disc ps-5">
                {rows.map((r) => (
                  <li key={r.key}>
                    #{r.rank} {byId.get(r.userId)?.name ?? "?"}: {prizeForRank(prizes, Number(r.rank)) || "no prize for this rank"}
                  </li>
                ))}
              </ul>
            </>
          }
          confirmLabel="Announce"
          action={() => announceWinners(campaignId, winners)}
          success="Winners announced"
          onDone={() => router.refresh()}
        />
      </div>
      {notEligible.length > 0 ? (
        <p className="text-xs text-destructive">Not eligible, so they can&apos;t win: {notEligible.map((r) => byId.get(r.userId)?.name ?? "?").join(", ")}.</p>
      ) : !valid && rows.length > 0 ? (
        <p className="text-xs text-destructive">Each winner needs a different person and a different rank.</p>
      ) : null}
    </div>
  );
}

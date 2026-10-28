"use client";

import { ArrowDown, ArrowUp, Loader2, Plus, Trash2 } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import type { BusStop } from "@/lib/admin/transport";

import { saveStops } from "../actions";

type Row = { key: number; name: string; landmark: string; to: string; from: string };

const toRow = (s: BusStop, key: number): Row => ({
  key,
  name: s.name,
  landmark: s.landmark,
  to: s.toCampusMin == null ? "" : String(s.toCampusMin),
  from: s.fromCampusMin == null ? "" : String(s.fromCampusMin),
});

const mins = (v: string) => (v.trim() === "" ? null : Number(v));

/** A route's stops in order, from the far end to campus, with their minute offsets. */
export function StopsEditor({ routeId, stops }: { routeId: string; stops: BusStop[] }) {
  const [rows, setRows] = useState(() => stops.map(toRow));
  const [nextKey, setNextKey] = useState(stops.length);
  const [dirty, setDirty] = useState(false);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function change(next: Row[]) {
    setRows(next);
    setDirty(true);
  }

  function edit(key: number, patch: Partial<Row>) {
    change(rows.map((r) => (r.key === key ? { ...r, ...patch } : r)));
  }

  function move(i: number, by: number) {
    const next = [...rows];
    const [r] = next.splice(i, 1);
    if (!r) return;
    next.splice(i + by, 0, r);
    change(next);
  }

  function save() {
    setError(undefined);
    startTransition(async () => {
      const res = await saveStops(
        routeId,
        rows.map((r) => ({ name: r.name, landmark: r.landmark, toCampusMin: mins(r.to), fromCampusMin: mins(r.from) })),
      );
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success("Stops saved");
      if (res.data) {
        setRows(res.data.stops.map(toRow));
        setNextKey(res.data.stops.length);
      }
      setDirty(false);
    });
  }

  return (
    <section className="rounded-xl border bg-card p-4" aria-labelledby="stops-title">
      <div className="mb-3 flex flex-wrap items-start justify-between gap-2">
        <div>
          <h2 id="stops-title" className="font-semibold">
            Stops
          </h2>
          <p className="text-sm text-muted-foreground">
            From the far end to campus. Minutes count from the first stop going to campus, and from campus on the way
            back. Leave a time empty if the bus doesn&apos;t stop there that way.
          </p>
        </div>
        <Button onClick={save} disabled={!dirty || pending}>
          {pending ? <Loader2 className="animate-spin" /> : null}
          Save stops
        </Button>
      </div>

      {rows.length === 0 ? (
        <p className="py-4 text-sm text-muted-foreground">No stops yet.</p>
      ) : (
        <ol className="grid gap-2">
          <li className="hidden grid-cols-[2rem_1fr_1fr_7rem_7rem_auto] gap-2 px-1 text-xs font-medium text-muted-foreground md:grid">
            <span>#</span>
            <span>Stop</span>
            <span>Landmark</span>
            <span>To campus (min)</span>
            <span>Way back (min)</span>
            <span className="sr-only">Actions</span>
          </li>
          {rows.map((r, i) => (
            <li
              key={r.key}
              className="grid grid-cols-2 items-center gap-2 rounded-lg border p-2 md:grid-cols-[2rem_1fr_1fr_7rem_7rem_auto] md:border-0 md:p-0"
            >
              <span className="col-span-2 text-sm font-medium text-muted-foreground md:col-span-1 md:text-center">
                {i + 1}
              </span>
              <Input
                aria-label={`Stop ${i + 1} name`}
                value={r.name}
                maxLength={60}
                placeholder="Stop name"
                onChange={(e) => edit(r.key, { name: e.target.value })}
                className="col-span-2 md:col-span-1"
              />
              <Input
                aria-label={`Stop ${i + 1} landmark`}
                value={r.landmark}
                maxLength={100}
                placeholder="Landmark (optional)"
                onChange={(e) => edit(r.key, { landmark: e.target.value })}
                className="col-span-2 md:col-span-1"
              />
              <Input
                aria-label={`Stop ${i + 1} minutes to campus`}
                inputMode="numeric"
                type="number"
                min={0}
                max={600}
                value={r.to}
                placeholder="—"
                onChange={(e) => edit(r.key, { to: e.target.value })}
              />
              <Input
                aria-label={`Stop ${i + 1} minutes on the way back`}
                inputMode="numeric"
                type="number"
                min={0}
                max={600}
                value={r.from}
                placeholder="—"
                onChange={(e) => edit(r.key, { from: e.target.value })}
              />
              <div className="col-span-2 flex justify-end md:col-span-1">
                <Button variant="ghost" size="icon" aria-label="Move up" disabled={i === 0} onClick={() => move(i, -1)}>
                  <ArrowUp />
                </Button>
                <Button
                  variant="ghost"
                  size="icon"
                  aria-label="Move down"
                  disabled={i === rows.length - 1}
                  onClick={() => move(i, 1)}
                >
                  <ArrowDown />
                </Button>
                <Button
                  variant="ghost"
                  size="icon"
                  aria-label={`Remove stop ${i + 1}`}
                  onClick={() => change(rows.filter((x) => x.key !== r.key))}
                >
                  <Trash2 />
                </Button>
              </div>
            </li>
          ))}
        </ol>
      )}

      <Button
        variant="outline"
        className="mt-3"
        onClick={() => {
          change([...rows, { key: nextKey, name: "", landmark: "", to: "", from: "" }]);
          setNextKey(nextKey + 1);
        }}
      >
        <Plus /> Add stop
      </Button>

      {error ? (
        <p role="alert" className="mt-3 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      ) : null}
    </section>
  );
}

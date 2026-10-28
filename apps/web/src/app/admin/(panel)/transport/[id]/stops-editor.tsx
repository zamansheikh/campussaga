"use client";

import { ArrowDown, ArrowUp, ClipboardPaste, ExternalLink, Loader2, Plus, Trash2 } from "lucide-react";
import { useMemo, useState, useTransition } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import {
  type BusStop,
  formatLatLng,
  isMirrored,
  legsFromOffsets,
  mirroredFromCampus,
  offsetsFromLegs,
  osmLink,
  parseLatLng,
  parseStopList,
} from "@/lib/admin/transport";
import { cn } from "@/lib/utils";

import { saveStops } from "../actions";

/** One row. Times are legs: minutes from the timed stop before (way back: after). */
type Row = { key: number; name: string; landmark: string; to: string; back: string; location: string };

const num = (v: number | null) => (v == null ? "" : String(v));
const mins = (v: string) => (v.trim() === "" ? null : Math.max(0, Math.round(Number(v))));

function toRows(stops: BusStop[]): Row[] {
  const to = legsFromOffsets(stops.map((s) => s.toCampusMin));
  const back = legsFromOffsets(stops.map((s) => s.fromCampusMin).reverse()).reverse();
  return stops.map((s, i) => ({
    key: i,
    name: s.name,
    landmark: s.landmark,
    to: num(to[i] ?? null),
    back: num(back[i] ?? null),
    location: formatLatLng(s.location),
  }));
}

/**
 * A route's stops in order, from the far end to campus: minutes from the stop
 * before, the way back as the same journey reversed (or set separately), and
 * where each stop is. Paste a notice's list to add many stops at once.
 */
export function StopsEditor({ routeId, stops }: { routeId: string; stops: BusStop[] }) {
  const [rows, setRows] = useState(() => toRows(stops));
  const [mirror, setMirror] = useState(() => isMirrored(stops));
  const [nextKey, setNextKey] = useState(stops.length);
  const [paste, setPaste] = useState<string | null>(null);
  const [dirty, setDirty] = useState(false);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  const toOffsets = useMemo(() => offsetsFromLegs(rows.map((r) => mins(r.to))), [rows]);
  const total = rows.length > 1 ? toOffsets.at(-1) : null;
  const drafts = useMemo(() => (paste == null ? [] : parseStopList(paste)), [paste]);

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

  function add(list: { name: string; landmark: string }[]) {
    const room = 60 - rows.length;
    if (list.length > room) {
      setError("A route can have at most 60 stops.");
      return;
    }
    change([...rows, ...list.map((d, i) => ({ key: nextKey + i, name: d.name, landmark: d.landmark, to: "", back: "", location: "" }))]);
    setNextKey(nextKey + list.length);
  }

  function switchMirror(on: boolean) {
    if (!on) {
      // Start the separate way back from the reversed times.
      const back = legsFromOffsets(mirroredFromCampus(toOffsets).reverse()).reverse();
      setRows(rows.map((r, i) => ({ ...r, back: num(back[i] ?? null) })));
    }
    setMirror(on);
    setDirty(true);
  }

  function save() {
    setError(undefined);
    const bad = rows.findIndex((r) => r.location.trim() !== "" && !parseLatLng(r.location));
    if (bad >= 0) {
      setError(`Stop ${bad + 1}: the location should look like "23.8103, 90.4125" or be a map link.`);
      return;
    }
    const to = offsetsFromLegs(rows.map((r) => mins(r.to)));
    const from = mirror
      ? mirroredFromCampus(to)
      : offsetsFromLegs(rows.map((r) => mins(r.back)).reverse()).reverse();
    if ([...to, ...from].some((m) => (m ?? 0) > 600)) {
      setError("A trip can't be longer than 10 hours. Check the minutes.");
      return;
    }
    startTransition(async () => {
      const res = await saveStops(
        routeId,
        rows.map((r, i) => ({
          name: r.name,
          landmark: r.landmark,
          toCampusMin: to[i] ?? null,
          fromCampusMin: from[i] ?? null,
          location: r.location.trim() ? parseLatLng(r.location) : null,
        })),
      );
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success("Stops saved");
      if (res.data) {
        setRows(toRows(res.data.stops));
        setNextKey(res.data.stops.length);
      }
      setDirty(false);
    });
  }

  const cols = mirror
    ? "md:grid-cols-[2rem_1fr_1fr_6.5rem_11rem_auto]"
    : "md:grid-cols-[2rem_1fr_1fr_6.5rem_6.5rem_11rem_auto]";

  return (
    <section className="rounded-xl border bg-card p-4" aria-labelledby="stops-title">
      <div className="mb-3 flex flex-wrap items-start justify-between gap-2">
        <div>
          <h2 id="stops-title" className="font-semibold">
            Stops
            {total != null ? <span className="ms-2 text-sm font-normal text-muted-foreground">· {total} min to campus</span> : null}
          </h2>
          <p className="max-w-prose text-sm text-muted-foreground">
            From the far end to campus. Minutes count from the stop before; leave them empty if you don&apos;t know
            (students see &quot;—&quot;). Location: paste &quot;lat, lng&quot; or a Google Maps or OpenStreetMap link.
          </p>
        </div>
        <Button onClick={save} disabled={!dirty || pending}>
          {pending ? <Loader2 className="animate-spin" /> : null}
          Save stops
        </Button>
      </div>

      <label className="mb-3 flex items-center gap-3 rounded-lg bg-muted/60 px-3 py-2 text-sm">
        <Switch checked={mirror} onCheckedChange={switchMirror} />
        <span>
          <span className="font-medium">Same times on the way back</span>
          <span className="block text-muted-foreground">The way back takes the same time between stops, in reverse.</span>
        </span>
      </label>

      {rows.length === 0 ? (
        <p className="py-4 text-sm text-muted-foreground">No stops yet. Add one, or paste a list.</p>
      ) : (
        <ol className="grid gap-2">
          <li className={cn("hidden gap-2 px-1 text-xs font-medium text-muted-foreground md:grid", cols)}>
            <span>#</span>
            <span>Stop</span>
            <span>Landmark</span>
            <span>Min from before</span>
            {mirror ? null : <span>Way back (min)</span>}
            <span>Location</span>
            <span className="sr-only">Actions</span>
          </li>
          {rows.map((r, i) => {
            const point = r.location.trim() ? parseLatLng(r.location) : null;
            return (
              <li
                key={r.key}
                className={cn("grid grid-cols-2 items-center gap-2 rounded-lg border p-2 md:border-0 md:p-0", cols)}
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
                {i === 0 ? (
                  <span className="px-2 text-sm text-muted-foreground">Start</span>
                ) : (
                  <Input
                    aria-label={`Stop ${i + 1}: minutes from the stop before`}
                    inputMode="numeric"
                    type="number"
                    min={0}
                    max={600}
                    value={r.to}
                    placeholder="—"
                    onChange={(e) => edit(r.key, { to: e.target.value })}
                  />
                )}
                {mirror ? null : i === rows.length - 1 ? (
                  <span className="px-2 text-sm text-muted-foreground">Start back</span>
                ) : (
                  <Input
                    aria-label={`Stop ${i + 1}: minutes on the way back from the stop after`}
                    inputMode="numeric"
                    type="number"
                    min={0}
                    max={600}
                    value={r.back}
                    placeholder="—"
                    onChange={(e) => edit(r.key, { back: e.target.value })}
                  />
                )}
                <div className="col-span-2 flex items-center gap-1 md:col-span-1">
                  <Input
                    aria-label={`Stop ${i + 1} location`}
                    aria-invalid={r.location.trim() !== "" && !point}
                    value={r.location}
                    placeholder="lat, lng"
                    onChange={(e) => edit(r.key, { location: e.target.value })}
                    onBlur={() => point && edit(r.key, { location: formatLatLng(point) })}
                  />
                  {point ? (
                    <Button variant="ghost" size="icon" asChild aria-label={`Stop ${i + 1} on OpenStreetMap`}>
                      <a href={osmLink(point)} target="_blank" rel="noreferrer">
                        <ExternalLink />
                      </a>
                    </Button>
                  ) : null}
                </div>
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
            );
          })}
        </ol>
      )}

      <div className="mt-3 flex flex-wrap gap-2">
        <Button variant="outline" onClick={() => add([{ name: "", landmark: "" }])}>
          <Plus /> Add stop
        </Button>
        <Button variant="outline" onClick={() => setPaste(paste == null ? "" : null)} aria-expanded={paste != null}>
          <ClipboardPaste /> Paste a list
        </Button>
      </div>

      {paste != null ? (
        <div className="mt-3 grid gap-2 rounded-lg border p-3">
          <label htmlFor="paste-stops" className="text-sm font-medium">
            Paste stops
          </label>
          <p className="text-sm text-muted-foreground">
            One per line, or separated by commas, like in a transport notice. Text in brackets becomes the landmark.
          </p>
          <Textarea id="paste-stops" rows={4} value={paste} onChange={(e) => setPaste(e.target.value)} />
          {drafts.length > 0 ? (
            <ol className="flex flex-wrap gap-1.5 text-xs">
              {drafts.map((d, i) => (
                <li key={i} className="rounded-md bg-muted px-2 py-1">
                  {i + 1}. {d.name}
                  {d.landmark ? <span className="text-muted-foreground"> ({d.landmark})</span> : null}
                </li>
              ))}
            </ol>
          ) : null}
          <div>
            <Button
              disabled={drafts.length === 0}
              onClick={() => {
                add(drafts);
                setPaste(null);
              }}
            >
              Add {drafts.length === 1 ? "1 stop" : `${drafts.length} stops`}
            </Button>
          </div>
        </div>
      ) : null}

      {error ? (
        <p role="alert" className="mt-3 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      ) : null}
    </section>
  );
}

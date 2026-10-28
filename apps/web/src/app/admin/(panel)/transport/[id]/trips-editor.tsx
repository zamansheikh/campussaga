"use client";

import { Loader2, Plus, Trash2 } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { type BusDirection, type BusTrip, weekDays } from "@/lib/admin/transport";
import { cn } from "@/lib/utils";

import { saveTrips } from "../actions";

type Row = { key: number; direction: BusDirection; departs: string; weekdays: number[]; note: string };

const SAT_TO_THU = [6, 7, 1, 2, 3, 4];

const sections: { direction: BusDirection; title: string; hint: string }[] = [
  { direction: "to_campus", title: "To campus", hint: "Time it leaves the first stop." },
  { direction: "from_campus", title: "From campus", hint: "Time it leaves campus." },
];

/** A route's timetable: each departure is a time, a direction and its days. */
export function TripsEditor({ routeId, trips }: { routeId: string; trips: BusTrip[] }) {
  const [rows, setRows] = useState<Row[]>(() => trips.map((t, key) => ({ key, ...t })));
  const [nextKey, setNextKey] = useState(trips.length);
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

  function toggleDay(r: Row, day: number) {
    edit(r.key, { weekdays: r.weekdays.includes(day) ? r.weekdays.filter((d) => d !== day) : [...r.weekdays, day] });
  }

  function save() {
    setError(undefined);
    startTransition(async () => {
      const res = await saveTrips(
        routeId,
        rows.map(({ direction, departs, weekdays, note }) => ({ direction, departs, weekdays, note })),
      );
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success("Timetable saved");
      if (res.data) {
        setRows(res.data.trips.map((t, key) => ({ key, ...t })));
        setNextKey(res.data.trips.length);
      }
      setDirty(false);
    });
  }

  return (
    <section className="rounded-xl border bg-card p-4" aria-labelledby="trips-title">
      <div className="mb-3 flex flex-wrap items-start justify-between gap-2">
        <div>
          <h2 id="trips-title" className="font-semibold">
            Timetable
          </h2>
          <p className="text-sm text-muted-foreground">
            The app adds each stop&apos;s minutes to these times.
          </p>
        </div>
        <Button onClick={save} disabled={!dirty || pending}>
          {pending ? <Loader2 className="animate-spin" /> : null}
          Save timetable
        </Button>
      </div>

      <div className="grid gap-6">
        {sections.map((s) => {
          const list = rows
            .filter((r) => r.direction === s.direction)
            .sort((a, b) => a.departs.localeCompare(b.departs));
          return (
            <div key={s.direction}>
              <h3 className="text-sm font-medium">{s.title}</h3>
              <p className="mb-2 text-xs text-muted-foreground">{s.hint}</p>
              {list.length === 0 ? (
                <p className="py-2 text-sm text-muted-foreground">No departures.</p>
              ) : (
                <ul className="grid gap-2">
                  {list.map((r) => (
                    <li
                      key={r.key}
                      className="flex flex-col gap-2 rounded-lg border p-2 lg:flex-row lg:items-center"
                    >
                      <Input
                        type="time"
                        aria-label="Leaves at"
                        value={r.departs}
                        onChange={(e) => edit(r.key, { departs: e.target.value })}
                        className="lg:w-32"
                      />
                      <div role="group" aria-label="Days" className="flex flex-wrap gap-1">
                        {weekDays.map((d) => {
                          const on = r.weekdays.includes(d.day);
                          return (
                            <button
                              key={d.day}
                              type="button"
                              aria-pressed={on}
                              onClick={() => toggleDay(r, d.day)}
                              className={cn(
                                "h-8 min-w-11 rounded-md border px-2 text-xs font-medium transition-colors",
                                "focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
                                on ? "border-primary bg-primary text-primary-foreground" : "hover:bg-muted",
                              )}
                            >
                              {d.short}
                            </button>
                          );
                        })}
                      </div>
                      <Input
                        aria-label="Note"
                        value={r.note}
                        maxLength={100}
                        placeholder="Note (optional)"
                        onChange={(e) => edit(r.key, { note: e.target.value })}
                        className="lg:flex-1"
                      />
                      <Button
                        variant="ghost"
                        size="icon"
                        aria-label="Remove departure"
                        className="self-end lg:self-auto"
                        onClick={() => change(rows.filter((x) => x.key !== r.key))}
                      >
                        <Trash2 />
                      </Button>
                    </li>
                  ))}
                </ul>
              )}
              <Button
                variant="outline"
                size="sm"
                className="mt-2"
                onClick={() => {
                  const last = list.at(-1);
                  change([
                    ...rows,
                    {
                      key: nextKey,
                      direction: s.direction,
                      departs: last?.departs ?? (s.direction === "to_campus" ? "07:30" : "16:30"),
                      weekdays: last ? [...last.weekdays] : SAT_TO_THU,
                      note: "",
                    },
                  ]);
                  setNextKey(nextKey + 1);
                }}
              >
                <Plus /> Add departure
              </Button>
            </div>
          );
        })}
      </div>

      {error ? (
        <p role="alert" className="mt-3 rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      ) : null}
    </section>
  );
}

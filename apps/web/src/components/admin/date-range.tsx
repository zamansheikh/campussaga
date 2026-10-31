"use client";

import { Loader2 } from "lucide-react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTransition } from "react";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

/**
 * A report's date range in the URL (?from=YYYY-MM-DD&to=YYYY-MM-DD), with
 * quick presets. Days are Bangladesh days. [presets] map a label to a range.
 */
export function DateRange({
  from,
  to,
  presets,
  className,
}: {
  from: string;
  to: string;
  presets: { label: string; from: string; to: string }[];
  className?: string;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [pending, startTransition] = useTransition();

  function go(f: string, t: string) {
    if (!f || !t) return;
    // A reversed range is swapped rather than refused.
    const [a, b] = f <= t ? [f, t] : [t, f];
    const next = new URLSearchParams(params.toString());
    next.set("from", a);
    next.set("to", b);
    startTransition(() => router.replace(`${pathname}?${next.toString()}`, { scroll: false }));
  }

  return (
    <div className={cn("flex flex-wrap items-end gap-3", className)} aria-busy={pending}>
      <div className="space-y-1.5">
        <Label htmlFor="range-from" className="text-xs text-muted-foreground">
          From
        </Label>
        <Input id="range-from" type="date" className="w-40" value={from} max={to} onChange={(e) => go(e.target.value, to)} />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="range-to" className="text-xs text-muted-foreground">
          To
        </Label>
        <Input id="range-to" type="date" className="w-40" value={to} min={from} onChange={(e) => go(from, e.target.value)} />
      </div>
      <div className="flex flex-wrap gap-1">
        {presets.map((p) => {
          const on = p.from === from && p.to === to;
          return (
            <button
              key={p.label}
              type="button"
              aria-pressed={on}
              onClick={() => go(p.from, p.to)}
              className={cn(
                "h-9 rounded-md border px-3 text-sm transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
                on ? "border-primary bg-primary-soft text-primary-soft-foreground" : "hover:bg-muted",
              )}
            >
              {p.label}
            </button>
          );
        })}
      </div>
      {pending ? <Loader2 className="mb-2.5 size-4 animate-spin text-muted-foreground" aria-label="Loading" /> : null}
    </div>
  );
}

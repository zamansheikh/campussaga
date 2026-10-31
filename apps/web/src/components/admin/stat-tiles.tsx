import { formatNumber } from "@/lib/format";
import { percentText, type StatsTotals } from "@/lib/admin/sponsors";
import { cn } from "@/lib/utils";

/**
 * A report's totals as even tiles (views, students reached, taps, tap rate,
 * code copies when asked, hides), with one line below saying how each is
 * counted.
 */
export function StatTiles({ totals, copies = false, className }: { totals: StatsTotals; copies?: boolean; className?: string }) {
  const tiles: { label: string; value: string }[] = [
    { label: "Views", value: formatNumber(totals.views) },
    { label: "Students reached", value: formatNumber(totals.viewers) },
    { label: "Taps", value: formatNumber(totals.taps) },
    { label: "Tap rate", value: percentText(totals.ctr) },
    ...(copies ? [{ label: "Codes copied", value: formatNumber(totals.copies) }] : []),
    { label: "Hidden", value: formatNumber(totals.hides) },
  ];
  return (
    <div className={cn("space-y-2", className)}>
      <dl className="grid grid-cols-[repeat(auto-fit,minmax(7.5rem,1fr))] gap-3">
        {tiles.map((t) => (
          <div key={t.label} className="rounded-xl border bg-card px-4 py-3">
            <dt className="truncate text-xs text-muted-foreground">{t.label}</dt>
            <dd className="mt-1 text-xl font-semibold tabular-nums">{t.value}</dd>
          </div>
        ))}
      </dl>
      <p className="text-xs text-muted-foreground">
        A view is half the ad on screen for a second. Students reached counts different students. Tap rate is taps ÷ views. Hidden is “Hide this
        ad” (7 days).
      </p>
    </div>
  );
}

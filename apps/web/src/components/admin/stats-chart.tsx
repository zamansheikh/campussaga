"use client";

import { Bar, CartesianGrid, ComposedChart, Line, XAxis, YAxis } from "recharts";

import { type ChartConfig, ChartContainer, ChartLegend, ChartLegendContent, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { shortDay, type StatsDay } from "@/lib/admin/sponsors";

const config = {
  views: { label: "Views", color: "var(--chart-1)" },
  taps: { label: "Taps", color: "var(--chart-3)" },
} satisfies ChartConfig;

/**
 * Views (bars, left axis) and taps (line, right axis) per day. Taps are far
 * fewer than views, so each has its own scale. The numbers are also in the
 * daily table below the chart, for screen readers.
 */
export function StatsChart({ days }: { days: StatsDay[] }) {
  const rows = days.map((d) => ({ ...d, label: shortDay(d.day) }));
  return (
    <ChartContainer config={config} className="aspect-auto h-64 w-full" aria-hidden>
      <ComposedChart data={rows} margin={{ left: -12, right: -12, top: 8 }}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="label" tickLine={false} axisLine={false} tickMargin={8} minTickGap={24} />
        <YAxis yAxisId="views" allowDecimals={false} tickLine={false} axisLine={false} width={44} />
        <YAxis yAxisId="taps" orientation="right" allowDecimals={false} tickLine={false} axisLine={false} width={36} />
        <ChartTooltip cursor={false} content={<ChartTooltipContent />} />
        <ChartLegend content={<ChartLegendContent />} />
        <Bar yAxisId="views" dataKey="views" fill="var(--color-views)" radius={4} maxBarSize={28} />
        <Line yAxisId="taps" dataKey="taps" type="monotone" stroke="var(--color-taps)" strokeWidth={2} dot={false} />
      </ComposedChart>
    </ChartContainer>
  );
}

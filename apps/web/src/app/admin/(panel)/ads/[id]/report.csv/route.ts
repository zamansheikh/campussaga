import { NextResponse } from "next/server";

import { ApiError, errorMessage } from "@/lib/admin/errors";
import { api, query, requireAdmin } from "@/lib/admin/session";
import { type AdminPromo, ctrOf, type PromoStats, dateParam, daysBefore, dhakaToday, fileSlug, fillDays, promoStatsFrom, toCsv } from "@/lib/admin/sponsors";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** One ad's daily numbers as a CSV file (?from=&to=, Bangladesh days). */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  if (!UUID.test(id)) return new NextResponse("Not found", { status: 404 });
  const url = new URL(req.url);
  const today = dhakaToday();
  const to = dateParam(url.searchParams.get("to") ?? undefined, today);
  const from = dateParam(url.searchParams.get("from") ?? undefined, daysBefore(to, 29));
  try {
    const [promo, raw] = await Promise.all([api<AdminPromo>(`/admin/promos/${id}`), api<Partial<PromoStats>>(`/admin/promos/${id}/stats${query({ from, to })}`)]);
    const stats = promoStatsFrom(raw);
    const days = fillDays(stats.days, from, to);
    const csv = toCsv(
      ["Day", "Views", "Students reached", "Taps", "Tap rate %", "Codes copied", "Hidden"],
      [
        ...days.map((d) => [d.day, d.views, d.viewers, d.taps, (ctrOf(d.views, d.taps) * 100).toFixed(2), d.copies, d.hides]),
        ["Total", stats.totals.views, stats.totals.viewers, stats.totals.taps, (stats.totals.ctr * 100).toFixed(2), stats.totals.copies, stats.totals.hides],
      ],
    );
    const name = `varsitykotha-ad-${fileSlug(promo.titleEn || promo.kind)}-${from}-to-${to}.csv`;
    return new NextResponse(csv, {
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="${name}"`,
        "Cache-Control": "private, no-store",
      },
    });
  } catch (e) {
    if (e instanceof ApiError) return new NextResponse(errorMessage(e.code, e.details, e.message), { status: e.status === 404 ? 404 : 502 });
    throw e;
  }
}

import { NextResponse } from "next/server";

import { ApiError, errorMessage } from "@/lib/admin/errors";
import { api, query, requireAdmin } from "@/lib/admin/session";
import { type AdminSponsor, dateParam, daysBefore, dhakaToday, fileSlug, kindInfo, placementLabel, type PromoKind, type PromoPlacement, sponsorStatsFrom, toCsv } from "@/lib/admin/sponsors";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** A sponsor's totals per ad as a CSV file (?from=&to=, Bangladesh days), ready to send them. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  if (!UUID.test(id)) return new NextResponse("Not found", { status: 404 });
  const url = new URL(req.url);
  const to = dateParam(url.searchParams.get("to") ?? undefined, dhakaToday());
  const from = dateParam(url.searchParams.get("from") ?? undefined, daysBefore(to, 29));
  try {
    const [sponsor, raw] = await Promise.all([api<AdminSponsor>(`/admin/sponsors/${id}`), api(`/admin/sponsors/${id}/stats${query({ from, to })}`)]);
    const stats = sponsorStatsFrom(raw);
    const csv = toCsv(
      ["Ad", "Kind", "Place", "Views", "Students reached", "Taps", "Tap rate %", "Codes copied", "Hidden"],
      [
        ...stats.promos.map((p) => [
          p.titleEn || kindInfo[p.kind as PromoKind]?.label || "Ad",
          kindInfo[p.kind as PromoKind]?.label ?? p.kind,
          placementLabel[p.placement as PromoPlacement] ?? p.placement,
          p.views,
          p.viewers,
          p.taps,
          (p.ctr * 100).toFixed(2),
          p.copies,
          p.hides,
        ]),
        ["Total", "", "", stats.totals.views, stats.totals.viewers, stats.totals.taps, (stats.totals.ctr * 100).toFixed(2), stats.totals.copies, stats.totals.hides],
      ],
    );
    const name = `varsitykotha-${fileSlug(sponsor.name)}-${from}-to-${to}.csv`;
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

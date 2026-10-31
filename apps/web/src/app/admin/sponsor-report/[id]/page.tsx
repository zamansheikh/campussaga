import { ArrowLeft } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { BrandMark } from "@/components/site/brand-mark";
import { Button } from "@/components/ui/button";
import { ApiError } from "@/lib/admin/errors";
import { load } from "@/lib/admin/load";
import { api, query, requestNow, requireAdmin } from "@/lib/admin/session";
import {
  type AdminSponsor,
  dateParam,
  daysBefore,
  dhakaToday,
  kindInfo,
  percentText,
  placementLabel,
  type PromoKind,
  type PromoPlacement,
  sponsorStatsFrom,
} from "@/lib/admin/sponsors";
import { formatDate, formatNumber } from "@/lib/format";

import { PrintButton } from "./print-button";

export const metadata: Metadata = { title: "Sponsor report", robots: { index: false, follow: false } };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function longDay(day: string): string {
  return new Date(`${day}T00:00:00Z`).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" });
}

/**
 * A clean, printable report for a sponsor: totals for a date range and per
 * ad, how we count, and that no student's data is ever shared. Always light,
 * so it prints the same from a dark admin panel. "Print or save as PDF"
 * makes the file to send.
 */
export default async function SponsorReportPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ from?: string; to?: string }> }) {
  await requireAdmin();
  const { id } = await params;
  if (!UUID.test(id)) notFound();
  const sp = await searchParams;
  const now = requestNow();
  const to = dateParam(sp.to, dhakaToday(now));
  const from = dateParam(sp.from, daysBefore(to, 29));

  const res = await load(async () => {
    try {
      const [sponsor, raw] = await Promise.all([api<AdminSponsor>(`/admin/sponsors/${id}`), api(`/admin/sponsors/${id}/stats${query({ from, to })}`)]);
      return { sponsor, stats: sponsorStatsFrom(raw) };
    } catch (e) {
      if (e instanceof ApiError && e.status === 404) notFound();
      throw e;
    }
  });

  return (
    <div className="min-h-dvh bg-slate-100 py-6 text-slate-900 print:bg-white print:py-0">
      <style>{"@page { size: A4; margin: 14mm; } @media print { html, body { background: #fff !important; } }"}</style>
      <div className="mx-auto mb-4 flex max-w-[210mm] flex-wrap items-center justify-between gap-2 px-4 print:hidden">
        <Button variant="outline" asChild className="bg-white text-slate-900">
          <Link href={`/admin/sponsors/${id}${query({ from, to })}`}>
            <ArrowLeft /> Back to the sponsor
          </Link>
        </Button>
        <PrintButton />
      </div>

      <article className="mx-auto max-w-[210mm] bg-white px-5 py-8 shadow-sm sm:px-10 sm:py-10 print:max-w-none print:p-0 print:shadow-none">
        {res.error || !res.data ? (
          <p className="text-red-700">{res.error ?? "No data."}</p>
        ) : (
          <>
            <header className="flex items-start justify-between gap-6 border-b border-slate-200 pb-6">
              <div className="flex items-center gap-3">
                <BrandMark className="size-10" />
                <div>
                  <p className="text-lg font-semibold">VarsityKotha</p>
                  <p className="text-sm text-slate-500">Sponsor report</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-sm text-slate-500">Prepared for</p>
                <div className="mt-1 flex items-center justify-end gap-2">
                  {res.data.sponsor.logoUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={res.data.sponsor.logoUrl} alt="" className="size-8 rounded-full border border-slate-200 object-contain" />
                  ) : null}
                  <p className="text-lg font-semibold">{res.data.sponsor.name}</p>
                </div>
              </div>
            </header>

            <section className="mt-6">
              <p className="text-sm text-slate-500">Period (Bangladesh time)</p>
              <p className="text-base font-medium">
                {longDay(from)} – {longDay(to)}
              </p>
            </section>

            <section className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4 print:grid-cols-4">
              {[
                ["Views", formatNumber(res.data.stats.totals.views)],
                ["Students reached", formatNumber(res.data.stats.totals.viewers)],
                ["Taps", formatNumber(res.data.stats.totals.taps)],
                ["Tap rate", percentText(res.data.stats.totals.ctr)],
              ].map(([label, value]) => (
                <div key={label} className="rounded-xl border border-slate-200 px-4 py-3">
                  <p className="text-xs text-slate-500">{label}</p>
                  <p className="mt-1 text-2xl font-semibold tabular-nums">{value}</p>
                </div>
              ))}
            </section>

            <section className="mt-8">
              <h2 className="text-base font-semibold">By ad</h2>
              {res.data.stats.promos.length === 0 ? (
                <p className="mt-2 text-sm text-slate-500">No ads ran in this period.</p>
              ) : (
                <table className="mt-3 w-full border-collapse text-sm">
                  <thead>
                    <tr className="border-b border-slate-300 text-left text-xs text-slate-500">
                      <th className="py-2 pe-2 font-medium">Ad</th>
                      <th className="py-2 pe-2 font-medium">Where</th>
                      <th className="py-2 pe-2 text-right font-medium">Views</th>
                      <th className="py-2 pe-2 text-right font-medium">Students</th>
                      <th className="py-2 pe-2 text-right font-medium">Taps</th>
                      <th className="py-2 text-right font-medium">Tap rate</th>
                    </tr>
                  </thead>
                  <tbody>
                    {res.data.stats.promos.map((p) => (
                      <tr key={p.promoId || p.titleEn} className="border-b border-slate-100 align-top break-inside-avoid">
                        <td className="py-2 pe-2">
                          <p className="font-medium">{p.titleEn || kindInfo[p.kind as PromoKind]?.label || "Ad"}</p>
                          {p.startsAt || p.endsAt ? (
                            <p className="text-xs text-slate-500">
                              {formatDate(p.startsAt)} – {formatDate(p.endsAt)}
                            </p>
                          ) : null}
                        </td>
                        <td className="py-2 pe-2 text-slate-600">
                          {kindInfo[p.kind as PromoKind]?.label ?? p.kind}
                          <br />
                          <span className="text-xs">{placementLabel[p.placement as PromoPlacement] ?? p.placement}</span>
                        </td>
                        <td className="py-2 pe-2 text-right tabular-nums">{formatNumber(p.views)}</td>
                        <td className="py-2 pe-2 text-right tabular-nums">{formatNumber(p.viewers)}</td>
                        <td className="py-2 pe-2 text-right tabular-nums">{formatNumber(p.taps)}</td>
                        <td className="py-2 text-right tabular-nums">{percentText(p.ctr)}</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="font-semibold">
                      <td className="py-2 pe-2" colSpan={2}>
                        Total
                      </td>
                      <td className="py-2 pe-2 text-right tabular-nums">{formatNumber(res.data.stats.totals.views)}</td>
                      <td className="py-2 pe-2 text-right tabular-nums">{formatNumber(res.data.stats.totals.viewers)}</td>
                      <td className="py-2 pe-2 text-right tabular-nums">{formatNumber(res.data.stats.totals.taps)}</td>
                      <td className="py-2 text-right tabular-nums">{percentText(res.data.stats.totals.ctr)}</td>
                    </tr>
                  </tfoot>
                </table>
              )}
              {res.data.stats.totals.copies > 0 ? (
                <p className="mt-3 text-sm text-slate-600">Promo codes copied: {formatNumber(res.data.stats.totals.copies)}</p>
              ) : null}
            </section>

            <section className="mt-8 rounded-xl bg-slate-50 p-4 text-xs leading-relaxed text-slate-600 break-inside-avoid print:bg-white print:border print:border-slate-200">
              <p className="font-semibold text-slate-800">How we count</p>
              <ul className="mt-1 list-disc space-y-0.5 ps-4">
                <li>A view counts when at least half of the ad is on a student&apos;s screen for one second, at most once per screen visit.</li>
                <li>Students reached counts different students. Taps count taps on the ad&apos;s button or link; the tap rate is taps divided by views.</li>
                <li>Views by the VarsityKotha team are not counted.</li>
                <li>These are totals only. VarsityKotha never shares any student&apos;s name, contact or personal data with sponsors.</li>
              </ul>
            </section>

            <footer className="mt-8 flex justify-between border-t border-slate-200 pt-4 text-xs text-slate-500">
              <span>VarsityKotha · varsitykotha.com</span>
              <span>Prepared {formatDate(new Date(now).toISOString())}</span>
            </footer>
          </>
        )}
      </article>
    </div>
  );
}

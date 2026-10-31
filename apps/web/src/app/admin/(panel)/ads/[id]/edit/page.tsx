import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { notFound } from "next/navigation";

import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Button } from "@/components/ui/button";
import { ApiError } from "@/lib/admin/errors";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import { type AdminPromo, type AdminSponsor, promoFrom } from "@/lib/admin/sponsors";

import { AdForm } from "../../ad-form";
import { adFormData } from "../../form-data";

export const metadata = { title: "Edit ad" };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function EditAdPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  if (!UUID.test(id)) notFound();
  const res = await load(async () => {
    try {
      const [raw, data] = await Promise.all([api<AdminPromo>(`/admin/promos/${id}`), adFormData()]);
      return { promo: promoFrom(raw), ...data };
    } catch (e) {
      if (e instanceof ApiError && e.status === 404) notFound();
      throw e;
    }
  });
  if (res.error || !res.data) return <ErrorPanel message={res.error ?? "No data."} />;
  const { promo, sponsors } = res.data;
  // An archived sponsor is no longer in the picker, but its ads still need it.
  const withOwn: AdminSponsor[] =
    promo.sponsor && !sponsors.some((s) => s.id === promo.sponsorId)
      ? [...sponsors, { id: promo.sponsor.id, name: promo.sponsor.name, category: promo.sponsor.category ?? "general", logoUrl: promo.sponsor.logoUrl }]
      : sponsors;
  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href={`/admin/ads/${id}`}>
          <ArrowLeft /> {promo.titleEn || "Ad"}
        </Link>
      </Button>
      <PageHeader title="Edit ad" description="The preview shows the ad as the app draws it." />
      <AdForm
        promo={promo}
        sponsors={withOwn}
        universities={res.data.universities}
        // An ended campaign is no longer offered, but this ad may point at it.
        campaigns={
          promo.campaignId && !res.data.campaigns.some((c) => c.id === promo.campaignId)
            ? [...res.data.campaigns, { id: promo.campaignId, titleEn: promo.campaign?.titleEn ?? "This campaign", status: "Ended" }]
            : res.data.campaigns
        }
      />
    </>
  );
}

import { ArrowLeft } from "lucide-react";
import Link from "next/link";

import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Button } from "@/components/ui/button";
import { load } from "@/lib/admin/load";
import { requireAdmin } from "@/lib/admin/session";
import { kindOrder, type PromoKind } from "@/lib/admin/sponsors";

import { AdForm } from "../ad-form";
import { adFormData } from "../form-data";

export const metadata = { title: "New ad" };

export default async function NewAdPage({ searchParams }: { searchParams: Promise<{ sponsorId?: string; kind?: string }> }) {
  await requireAdmin();
  const sp = await searchParams;
  const data = await load(() => adFormData());
  const kind = kindOrder.includes(sp.kind as PromoKind) ? (sp.kind as PromoKind) : undefined;
  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/ads">
          <ArrowLeft /> Ads
        </Link>
      </Button>
      <PageHeader title="New ad" description="It starts as a draft. Students see nothing until you publish it." />
      {data.error || !data.data ? (
        <ErrorPanel message={data.error ?? "No data."} />
      ) : (
        <AdForm {...data.data} initialSponsorId={data.data.sponsors.some((s) => s.id === sp.sponsorId) ? sp.sponsorId : undefined} initialKind={kind} />
      )}
    </>
  );
}

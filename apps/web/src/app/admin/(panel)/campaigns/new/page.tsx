import { ArrowLeft } from "lucide-react";
import Link from "next/link";

import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Button } from "@/components/ui/button";
import { load } from "@/lib/admin/load";
import { requireAdmin } from "@/lib/admin/session";
import { allUniversities } from "@/lib/admin/universities";

import { CampaignForm } from "../campaign-form";

export const metadata = { title: "New campaign" };

export default async function NewCampaignPage() {
  await requireAdmin();
  const unis = await load(() => allUniversities());
  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/campaigns">
          <ArrowLeft /> Campaigns
        </Link>
      </Button>
      <PageHeader title="New campaign" description="It starts as a draft. Students see nothing until you publish it." />
      {unis.error ? <ErrorPanel message={unis.error} /> : <CampaignForm universities={(unis.data ?? []).map((u) => ({ id: u.id, slug: u.slug, name: u.name }))} />}
    </>
  );
}

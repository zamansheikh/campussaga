import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { redirect } from "next/navigation";

import { ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Button } from "@/components/ui/button";
import type { AdminCampaign } from "@/lib/admin/growth";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import { allUniversities } from "@/lib/admin/universities";

import { CampaignForm } from "../../campaign-form";

export const metadata = { title: "Edit campaign" };

export default async function EditCampaignPage({ params }: { params: Promise<{ id: string }> }) {
  await requireAdmin();
  const { id } = await params;
  const [res, unis] = await Promise.all([load(() => api<AdminCampaign>(`/admin/campaigns/${encodeURIComponent(id)}`)), load(() => allUniversities())]);
  if (res.data?.status === "announced") redirect(`/admin/campaigns/${id}`);
  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href={`/admin/campaigns/${id}`}>
          <ArrowLeft /> Campaign
        </Link>
      </Button>
      <PageHeader title="Edit campaign" />
      {res.error || !res.data ? (
        <ErrorPanel message={res.error ?? "Not found."} />
      ) : unis.error ? (
        <ErrorPanel message={unis.error} />
      ) : (
        <CampaignForm campaign={res.data} universities={(unis.data ?? []).map((u) => ({ id: u.id, slug: u.slug, name: u.name }))} />
      )}
    </>
  );
}

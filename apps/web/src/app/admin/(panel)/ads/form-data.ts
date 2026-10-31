import "server-only";

import type { AdminCampaign } from "@/lib/admin/growth";
import { api, query } from "@/lib/admin/session";
import { type AdminSponsor, listOf } from "@/lib/admin/sponsors";
import type { Paged } from "@/lib/admin/types";
import { allUniversities } from "@/lib/admin/universities";

import type { CampaignOption, UniversityWithCity } from "./ad-form";

/** What the ad form picks from: sponsors (not archived), universities with their city, and campaigns. */
export async function adFormData(): Promise<{ sponsors: AdminSponsor[]; universities: UniversityWithCity[]; campaigns: CampaignOption[] }> {
  const [sponsors, unis, campaigns] = await Promise.all([
    api<Paged<AdminSponsor> | AdminSponsor[]>(`/admin/sponsors${query({ pageSize: 200 })}`).then(listOf),
    allUniversities(),
    api<AdminCampaign[] | { items: AdminCampaign[] }>("/admin/campaigns")
      .then(listOf)
      .catch(() => [] as AdminCampaign[]),
  ]);
  return {
    sponsors: sponsors.filter((s) => !s.archivedAt).sort((a, b) => a.name.localeCompare(b.name)),
    universities: unis.map((u) => ({ id: u.id, slug: u.slug, name: u.name, city: u.city ?? null })),
    campaigns: campaigns
      .filter((c) => c.status === "draft" || c.status === "live")
      .map((c) => ({ id: c.id, titleEn: c.titleEn, status: c.status === "live" ? "Live" : "Draft" })),
  };
}

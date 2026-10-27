import "server-only";

import { api } from "@/lib/admin/session";
import type { AdminUniversity } from "@/lib/admin/types";

/** Every university (the API returns them unpaged, as a list or {items}). */
export async function allUniversities(params = ""): Promise<AdminUniversity[]> {
  const res = await api<AdminUniversity[] | { items: AdminUniversity[] }>(`/admin/universities${params}`);
  return Array.isArray(res) ? res : res.items;
}

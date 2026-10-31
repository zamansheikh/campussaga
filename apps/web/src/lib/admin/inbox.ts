import "server-only";

import { cache } from "react";

import type { NavCounts } from "@/components/admin/nav";
import { load } from "@/lib/admin/load";
import { api } from "@/lib/admin/session";
import type { AdminInbox } from "@/lib/admin/types";

/** The central "needs attention" lists (once per request, shared by the nav and the page). */
export const getInbox = cache(() => load(() => api<AdminInbox>("/admin/inbox")));

/** Open escalations + open domain requests + universities without a campus admin. */
export function attentionTotal(i: AdminInbox): number {
  return (i.escalations?.length ?? 0) + (i.domainRequests?.length ?? 0) + (i.universitiesWithoutCampusAdmin?.length ?? 0);
}

/** The nav badges; empty when the inbox can't load. */
export async function navCounts(): Promise<NavCounts> {
  const res = await getInbox();
  if (!res.data) return {};
  return { attention: attentionTotal(res.data), feedback: res.data.feedbackNew ?? 0 };
}

import { PageHeader } from "@/components/admin/page-header";
import { load } from "@/lib/admin/load";
import { api } from "@/lib/admin/session";
import type { AdminUserDetail } from "@/lib/admin/types";

import { PushForm } from "./push-form";

export const metadata = { title: "Push" };

export default async function PushPage({ searchParams }: { searchParams: Promise<{ userId?: string }> }) {
  const { userId } = await searchParams;
  const user = userId ? await load(() => api<AdminUserDetail>(`/admin/users/${encodeURIComponent(userId)}`)) : undefined;
  const initialUser = user?.data
    ? { id: user.data.id, email: user.data.email, displayName: user.data.displayName }
    : undefined;
  return (
    <>
      <PageHeader
        title="Push notification"
        description="Send a notification to one person (for example, to test their phone) or to everyone."
      />
      <PushForm initialUser={initialUser} />
    </>
  );
}

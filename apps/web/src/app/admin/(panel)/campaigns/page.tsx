import { Plus } from "lucide-react";
import Link from "next/link";

import { EmptyState, ErrorPanel } from "@/components/admin/notice";
import { PageHeader } from "@/components/admin/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { type AdminCampaign, statusLabel, statusTone } from "@/lib/admin/growth";
import { load } from "@/lib/admin/load";
import { api, requireAdmin } from "@/lib/admin/session";
import { formatDate } from "@/lib/format";

export const metadata = { title: "Campaigns" };

export default async function CampaignsPage() {
  await requireAdmin();
  const res = await load(async () => {
    const r = await api<AdminCampaign[] | { items: AdminCampaign[] }>("/admin/campaigns");
    return Array.isArray(r) ? r : (r.items ?? []);
  });
  return (
    <>
      <PageHeader
        title="Campaigns"
        description="Prize campaigns: the top inviters win by rank, after the team reviews the standings."
        actions={
          <>
            <Button variant="outline" asChild>
              <Link href="/admin/referrals">All referrals</Link>
            </Button>
            <Button asChild>
              <Link href="/admin/campaigns/new">
                <Plus /> New campaign
              </Link>
            </Button>
          </>
        }
      />
      {res.error ? (
        <ErrorPanel message={res.error} />
      ) : res.data && res.data.length === 0 ? (
        <EmptyState title="No campaigns yet">Create a draft, check it, then publish it.</EmptyState>
      ) : res.data ? (
        <div className="overflow-hidden rounded-xl border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Campaign</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="hidden md:table-cell">Runs</TableHead>
                <TableHead className="hidden lg:table-cell">Settles</TableHead>
                <TableHead className="hidden lg:table-cell">Prizes</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {res.data.map((c) => (
                <TableRow key={c.id} className="relative">
                  <TableCell className="max-w-72">
                    <Link href={`/admin/campaigns/${c.id}`} className="font-medium whitespace-normal after:absolute after:inset-0 hover:underline focus-visible:outline-none">
                      {c.titleEn}
                    </Link>
                    <p lang="bn" className="truncate text-xs text-muted-foreground">
                      {c.titleBn}
                    </p>
                  </TableCell>
                  <TableCell>
                    <Badge variant={statusTone[c.status] ?? "outline"}>{statusLabel[c.status] ?? c.status}</Badge>
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground md:table-cell">
                    {formatDate(c.startsAt)} to {formatDate(c.endsAt)}
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground lg:table-cell">{formatDate(c.settlesAt)}</TableCell>
                  <TableCell className="hidden max-w-56 truncate lg:table-cell">{(c.prizes ?? []).map((p) => p.titleEn).join(", ") || "—"}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : null}
    </>
  );
}

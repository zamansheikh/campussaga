import { ArrowLeft } from "lucide-react";
import Link from "next/link";

import { PageHeader } from "@/components/admin/page-header";
import { Button } from "@/components/ui/button";
import { requireAdmin } from "@/lib/admin/session";

import { SponsorForm } from "../sponsor-form";

export const metadata = { title: "New sponsor" };

export default async function NewSponsorPage() {
  await requireAdmin();
  return (
    <>
      <Button variant="ghost" size="sm" asChild className="mb-4 -ms-2">
        <Link href="/admin/sponsors">
          <ArrowLeft /> Sponsors
        </Link>
      </Button>
      <PageHeader title="New sponsor" description="Add the brand, then upload its logo and create its ads." />
      <SponsorForm />
    </>
  );
}

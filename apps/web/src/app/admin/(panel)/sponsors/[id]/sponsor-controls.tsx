"use client";

import { Archive, ArchiveRestore } from "lucide-react";
import { useRouter } from "next/navigation";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { ImageUploadField } from "@/components/admin/image-upload-field";
import { Button } from "@/components/ui/button";

import { archiveSponsor, removeSponsorLogo, restoreSponsor } from "../actions";

export function RestoreSponsorButton({ id, name }: { id: string; name: string }) {
  const router = useRouter();
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline">
          <ArchiveRestore /> Restore
        </Button>
      }
      title={`Restore ${name}?`}
      description={<p>They can get new ads again. Their old ads stay paused; resume the ones that should run.</p>}
      confirmLabel="Restore"
      action={() => restoreSponsor(id)}
      success="Sponsor restored"
      onDone={() => router.refresh()}
    />
  );
}

export function ArchiveSponsorButton({ id, name, liveAds }: { id: string; name: string; liveAds: number }) {
  const router = useRouter();
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline">
          <Archive /> Archive
        </Button>
      }
      title={`Archive ${name}?`}
      description={
        <>
          <p>{liveAds > 0 ? `Their ${liveAds} live ${liveAds === 1 ? "ad is" : "ads are"} paused. ` : ""}They can&apos;t get new ads until you restore them.</p>
          <p>Their reports stay, so you can still send them numbers.</p>
        </>
      }
      confirmLabel="Archive"
      destructive
      action={() => archiveSponsor(id)}
      success="Sponsor archived"
      onDone={() => router.refresh()}
    />
  );
}

export function SponsorLogoField({ id, logoUrl, disabled }: { id: string; logoUrl?: string | null; disabled?: boolean }) {
  return (
    <ImageUploadField
      title="Logo"
      description="Square, at least 256×256, JPEG, PNG or WebP up to 4 MB. Shown in a circle next to the brand's name; transparent parts become white."
      uploadUrl={`/admin/sponsor-logo/${id}`}
      url={logoUrl}
      shape="square"
      maxMb={4}
      side={512}
      format="png"
      onRemove={() => removeSponsorLogo(id)}
      disabled={disabled}
    />
  );
}

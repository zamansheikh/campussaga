"use client";

import { ImageIcon, ImagePlus, Loader2, RefreshCw, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { toast } from "sonner";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

import { removeCampaignBanner } from "./actions";

const MAX_BYTES = 8 * 1024 * 1024;
/** The website's nginx takes 1 MB per request, so bigger photos are shrunk here first. */
const SEND_MAX = 900 * 1024;
/** The API keeps banners at most this many pixels on a side. */
const SIDE = 1600;

type UploadResult = { ok: true; bannerUrl: string | null } | { ok: false; error: string };

/**
 * A photo small enough to send: as it is when it fits, else redrawn at most
 * SIDE px on a side as a JPEG (the API re-encodes it anyway). A file the
 * browser can't read is sent as it is, and the API says what's wrong.
 */
async function shrink(file: File): Promise<Blob> {
  if (file.size <= SEND_MAX) return file;
  let bmp: ImageBitmap;
  try {
    bmp = await createImageBitmap(file);
  } catch {
    return file;
  }
  try {
    const f = Math.min(1, SIDE / Math.max(bmp.width, bmp.height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(1, Math.round(bmp.width * f));
    canvas.height = Math.max(1, Math.round(bmp.height * f));
    const ctx = canvas.getContext("2d");
    if (!ctx) return file;
    ctx.fillStyle = "#fff"; // transparent parts come out white, as on the server
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(bmp, 0, 0, canvas.width, canvas.height);
    for (const q of [0.9, 0.82, 0.72, 0.6]) {
      const blob = await new Promise<Blob | null>((done) => canvas.toBlob(done, "image/jpeg", q));
      if (blob && blob.size <= SEND_MAX) return blob;
    }
    return file;
  } finally {
    bmp.close();
  }
}

/**
 * A campaign's banner photo: preview, upload, replace and remove. The file
 * goes to /admin/campaign-banner/{id}, which forwards it to the API with
 * the admin's token. `bannerUrl` is the API's path, which the website
 * serves too, so it works as the preview's src.
 */
export function BannerField({ campaignId, bannerUrl }: { campaignId: string; bannerUrl?: string | null }) {
  const router = useRouter();
  const input = useRef<HTMLInputElement>(null);
  // What this field last set, until the page sends a newer bannerUrl.
  const [local, setLocal] = useState({ from: bannerUrl ?? null, url: bannerUrl ?? null });
  const url = local.from === (bannerUrl ?? null) ? local.url : (bannerUrl ?? null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string>();

  async function upload(file: File) {
    setError(undefined);
    if (!file.type.startsWith("image/")) return setError("Choose a photo: JPEG, PNG or WebP.");
    if (file.size > MAX_BYTES) return setError("This photo is larger than 8 MB. Choose a smaller one.");
    setUploading(true);
    try {
      const photo = await shrink(file);
      const body = new FormData();
      body.set("image", photo, photo === file ? file.name : "banner.jpg");
      const res = await fetch(`/admin/campaign-banner/${campaignId}`, { method: "POST", body });
      if (res.redirected) return setError("Your session ended. Sign in again, then upload the photo.");
      if (res.status === 413) return setError("This photo is too large to upload. Choose a smaller one.");
      const out = (await res.json().catch(() => null)) as UploadResult | null;
      if (!out?.ok) return setError(out?.error ?? "The upload didn't work. Try again.");
      setLocal({ from: bannerUrl ?? null, url: out.bannerUrl });
      toast.success(url ? "Banner replaced" : "Banner added");
      router.refresh();
    } catch {
      setError("Can't reach the server. Try again.");
    } finally {
      setUploading(false);
      if (input.current) input.current.value = "";
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Banner</CardTitle>
        <CardDescription>Shown on the campaign in the app and on the rules page. 2:1, e.g. 1600×800. JPEG, PNG or WebP, up to 8 MB.</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="relative aspect-[2/1] w-full overflow-hidden rounded-lg border bg-muted">
          {url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={url} alt="Campaign banner" className="size-full object-cover" />
          ) : (
            <div className="flex size-full flex-col items-center justify-center gap-2 text-sm text-muted-foreground">
              <ImageIcon className="size-8" aria-hidden />
              No banner yet
            </div>
          )}
          {uploading ? (
            <div className="absolute inset-0 flex items-center justify-center bg-background/60">
              <Loader2 className="size-6 animate-spin" aria-label="Uploading" />
            </div>
          ) : null}
        </div>
        <input
          ref={input}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) void upload(f);
          }}
        />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => input.current?.click()} disabled={uploading}>
            {url ? <RefreshCw /> : <ImagePlus />}
            {url ? "Replace" : "Upload"}
          </Button>
          {url ? (
            <ConfirmAction
              trigger={
                <Button variant="outline" disabled={uploading}>
                  <Trash2 /> Remove
                </Button>
              }
              title="Remove the banner?"
              description={<p>Students stop seeing this photo on the campaign. You can add another one later.</p>}
              confirmLabel="Remove"
              destructive
              action={() => removeCampaignBanner(campaignId)}
              success="Banner removed"
              onDone={() => {
                setLocal({ from: bannerUrl ?? null, url: null });
                router.refresh();
              }}
            />
          ) : null}
        </div>
        {error ? (
          <p role="alert" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {error}
          </p>
        ) : null}
      </CardContent>
    </Card>
  );
}

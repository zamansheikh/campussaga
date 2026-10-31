"use client";

import { AlertTriangle, ImageIcon, ImagePlus, Loader2, RefreshCw, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { toast } from "sonner";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import type { ActionResult } from "@/lib/admin/errors";
import { cn } from "@/lib/utils";

/** The website's nginx takes 1 MB per request, so bigger images are shrunk here first. */
const SEND_MAX = 900 * 1024;

type UploadResult = { ok: true; url: string | null } | { ok: false; error: string };

/**
 * An image small enough to send: as it is when it fits, else redrawn at most
 * [side] px on a side (PNG for logos, to keep transparency; JPEG for photos).
 * A file the browser can't read is sent as it is, and the API says what's wrong.
 */
async function shrink(file: File, side: number, format: "png" | "jpeg"): Promise<Blob> {
  if (file.size <= SEND_MAX) return file;
  let bmp: ImageBitmap;
  try {
    bmp = await createImageBitmap(file);
  } catch {
    return file;
  }
  try {
    const f = Math.min(1, side / Math.max(bmp.width, bmp.height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(1, Math.round(bmp.width * f));
    canvas.height = Math.max(1, Math.round(bmp.height * f));
    const ctx = canvas.getContext("2d");
    if (!ctx) return file;
    if (format === "jpeg") {
      ctx.fillStyle = "#fff"; // transparent parts come out white, as on the server
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }
    ctx.drawImage(bmp, 0, 0, canvas.width, canvas.height);
    if (format === "png") {
      const blob = await new Promise<Blob | null>((done) => canvas.toBlob(done, "image/png"));
      if (blob && blob.size <= SEND_MAX) return blob;
    }
    for (const q of [0.9, 0.82, 0.72, 0.6]) {
      const blob = await new Promise<Blob | null>((done) => canvas.toBlob(done, "image/jpeg", q));
      if (blob && blob.size <= SEND_MAX) return blob;
    }
    return file;
  } finally {
    bmp.close();
  }
}

/** How far a w×h image is from the wanted shape, as a ratio (1 = exact). */
function shapeOff(w: number, h: number, want: number): number {
  const r = w / h;
  return r > want ? r / want : want / r;
}

/**
 * Upload, replace and remove one image (an ad's 2:1 photo or a sponsor's
 * square logo). The file goes to [uploadUrl], a route that forwards it to
 * the API with the admin's token. [url] is the API's path, which the website
 * serves too, so it works as the preview's src. After loading, it says when
 * the image's shape is far from the one the app uses (the app crops to fill).
 */
export function ImageUploadField({
  title,
  description,
  uploadUrl,
  url: pageUrl,
  shape,
  maxMb,
  side,
  format,
  onRemove,
  required = false,
  disabled = false,
}: {
  title: string;
  description: React.ReactNode;
  uploadUrl: string;
  url?: string | null;
  shape: "wide" | "square";
  maxMb: number;
  side: number;
  format: "png" | "jpeg";
  onRemove: () => Promise<ActionResult<unknown>>;
  required?: boolean;
  disabled?: boolean;
}) {
  const router = useRouter();
  const input = useRef<HTMLInputElement>(null);
  // What this field last set, until the page sends a newer url.
  const [local, setLocal] = useState({ from: pageUrl ?? null, url: pageUrl ?? null });
  const url = local.from === (pageUrl ?? null) ? local.url : (pageUrl ?? null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string>();
  const [size, setSize] = useState<{ w: number; h: number; src: string }>();
  const want = shape === "wide" ? 2 : 1;
  const off = size && size.src === url ? shapeOff(size.w, size.h, want) : 1;

  async function upload(file: File) {
    setError(undefined);
    if (!file.type.startsWith("image/")) return setError("Choose an image: JPEG, PNG or WebP.");
    if (file.size > maxMb * 1024 * 1024) return setError(`This image is larger than ${maxMb} MB. Choose a smaller one.`);
    setUploading(true);
    try {
      const img = await shrink(file, side, format);
      const body = new FormData();
      body.set("image", img, img === file ? file.name : format === "png" ? "image.png" : "image.jpg");
      const res = await fetch(uploadUrl, { method: "POST", body });
      if (res.redirected) return setError("Your session ended. Sign in again, then upload the image.");
      if (res.status === 413) return setError("This image is too large to upload. Choose a smaller one.");
      const out = (await res.json().catch(() => null)) as UploadResult | null;
      if (!out?.ok) return setError(out?.error ?? "The upload didn't work. Try again.");
      setLocal({ from: pageUrl ?? null, url: out.url });
      toast.success(url ? `${title} replaced` : `${title} added`);
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
        <CardTitle className="text-base">
          {title}
          {required ? <span className="ms-1 text-destructive">*</span> : null}
        </CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        <div
          className={cn(
            "relative overflow-hidden rounded-lg border bg-muted",
            shape === "wide" ? "aspect-[2/1] w-full" : "size-32",
            // A checkerboard shows a logo's transparent parts.
            shape === "square" && url ? "bg-[conic-gradient(#e2e8f0_25%,#fff_0_50%,#e2e8f0_0_75%,#fff_0)] bg-[length:16px_16px]" : "",
          )}
        >
          {url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={url}
              alt={title}
              className={cn("size-full", shape === "wide" ? "object-cover" : "object-contain")}
              onLoad={(e) => setSize({ w: e.currentTarget.naturalWidth, h: e.currentTarget.naturalHeight, src: url })}
            />
          ) : (
            <div className="flex size-full flex-col items-center justify-center gap-2 p-2 text-center text-sm text-muted-foreground">
              <ImageIcon className="size-7" aria-hidden />
              No {title.toLowerCase()} yet
            </div>
          )}
          {shape === "wide" && url ? (
            // The part a narrow phone shows: the app fills 2:1, so this is a guide only.
            <div aria-hidden className="pointer-events-none absolute inset-y-0 left-[8%] right-[8%] border-x border-dashed border-white/60" />
          ) : null}
          {uploading ? (
            <div className="absolute inset-0 flex items-center justify-center bg-background/60">
              <Loader2 className="size-6 animate-spin" aria-label="Uploading" />
            </div>
          ) : null}
        </div>
        {off > 1.08 && size ? (
          <p className="flex items-start gap-2 rounded-md bg-warning-soft px-3 py-2 text-sm text-warning">
            <AlertTriangle className="mt-0.5 size-4 shrink-0" aria-hidden />
            <span>
              This image is {size.w}×{size.h}, not {shape === "wide" ? "2:1" : "square"}. The app crops it to fill, so the edges may be cut. Keep text and
              logos away from the edges, or upload a {shape === "wide" ? "1600×800" : "512×512"} version.
            </span>
          </p>
        ) : null}
        <input
          ref={input}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="hidden"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) void upload(f);
          }}
        />
        <div className="flex flex-wrap gap-2">
          <Button type="button" variant="outline" onClick={() => input.current?.click()} disabled={uploading || disabled}>
            {url ? <RefreshCw /> : <ImagePlus />}
            {url ? "Replace" : "Upload"}
          </Button>
          {url ? (
            <ConfirmAction
              trigger={
                <Button type="button" variant="outline" disabled={uploading || disabled}>
                  <Trash2 /> Remove
                </Button>
              }
              title={`Remove the ${title.toLowerCase()}?`}
              description={<p>You can add another one later.</p>}
              confirmLabel="Remove"
              destructive
              action={onRemove}
              success={`${title} removed`}
              onDone={() => {
                setLocal({ from: pageUrl ?? null, url: null });
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

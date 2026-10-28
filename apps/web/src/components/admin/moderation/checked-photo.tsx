"use client";

import { Eye, ShieldAlert } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";

export type PhotoCheck = { imageId: string; score: number | null; flagged: boolean };

/**
 * One issue photo for a moderator. A photo the photo check flagged (or
 * couldn't check) stays blurred until the moderator chooses to look.
 */
export function CheckedPhoto({
  id,
  width,
  height,
  index,
  count,
  check,
}: {
  id: string;
  width: number;
  height: number;
  index: number;
  count: number;
  check?: PhotoCheck;
}) {
  const flagged = check?.flagged ?? false;
  const [shown, setShown] = useState(!flagged);
  const label =
    check?.score == null
      ? "Not checked: the photo check was unavailable"
      : `Flagged by the photo check (score ${check.score.toFixed(2)})`;

  return (
    <figure className="space-y-1">
      <div className="relative overflow-hidden rounded-lg border bg-muted">
        <a
          href={shown ? `/admin/media/${id}?size=full` : undefined}
          target="_blank"
          rel="noopener noreferrer"
          aria-disabled={!shown}
          tabIndex={shown ? undefined : -1}
          className="block focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
        >
          {/* Private photos come through our authenticated proxy, not the image optimizer. */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={`/admin/media/${id}?size=thumb`}
            alt={shown ? `Photo ${index + 1} of ${count} (opens full size)` : `Photo ${index + 1} of ${count}, hidden`}
            width={width}
            height={height}
            loading="lazy"
            className={`aspect-square w-full object-cover transition ${shown ? "" : "scale-110 blur-2xl"}`}
          />
        </a>
        {!shown ? (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 bg-background/60 p-2 text-center">
            <ShieldAlert className="size-5 text-destructive" aria-hidden />
            <p className="text-xs font-medium">{label}</p>
            <Button type="button" size="sm" variant="secondary" onClick={() => setShown(true)}>
              <Eye /> Show photo
            </Button>
          </div>
        ) : null}
      </div>
      {check ? (
        <figcaption className={`text-xs ${flagged ? "text-destructive" : "text-muted-foreground"}`}>
          {flagged ? label : `Photo check: ${check.score == null ? "not checked" : check.score.toFixed(2)}`}
        </figcaption>
      ) : null}
    </figure>
  );
}

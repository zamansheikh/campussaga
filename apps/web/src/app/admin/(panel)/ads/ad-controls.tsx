"use client";

import { CircleStop, Copy, Loader2, Pause, Pencil, Play, Rocket, Trash2 } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useTransition } from "react";
import { toast } from "sonner";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import type { AdminPromo } from "@/lib/admin/sponsors";

import { deletePromo, duplicatePromo, setPromoStatus } from "./actions";

/**
 * What can be done with an ad in its status: publish a draft, pause or end
 * a live one, resume a paused one, duplicate any, delete a draft.
 */
export function AdControls({ promo, missing, startsLater }: { promo: AdminPromo; missing: string[]; startsLater: boolean }) {
  const router = useRouter();
  const [copying, startCopy] = useTransition();
  const s = promo.status;
  const title = promo.titleEn || "this ad";

  function duplicate() {
    startCopy(async () => {
      const res = await duplicatePromo(promo.id);
      if (!res.ok) {
        toast.error(res.error);
        return;
      }
      toast.success("Copied as a new draft");
      router.push(`/admin/ads/${res.data?.id}/edit`);
    });
  }

  return (
    <>
      {s !== "ended" ? (
        <Button variant="outline" asChild>
          <Link href={`/admin/ads/${promo.id}/edit`}>
            <Pencil /> Edit
          </Link>
        </Button>
      ) : null}
      <Button variant="outline" onClick={duplicate} disabled={copying}>
        {copying ? <Loader2 className="animate-spin" /> : <Copy />} Duplicate
      </Button>
      {s === "draft" ? (
        <ConfirmAction
          trigger={
            <Button variant="outline">
              <Trash2 /> Delete
            </Button>
          }
          title="Delete this draft?"
          description={<p>&quot;{title}&quot; is deleted for good. Students never saw it.</p>}
          confirmLabel="Delete"
          destructive
          action={() => deletePromo(promo.id)}
          success="Draft deleted"
          onDone={() => router.push("/admin/ads")}
        />
      ) : null}
      {s === "live" || s === "paused" ? (
        <ConfirmAction
          trigger={
            <Button variant="outline">
              <CircleStop /> End
            </Button>
          }
          title="End this ad?"
          description={<p>Students stop seeing it, and it can&apos;t be restarted (you can duplicate it). Its report stays.</p>}
          confirmLabel="End"
          destructive
          action={() => setPromoStatus(promo.id, "ended")}
          success="Ad ended"
          onDone={() => router.refresh()}
        />
      ) : null}
      {s === "live" ? (
        <ConfirmAction
          trigger={
            <Button variant="outline">
              <Pause /> Pause
            </Button>
          }
          title="Pause this ad?"
          description={<p>Students stop seeing it until you resume it. While paused, you can change everything.</p>}
          confirmLabel="Pause"
          action={() => setPromoStatus(promo.id, "paused")}
          success="Ad paused"
          onDone={() => router.refresh()}
        />
      ) : null}
      {s === "draft" || s === "paused" ? (
        <ConfirmAction
          trigger={
            <Button disabled={missing.length > 0} title={missing.length ? `Missing: ${missing.join(", ")}` : undefined}>
              {s === "draft" ? <Rocket /> : <Play />} {s === "draft" ? "Publish" : "Resume"}
            </Button>
          }
          title={s === "draft" ? "Publish this ad?" : "Resume this ad?"}
          description={
            <>
              <p>
                &quot;{title}&quot; starts showing to the students it targets{startsLater ? ", from its start time" : " now"}.
              </p>
              <p>While it&apos;s live, only the end, total views, times a day and priority can change.</p>
            </>
          }
          confirmLabel={s === "draft" ? "Publish" : "Resume"}
          action={() => setPromoStatus(promo.id, "live")}
          success={s === "draft" ? "Ad published" : "Ad resumed"}
          onDone={() => router.refresh()}
        />
      ) : null}
    </>
  );
}

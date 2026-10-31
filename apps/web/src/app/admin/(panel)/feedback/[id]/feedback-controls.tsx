"use client";

import { Loader2, Send } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { replyToFeedback, setFeedbackStatus } from "@/app/admin/(panel)/feedback/actions";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { feedbackImageSrc, feedbackStatusLabel } from "@/lib/admin/feedback";
import type { FeedbackImage } from "@/lib/admin/types";

/** Screenshots as thumbnails; a click opens the full picture. */
export function FeedbackImages({ images }: { images: FeedbackImage[] }) {
  const [big, setBig] = useState<FeedbackImage>();
  return (
    <>
      <ul className="grid grid-cols-3 gap-2">
        {images.map((img, i) => (
          <li key={img.url}>
            <button
              type="button"
              onClick={() => setBig(img)}
              className="block w-full overflow-hidden rounded-lg border bg-muted focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
            >
              {/* Private screenshots come through our authenticated proxy, not the image optimizer. */}
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={feedbackImageSrc(img.thumbUrl || img.url)}
                alt={`Screenshot ${i + 1} of ${images.length} (click to enlarge)`}
                loading="lazy"
                className="aspect-square w-full object-cover"
              />
            </button>
          </li>
        ))}
      </ul>
      <Dialog open={Boolean(big)} onOpenChange={(o) => !o && setBig(undefined)}>
        <DialogContent className="max-w-3xl">
          <DialogTitle className="sr-only">Screenshot</DialogTitle>
          {big ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={feedbackImageSrc(big.url)} alt="Screenshot, full size" className="max-h-[80dvh] w-full rounded-md object-contain" />
          ) : null}
        </DialogContent>
      </Dialog>
    </>
  );
}

export function ReplyBox({ feedbackId, closed }: { feedbackId: string; closed: boolean }) {
  const [body, setBody] = useState("");
  const [pending, startTransition] = useTransition();

  function send() {
    startTransition(async () => {
      const res = await replyToFeedback(feedbackId, body);
      if (res.ok) {
        toast.success("Reply sent");
        setBody("");
      } else {
        toast.error(res.error);
      }
    });
  }

  return (
    <div className="space-y-2">
      <Label htmlFor="feedback-reply">Reply to the student</Label>
      <Textarea
        id="feedback-reply"
        value={body}
        maxLength={2000}
        rows={4}
        onChange={(e) => setBody(e.target.value)}
        placeholder="They see this as “VarsityKotha team” and get a push."
      />
      {closed ? <p className="text-xs text-muted-foreground">This one is closed. The reply still reaches the student.</p> : null}
      <Button onClick={send} disabled={!body.trim() || pending}>
        {pending ? <Loader2 className="animate-spin" /> : <Send />}
        Send reply
      </Button>
    </div>
  );
}

export function StatusSelect({ feedbackId, status }: { feedbackId: string; status: string }) {
  const [value, setValue] = useState(status);
  const [pending, startTransition] = useTransition();

  function change(next: string) {
    const before = value;
    setValue(next);
    startTransition(async () => {
      const res = await setFeedbackStatus(feedbackId, next);
      if (res.ok) {
        toast.success(`Marked ${feedbackStatusLabel[next]?.toLowerCase() ?? next}; the student was told`);
      } else {
        setValue(before);
        toast.error(res.error);
      }
    });
  }

  return (
    <div className="space-y-2">
      <Label htmlFor="feedback-status">Status</Label>
      <Select value={value} onValueChange={change} disabled={pending}>
        <SelectTrigger id="feedback-status" className="w-full">
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {Object.entries(feedbackStatusLabel).map(([v, label]) => (
            <SelectItem key={v} value={v}>
              {label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <p className="text-xs text-muted-foreground">Changing the status sends the student a push.</p>
    </div>
  );
}

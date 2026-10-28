"use client";

import { Ban, Check, EyeOff, Loader2, RotateCcw, Trash2, Undo2 } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { banAuthor, dismissReports, moderateComment, moderateIssue } from "@/app/admin/(panel)/moderation/actions";
import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import type { ActionResult } from "@/lib/admin/errors";
import type { ModerationAction, Visibility } from "@/lib/admin/types";
import { actionsFor } from "@/lib/admin/voice";

type Target = { type: "issue" | "comment"; id: string; issueId: string };

function moderate(target: Target, action: ModerationAction, reason?: string): Promise<ActionResult> {
  return target.type === "issue"
    ? moderateIssue({ id: target.id, action, reason })
    : moderateComment({ id: target.id, issueId: target.issueId, action, reason });
}

const what = (t: Target) => (t.type === "issue" ? "issue" : "comment");

/** The moderation actions for one issue or comment, by its state. */
export function ModerationButtons({
  target,
  visibility,
  canBan = true,
  openReports = 0,
  size = "sm",
}: {
  target: Target;
  visibility: Visibility | string;
  canBan?: boolean;
  /** Open reports on it. */
  openReports?: number;
  size?: "sm" | "default";
}) {
  const actions = actionsFor(visibility);
  const dismissLabel = openReports > 1 ? `Dismiss ${openReports} reports` : "Dismiss report";
  return (
    <div className="flex flex-wrap gap-2">
      {actions.includes("approve") ? (
        <ConfirmAction
          trigger={
            <Button size={size}>
              <Check /> Approve
            </Button>
          }
          title={`Approve this ${what(target)}?`}
          description={
            <p>It becomes public{target.type === "issue" ? " and the author gets a push" : ""}. Open reports on it are resolved.</p>
          }
          confirmLabel="Approve"
          action={() => moderate(target, "approve")}
          success="Approved"
        />
      ) : null}
      {actions.includes("restore") ? (
        <ConfirmAction
          trigger={
            <Button size={size} variant="outline">
              <RotateCcw /> Restore
            </Button>
          }
          title={`Restore this ${what(target)}?`}
          description={<p>It becomes public again. Open reports on it are resolved.</p>}
          confirmLabel="Restore"
          action={() => moderate(target, "restore")}
          success="Restored"
        />
      ) : null}
      {actions.includes("hide") ? (
        <ConfirmAction
          trigger={
            <Button size={size} variant="outline">
              <EyeOff /> Hide
            </Button>
          }
          title={`Hide this ${what(target)}?`}
          description={<p>Students stop seeing it until a moderator restores or removes it. The author still sees it.</p>}
          confirmLabel="Hide"
          action={() => moderate(target, "hide")}
          success="Hidden"
        />
      ) : null}
      {actions.includes("remove") ? <RemoveDialog target={target} size={size} /> : null}
      {openReports > 0 ? (
        <ConfirmAction
          trigger={
            <Button size={size} variant="ghost">
              <Undo2 /> {dismissLabel}
            </Button>
          }
          title="Dismiss the reports?"
          description={
            <p>
              The reports are closed as not breaking the rules. If the reports had hidden it, it becomes public again
              (a moderator&apos;s hide stays).
            </p>
          }
          confirmLabel="Dismiss"
          action={() => dismissReports({ targetType: target.type, targetId: target.id, issueId: target.issueId })}
          success="Reports dismissed"
        />
      ) : null}
      {canBan ? <BanDialog target={target} size={size} /> : null}
    </div>
  );
}

/** Remove needs a reason: the author sees it. */
function RemoveDialog({ target, size }: { target: Target; size: "sm" | "default" }) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [pending, startTransition] = useTransition();
  const ready = reason.trim().length > 0;

  function run() {
    startTransition(async () => {
      const res = await moderate(target, "remove", reason.trim());
      if (res.ok) {
        toast.success("Removed");
        setOpen(false);
        setReason("");
      } else {
        toast.error(res.error);
      }
    });
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(o) => {
        setOpen(o);
        if (!o) setReason("");
      }}
    >
      <DialogTrigger asChild>
        <Button size={size} variant="destructive">
          <Trash2 /> Remove
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Remove this {what(target)}?</DialogTitle>
          <DialogDescription>
            Nobody else sees it any more. The author sees it as removed, with your reason. It stays on record and can be
            restored.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor={`remove-reason-${target.id}`}>Reason (shown to the author)</Label>
          <Textarea
            id={`remove-reason-${target.id}`}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            maxLength={300}
            rows={3}
            placeholder="For example: names a student; please describe the problem without naming people."
          />
          <p className="text-end text-xs text-muted-foreground tabular-nums">{reason.length}/300</p>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={pending}>
            Cancel
          </Button>
          <Button variant="destructive" onClick={run} disabled={!ready || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Remove
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

const DURATIONS = [
  { value: "7", label: "7 days" },
  { value: "30", label: "30 days" },
  { value: "permanent", label: "Permanently" },
] as const;

/**
 * Ban the author from Campus Voice. The server finds them; the panel never
 * learns who they are.
 */
function BanDialog({ target, size }: { target: Target; size: "sm" | "default" }) {
  const [open, setOpen] = useState(false);
  const [duration, setDuration] = useState<(typeof DURATIONS)[number]["value"]>("7");
  const [reason, setReason] = useState("");
  const [typed, setTyped] = useState("");
  const [pending, startTransition] = useTransition();
  const ready = reason.trim().length > 0 && typed.trim() === "BAN";

  function reset() {
    setDuration("7");
    setReason("");
    setTyped("");
  }

  function run() {
    startTransition(async () => {
      const res = await banAuthor({
        targetType: target.type,
        id: target.id,
        issueId: target.issueId,
        days: duration === "permanent" ? null : (Number(duration) as 7 | 30),
        reason: reason.trim(),
      });
      if (res.ok) {
        toast.success(res.message ?? "The author is banned");
        setOpen(false);
        reset();
      } else {
        toast.error(res.error);
      }
    });
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(o) => {
        setOpen(o);
        if (!o) reset();
      }}
    >
      <DialogTrigger asChild>
        <Button size={size} variant="ghost" className="text-destructive hover:text-destructive">
          <Ban /> Ban author
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Ban the author of this {what(target)}?</DialogTitle>
          <DialogDescription asChild>
            <div className="space-y-2">
              <p>
                They can still read Campus Voice, but can&apos;t post, comment, vote or report until the ban ends. They
                aren&apos;t told who banned them.
              </p>
              <p className="flex items-start gap-2 rounded-md bg-muted p-2 text-foreground">
                <EyeOff className="mt-0.5 size-4 shrink-0" aria-hidden />
                You won&apos;t see who they are: the server finds the author and records only that this {what(target)}{" "}
                led to a ban.
              </p>
            </div>
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <div className="space-y-2">
            <Label htmlFor={`ban-duration-${target.id}`}>How long</Label>
            <Select value={duration} onValueChange={(v) => setDuration(v as typeof duration)}>
              <SelectTrigger id={`ban-duration-${target.id}`} className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {DURATIONS.map((d) => (
                  <SelectItem key={d.value} value={d.value}>
                    {d.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor={`ban-reason-${target.id}`}>Reason (for the record)</Label>
            <Textarea
              id={`ban-reason-${target.id}`}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              maxLength={300}
              rows={2}
              placeholder="For example: repeated threats in comments."
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor={`ban-confirm-${target.id}`}>
              Type <span className="font-mono font-semibold text-foreground">BAN</span> to confirm
            </Label>
            <Input
              id={`ban-confirm-${target.id}`}
              value={typed}
              onChange={(e) => setTyped(e.target.value)}
              autoComplete="off"
              spellCheck={false}
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={pending}>
            Cancel
          </Button>
          <Button variant="destructive" onClick={run} disabled={!ready || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Ban author
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

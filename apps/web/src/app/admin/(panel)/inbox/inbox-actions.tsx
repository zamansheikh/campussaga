"use client";

import { Check, Loader2, X } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";
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
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

import { approveDomainRequest, rejectDomainRequest, resolveEscalation } from "./actions";

/** Marks an escalation as dealt with; the text is kept with it. */
export function ResolveButton({ escalationId }: { escalationId: string }) {
  const [text, setText] = useState("");
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline" size="sm">
          <Check /> Resolve
        </Button>
      }
      title="Resolve this request?"
      description={
        <div className="space-y-1.5">
          <Label htmlFor={`resolve-${escalationId}`}>What did you do?</Label>
          <Textarea
            id={`resolve-${escalationId}`}
            value={text}
            maxLength={300}
            rows={3}
            onChange={(e) => setText(e.target.value)}
            placeholder="For example: removed the student's verification and told the campus admin"
          />
        </div>
      }
      confirmLabel="Resolve"
      action={() => resolveEscalation(escalationId, text)}
      success="Resolved"
      onDone={() => setText("")}
    />
  );
}

/** Adds the request's domain to a university (prefilled with the one the student chose). */
export function ApproveDomainDialog({
  requestId,
  domain,
  universityId,
  universities,
}: {
  requestId: string;
  domain: string;
  universityId: string | null;
  universities: UniversityOption[];
}) {
  const [open, setOpen] = useState(false);
  const [uni, setUni] = useState<string | null>(universityId);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function submit() {
    if (!uni) return;
    setError(undefined);
    startTransition(async () => {
      const res = await approveDomainRequest(requestId, uni);
      if (res.ok) {
        toast.success(`${domain} added`);
        setOpen(false);
      } else {
        setError(res.error);
      }
    });
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(o) => {
        setOpen(o);
        if (o) {
          setUni(universityId);
          setError(undefined);
        }
      }}
    >
      <DialogTrigger asChild>
        <Button size="sm">
          <Check /> Approve
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add {domain} to a university</DialogTitle>
          <DialogDescription>
            Students with an email at this domain can then verify with a code. Check the domain really belongs to the university.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor={`approve-uni-${requestId}`}>University</Label>
          <UniversityCombobox id={`approve-uni-${requestId}`} universities={universities} value={uni} onChange={setUni} />
          {error ? (
            <p role="alert" className="text-sm text-destructive">
              {error}
            </p>
          ) : null}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={pending}>
            Cancel
          </Button>
          <Button onClick={submit} disabled={!uni || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Add domain
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export function RejectDomainButton({ requestId, domain }: { requestId: string; domain: string }) {
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline" size="sm">
          <X /> Reject
        </Button>
      }
      title={`Reject ${domain}?`}
      description={<p>The request is closed. Nothing is added to any university.</p>}
      confirmLabel="Reject"
      destructive
      action={() => rejectDomainRequest(requestId)}
      success="Rejected"
    />
  );
}

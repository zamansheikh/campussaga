"use client";

import { Loader2 } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";

import { updateGroup } from "../actions";

/** The join code, which the admin can set to any free 6 letters (no I or O). */
export function JoinCodeEditor({ groupId, joinCode }: { groupId: string; joinCode: string }) {
  const [code, setCode] = useState(joinCode);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();
  const changed = code.trim().toUpperCase() !== joinCode;

  function save() {
    setError(undefined);
    startTransition(async () => {
      const res = await updateGroup(groupId, { joinCode: code });
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success(`Join code is now ${code.trim().toUpperCase()}`);
    });
  }

  return (
    <div className="space-y-1.5">
      <div className="flex gap-2">
        <Input
          aria-label="Join code"
          value={code}
          maxLength={6}
          onChange={(e) => setCode(e.target.value.toUpperCase().replace(/[^A-Z]/g, ""))}
          className="h-9 w-32 font-mono text-lg tracking-widest uppercase"
        />
        <Button size="sm" onClick={save} disabled={!changed || code.length !== 6 || pending}>
          {pending ? <Loader2 className="animate-spin" /> : null}
          Save
        </Button>
      </div>
      {error ? (
        <p role="alert" className="text-xs text-destructive">
          {error}
        </p>
      ) : (
        <p className="text-xs text-muted-foreground">6 letters, no I or O. Old invites stop working.</p>
      )}
    </div>
  );
}

/** Keep a published routine when its last member leaves (else it's deleted then). */
export function KeepWhenEmpty({ groupId, keep }: { groupId: string; keep: boolean }) {
  const [pending, startTransition] = useTransition();
  return (
    <label className="flex items-start gap-3 text-sm">
      <Switch
        checked={keep}
        disabled={pending}
        onCheckedChange={(on) =>
          startTransition(async () => {
            const res = await updateGroup(groupId, { keepWhenEmpty: on });
            if (!res.ok) toast.error(res.error);
            else toast.success(on ? "Kept when empty" : "Deleted when its last member leaves");
          })
        }
      />
      <span>
        <span className="font-medium">Keep when empty</span>
        <span className="block text-muted-foreground">
          For an official routine: it stays when the last member leaves.
        </span>
      </span>
    </label>
  );
}

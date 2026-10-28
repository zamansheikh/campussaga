"use client";

import { Loader2, Trash2, UserMinus, UserPlus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";
import { type PickedUser, UserPicker } from "@/components/admin/user-picker";
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

import { addRep, deleteRoute, removeRep } from "./actions";

/** Names a student as a transport rep: they edit their university's routes in the app. */
export function AddRepDialog({
  universities,
  universityId,
}: {
  universities: UniversityOption[];
  universityId: string | null;
}) {
  const [open, setOpen] = useState(false);
  const [user, setUser] = useState<PickedUser>();
  const [uni, setUni] = useState<string | null>(universityId);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function reset() {
    setUser(undefined);
    setUni(universityId);
    setError(undefined);
  }

  function submit() {
    if (!user || !uni) return;
    setError(undefined);
    startTransition(async () => {
      const res = await addRep(user.id, uni);
      if (res.ok) {
        toast.success("Transport rep added");
        setOpen(false);
        reset();
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
        if (!o) reset();
      }}
    >
      <DialogTrigger asChild>
        <Button variant="outline">
          <UserPlus /> Add rep
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Add a transport rep</DialogTitle>
          <DialogDescription>
            They keep their student account and can add and change this university&apos;s bus routes, stops and times in the
            app.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
          <div className="space-y-2">
            <Label htmlFor="rep-user">Account</Label>
            <UserPicker id="rep-user" value={user} onChange={setUser} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="rep-university">University</Label>
            <UniversityCombobox
              id="rep-university"
              universities={universities}
              value={uni}
              onChange={setUni}
              placeholder="Choose a university"
            />
          </div>
          {error ? (
            <p role="alert" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
              {error}
            </p>
          ) : null}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={pending}>
            Cancel
          </Button>
          <Button onClick={submit} disabled={!user || !uni || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Add
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export function RemoveRepButton({ userId, name }: { userId: string; name: string }) {
  return (
    <ConfirmAction
      trigger={
        <Button variant="ghost" size="sm" aria-label={`Remove ${name} as transport rep`}>
          <UserMinus /> Remove
        </Button>
      }
      title={`Remove ${name} as transport rep?`}
      description={<p>They can no longer change bus routes in the app. The routes they made stay.</p>}
      confirmLabel="Remove"
      destructive
      action={() => removeRep(userId)}
      success="Transport rep removed"
    />
  );
}

export function DeleteRouteButton({ routeId, name, universityId }: { routeId: string; name: string; universityId: string }) {
  const router = useRouter();
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline" className="text-destructive">
          <Trash2 /> Delete
        </Button>
      }
      title={`Delete ${name}?`}
      description={<p>Its stops and timetable go too. Students stop seeing it at once. This can&apos;t be undone.</p>}
      confirmLabel="Delete route"
      destructive
      action={() => deleteRoute(routeId)}
      success="Route deleted"
      onDone={() => router.replace(`/admin/transport?universityId=${universityId}`)}
    />
  );
}

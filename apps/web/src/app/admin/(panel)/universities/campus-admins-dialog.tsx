"use client";

import { Loader2, UserMinus, UserPlus, UserRoundCog } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState, useTransition } from "react";
import { toast } from "sonner";

import { appointCampusAdmin, listCampusAdmins, removeCampusAdmin } from "@/app/admin/(panel)/inbox/actions";
import { ConfirmAction } from "@/components/admin/confirm-action";
import { type PickedUser, UserPicker } from "@/components/admin/user-picker";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import type { CampusAdmin } from "@/lib/admin/types";

/** The university's campus admins: trusted verified students (up to 5) who handle their own university in the app. */
export function CampusAdminsDialog({ universityId, name, defaultOpen = false }: { universityId: string; name: string; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(defaultOpen);
  const [admins, setAdmins] = useState<CampusAdmin[]>();
  const [error, setError] = useState<string>();
  const [picked, setPicked] = useState<PickedUser>();
  const [pending, startTransition] = useTransition();

  const reload = useCallback(async () => {
    const res = await listCampusAdmins(universityId);
    if (res.ok) {
      setAdmins(res.data ?? []);
      setError(undefined);
    } else {
      setError(res.error);
    }
  }, [universityId]);

  useEffect(() => {
    if (!open) return;
    let live = true;
    listCampusAdmins(universityId).then((res) => {
      if (!live) return;
      if (res.ok) {
        setAdmins(res.data ?? []);
        setError(undefined);
      } else {
        setError(res.error);
      }
    });
    return () => {
      live = false;
    };
  }, [open, universityId]);

  function appoint() {
    if (!picked) return;
    startTransition(async () => {
      const res = await appointCampusAdmin(picked.id);
      if (res.ok) {
        toast.success("Campus admin appointed");
        setPicked(undefined);
        await reload();
      } else {
        toast.error(res.error);
      }
    });
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="ghost" size="sm" className="-ms-2 h-7 px-2 text-xs">
          <UserRoundCog /> Campus admins
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Campus admins · {name}</DialogTitle>
          <DialogDescription>
            Verified students of this university, at most 5. They can verify classmates, settle sections and handle reports there, and never see email addresses.
          </DialogDescription>
        </DialogHeader>

        {error ? (
          <p role="alert" className="text-sm text-destructive">
            {error}
          </p>
        ) : !admins ? (
          <p className="flex items-center gap-2 text-sm text-muted-foreground">
            <Loader2 className="size-4 animate-spin" /> Loading…
          </p>
        ) : admins.length === 0 ? (
          <p className="text-sm text-muted-foreground">No campus admin yet.</p>
        ) : (
          <ul className="divide-y rounded-lg border">
            {admins.map((a) => (
              <li key={a.user.id} className="flex items-center justify-between gap-3 px-3 py-2">
                <div className="min-w-0">
                  <Link href={`/admin/users/${a.user.id}`} className="block truncate text-sm font-medium hover:underline">
                    {a.user.name || "No name yet"}
                  </Link>
                  <p className="truncate text-xs text-muted-foreground">{a.user.email}</p>
                </div>
                <ConfirmAction
                  trigger={
                    <Button variant="outline" size="sm">
                      <UserMinus /> Remove
                    </Button>
                  }
                  title={`Remove ${a.user.name || a.user.email} as campus admin?`}
                  description={<p>They stay a verified student but lose the Campus admin tools in the app.</p>}
                  confirmLabel="Remove"
                  destructive
                  action={() => removeCampusAdmin(a.user.id)}
                  success="Campus admin removed"
                  onDone={reload}
                />
              </li>
            ))}
          </ul>
        )}

        <div className="space-y-2">
          <Label htmlFor={`appoint-${universityId}`}>Appoint a student of this university</Label>
          <UserPicker id={`appoint-${universityId}`} value={picked} onChange={setPicked} universityId={universityId} />
          <Button onClick={appoint} disabled={!picked || pending} className="w-full sm:w-auto">
            {pending ? <Loader2 className="animate-spin" /> : <UserPlus />}
            Appoint
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

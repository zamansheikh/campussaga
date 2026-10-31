"use client";

import { Award, Loader2, UserMinus, UserPlus, UserRoundCog } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState, useTransition } from "react";
import { toast } from "sonner";

import { appointCampusAdmin, listCampusAdmins, removeCampusAdmin } from "@/app/admin/(panel)/inbox/actions";
import { ConfirmAction } from "@/components/admin/confirm-action";
import { type PickedUser, UserPicker } from "@/components/admin/user-picker";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import type { Ambassador, CampusAdmin } from "@/lib/admin/types";

import { getAmbassador } from "./actions";

/**
 * The university's campus admins: trusted verified students (up to 5) who
 * handle their own university in the app. Shows the Campus ambassador (the
 * student who brought the most friends from it), a natural pick.
 */
export function CampusAdminsDialog({
  universityId,
  name,
  defaultOpen = false,
  ambassador: listed,
}: {
  universityId: string;
  name: string;
  defaultOpen?: boolean;
  /** From the universities list, when the API sends it there. */
  ambassador?: Ambassador | null;
}) {
  const [open, setOpen] = useState(defaultOpen);
  const [admins, setAdmins] = useState<CampusAdmin[]>();
  const [fetched, setFetched] = useState<Ambassador | null>();
  const ambassador = listed ?? fetched ?? null;
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
    if (!open || listed !== undefined) return;
    let live = true;
    // Only shown when the server has it; any error just leaves it out.
    getAmbassador(universityId).then((res) => {
      if (live) setFetched(res.ok ? (res.data ?? null) : null);
    });
    return () => {
      live = false;
    };
  }, [open, listed, universityId]);

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

  function appoint(userId: string | undefined = picked?.id) {
    if (!userId) return;
    startTransition(async () => {
      const res = await appointCampusAdmin(userId);
      if (res.ok) {
        toast.success("Campus admin appointed");
        setPicked(undefined);
        await reload();
      } else {
        toast.error(res.error);
      }
    });
  }

  const ambassadorIsAdmin = Boolean(ambassador && admins?.some((a) => a.user.id === ambassador.id));

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

        {ambassador ? (
          <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-muted/40 px-3 py-2">
            <div className="min-w-0">
              <p className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <Award className="size-3.5" aria-hidden /> Campus ambassador
              </p>
              <Link href={`/admin/users/${ambassador.id}`} className="block truncate text-sm font-medium hover:underline">
                {ambassador.name || "No name yet"}
              </Link>
              <p className="truncate text-xs text-muted-foreground">
                {ambassador.email} · brought {ambassador.invites} {ambassador.invites === 1 ? "friend" : "friends"} from this university
              </p>
            </div>
            {ambassadorIsAdmin ? (
              <span className="text-xs text-muted-foreground">Already a campus admin</span>
            ) : (
              <Button variant="outline" size="sm" onClick={() => appoint(ambassador.id)} disabled={pending || !admins}>
                {pending ? <Loader2 className="animate-spin" /> : <UserPlus />}
                Make campus admin
              </Button>
            )}
          </div>
        ) : null}

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
          <Button onClick={() => appoint()} disabled={!picked || pending} className="w-full sm:w-auto">
            {pending ? <Loader2 className="animate-spin" /> : <UserPlus />}
            Appoint
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

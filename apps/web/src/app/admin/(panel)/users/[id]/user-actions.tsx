"use client";

import { Ban, Bell, Building2, Loader2, ShieldCheck, ShieldOff, Trash2, UserCheck, UserX } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { deleteUser, updateUser, type UserPatch } from "@/app/admin/(panel)/users/actions";
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
import type { AdminUserDetail } from "@/lib/admin/types";

export function UserActions({
  user,
  isSelf,
  universities,
}: {
  user: AdminUserDetail;
  isSelf: boolean;
  universities: UniversityOption[];
}) {
  const router = useRouter();
  const name = user.displayName || user.email;
  const patch = (p: UserPatch) => () => updateUser(user.id, p);

  return (
    <div className="flex flex-col gap-2">
      {user.verified ? (
        <ConfirmAction
          trigger={
            <Button variant="outline" className="justify-start">
              <UserX /> Remove verification
            </Button>
          }
          title={`Remove ${name}'s verification?`}
          description={<p>They will show as not verified until they verify a university email again.</p>}
          confirmLabel="Remove verification"
          action={patch({ verified: false })}
          success="Verification removed"
        />
      ) : (
        <ConfirmAction
          trigger={
            <Button variant="outline" className="justify-start" disabled={!user.university}>
              <UserCheck /> Verify by hand
            </Button>
          }
          title={`Verify ${name} by hand?`}
          description={
            <p>
              Only do this when you are sure they study at <strong>{user.university?.name}</strong> (for example, they
              sent proof by email). They will show as verified to their classmates.
            </p>
          }
          confirmLabel="Verify"
          action={patch({ verified: true })}
          success="Marked as verified"
        />
      )}
      {!user.verified && !user.university ? (
        <p className="text-xs text-muted-foreground">Choose a university before verifying by hand.</p>
      ) : null}

      <ChangeUniversity user={user} universities={universities} />

      <Button variant="outline" className="justify-start" asChild>
        <Link href={`/admin/push?userId=${user.id}`}>
          <Bell /> Send a push
        </Link>
      </Button>

      {user.role === "admin" ? (
        <ConfirmAction
          trigger={
            <Button variant="outline" className="justify-start" disabled={isSelf}>
              <ShieldOff /> Make student
            </Button>
          }
          title={`Remove ${name}'s admin access?`}
          description={<p>They lose access to this panel at once.</p>}
          confirmLabel="Make student"
          action={patch({ role: "student" })}
          success="Admin access removed"
        />
      ) : (
        <ConfirmAction
          trigger={
            <Button variant="outline" className="justify-start">
              <ShieldCheck /> Make admin
            </Button>
          }
          title={`Make ${name} an admin?`}
          description={
            <p>
              Admins can see and change every account, university, class group and setting, and send pushes to
              everyone. Only give this to Campus Saga staff.
            </p>
          }
          confirmLabel="Make admin"
          action={patch({ role: "admin" })}
          success="Now an admin"
        />
      )}

      {user.blockedAt ? (
        <ConfirmAction
          trigger={
            <Button variant="outline" className="justify-start">
              <Ban /> Unblock
            </Button>
          }
          title={`Unblock ${name}?`}
          description={<p>They can sign in again.</p>}
          confirmLabel="Unblock"
          action={patch({ blocked: false })}
          success="Unblocked"
        />
      ) : (
        <ConfirmAction
          trigger={
            <Button variant="outline" className="justify-start text-destructive" disabled={isSelf}>
              <Ban /> Block
            </Button>
          }
          title={`Block ${name}?`}
          description={<p>They are signed out on every device at once and can&apos;t sign in until unblocked.</p>}
          confirmLabel="Block"
          destructive
          action={patch({ blocked: true })}
          success="Blocked"
        />
      )}

      <ConfirmAction
        trigger={
          <Button variant="destructive" className="justify-start" disabled={isSelf}>
            <Trash2 /> Delete account
          </Button>
        }
        title={`Delete ${name}'s account?`}
        description={
          <>
            <p>
              This permanently deletes the account like &quot;Delete account&quot; in the app: profile, sessions,
              memberships, personal classes and push tokens. If they are a group&apos;s only CR, the role passes on.
            </p>
            <p>This can&apos;t be undone.</p>
          </>
        }
        confirmLabel="Delete account"
        destructive
        typeToConfirm={user.email}
        action={() => deleteUser(user.id)}
        success="Account deleted"
        onDone={() => router.push("/admin/users")}
      />
      {isSelf ? <p className="text-xs text-muted-foreground">You can&apos;t block, demote or delete yourself.</p> : null}
    </div>
  );
}

function ChangeUniversity({ user, universities }: { user: AdminUserDetail; universities: UniversityOption[] }) {
  const [open, setOpen] = useState(false);
  const [value, setValue] = useState<string | null>(user.university?.id ?? null);
  const [pending, startTransition] = useTransition();
  const changed = value !== (user.university?.id ?? null);

  function save() {
    startTransition(async () => {
      const res = await updateUser(user.id, { universityId: value });
      if (res.ok) {
        toast.success("University changed");
        setOpen(false);
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
        if (o) setValue(user.university?.id ?? null);
      }}
    >
      <DialogTrigger asChild>
        <Button variant="outline" className="justify-start">
          <Building2 /> Change university
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Change university</DialogTitle>
          <DialogDescription>
            {user.verified
              ? "This student is verified with a university email. Moving them may remove their verification; the server decides."
              : "Not verified students choose their university themselves; fix it here if they picked the wrong one."}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor="user-university">University</Label>
          <UniversityCombobox
            id="user-university"
            universities={universities}
            value={value}
            onChange={setValue}
            allowClear={!user.verified}
          />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={pending}>
            Cancel
          </Button>
          <Button onClick={save} disabled={!changed || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Save
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

"use client";

import { Landmark, Loader2, Plus, ShieldHalf } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { StaffKind } from "@/lib/admin/types";
import { cn } from "@/lib/utils";

import { addStaff } from "./actions";

const kinds: { value: StaffKind; label: string; hint: string; icon: typeof Landmark }[] = [
  {
    value: "authority",
    label: "University official",
    hint: "Replies officially and changes issue status in the app, for one university. Their title and name are public.",
    icon: Landmark,
  },
  {
    value: "moderator",
    label: "Moderator",
    hint: "Reviews held and reported posts in this panel. Can't see who wrote anything.",
    icon: ShieldHalf,
  },
];

export function AddStaffDialog({ universities }: { universities: UniversityOption[] }) {
  const [open, setOpen] = useState(false);
  const [user, setUser] = useState<PickedUser>();
  const [kind, setKind] = useState<StaffKind>("authority");
  const [universityId, setUniversityId] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  const ready = Boolean(user) && (kind === "moderator" || (universityId && title.trim().length >= 2));

  function reset() {
    setUser(undefined);
    setKind("authority");
    setUniversityId(null);
    setTitle("");
    setError(undefined);
  }

  function submit() {
    if (!user) return;
    setError(undefined);
    startTransition(async () => {
      const res = await addStaff(
        kind === "authority"
          ? { kind, userId: user.id, universityId: universityId ?? "", title }
          : { kind, userId: user.id, universityId, title },
      );
      if (res.ok) {
        toast.success(kind === "authority" ? "Official added" : "Moderator added");
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
        <Button>
          <Plus /> Add staff
        </Button>
      </DialogTrigger>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Add staff</DialogTitle>
          <DialogDescription>
            They sign in with their own account. Pick it, then choose what they do.
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4">
          <div className="space-y-2">
            <Label htmlFor="staff-user">Account</Label>
            <UserPicker id="staff-user" value={user} onChange={setUser} />
          </div>

          <fieldset className="space-y-2">
            <legend className="mb-2 text-sm font-medium">Role</legend>
            <div className="grid gap-2">
              {kinds.map((k) => (
                <label
                  key={k.value}
                  className={cn(
                    "flex cursor-pointer items-start gap-3 rounded-lg border p-3 transition-colors",
                    "has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-ring",
                    kind === k.value ? "border-primary bg-primary-soft/40" : "hover:bg-muted/50",
                  )}
                >
                  <input
                    type="radio"
                    name="staff-kind"
                    value={k.value}
                    checked={kind === k.value}
                    onChange={() => setKind(k.value)}
                    className="sr-only"
                  />
                  <k.icon className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden />
                  <span>
                    <span className="block text-sm font-medium">{k.label}</span>
                    <span className="block text-xs text-muted-foreground">{k.hint}</span>
                  </span>
                </label>
              ))}
            </div>
          </fieldset>

          <div className="space-y-2">
            <Label htmlFor="staff-university">
              University{kind === "moderator" ? " (optional: leave empty for all universities)" : ""}
            </Label>
            <UniversityCombobox
              id="staff-university"
              universities={universities}
              value={universityId}
              onChange={setUniversityId}
              placeholder={kind === "moderator" ? "All universities" : "Choose a university"}
              allowClear
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="staff-title">
              Public title{kind === "moderator" ? " (optional)" : ""}
            </Label>
            <Input
              id="staff-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={80}
              placeholder={kind === "authority" ? "e.g. Proctor Office" : "e.g. VarsityKotha team"}
              autoComplete="off"
            />
            {kind === "authority" ? (
              <p className="text-xs text-muted-foreground">Shown with their official replies and status changes.</p>
            ) : null}
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
          <Button onClick={submit} disabled={!ready || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Add
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

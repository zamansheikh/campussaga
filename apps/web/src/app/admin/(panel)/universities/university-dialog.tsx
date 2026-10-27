"use client";

import { Loader2, Pencil, Plus, X } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
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
import { Switch } from "@/components/ui/switch";
import type { AdminUniversity } from "@/lib/admin/types";

import { createUniversity, setDomains, updateUniversity } from "./actions";

const NONE = "none";

/** Create (no `university`) or edit a university. */
export function UniversityDialog({ university }: { university?: AdminUniversity }) {
  const editing = Boolean(university);
  const [open, setOpen] = useState(false);
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string>();
  const [kind, setKind] = useState<string>(university?.kind ?? NONE);
  const [active, setActive] = useState(university?.active ?? true);
  const [domains, setDomainList] = useState<string[]>(university?.domains ?? []);

  function submit(form: FormData) {
    const get = (k: string) => String(form.get(k) ?? "");
    const common = {
      name: get("name"),
      nameBn: get("nameBn"),
      city: get("city"),
      kind: (kind === NONE ? "" : kind) as "" | "public" | "private",
      website: get("website"),
    };
    setError(undefined);
    startTransition(async () => {
      if (!university) {
        const res = await createUniversity({ ...common, slug: get("slug"), domains });
        if (!res.ok) return setError(res.error);
        toast.success("University added");
        return setOpen(false);
      }
      // Details and domains are saved separately; only what changed.
      const patch = changes(university, { ...common, active });
      if (Object.keys(patch).length > 0) {
        const res = await updateUniversity(university.id, patch);
        if (!res.ok) return setError(res.error);
      }
      if (domains.join(",") !== university.domains.join(",")) {
        const res = await setDomains(university.id, domains);
        if (!res.ok) return setError(res.error);
      }
      toast.success("University saved");
      setOpen(false);
    });
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(o) => {
        setOpen(o);
        if (o) {
          setError(undefined);
          setKind(university?.kind ?? NONE);
          setActive(university?.active ?? true);
          setDomainList(university?.domains ?? []);
        }
      }}
    >
      <DialogTrigger asChild>
        {editing ? (
          <Button variant="ghost" size="icon-sm" aria-label={`Edit ${university?.name}`}>
            <Pencil />
          </Button>
        ) : (
          <Button>
            <Plus /> Add university
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{editing ? "Edit university" : "Add university"}</DialogTitle>
          <DialogDescription>
            {editing
              ? "Changes show in the app's university list right away."
              : "Students can pick it at once; students with one of its email domains are verified automatically."}
          </DialogDescription>
        </DialogHeader>
        <form action={submit} className="grid gap-4">
          {!editing ? (
            <Field label="Slug" htmlFor="slug" hint="Short id, e.g. diu. Can't be changed later.">
              <Input id="slug" name="slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" autoComplete="off" />
            </Field>
          ) : null}
          <Field label="Name" htmlFor="name">
            <Input id="name" name="name" required minLength={2} maxLength={120} defaultValue={university?.name} />
          </Field>
          <Field label="Bangla name" htmlFor="nameBn">
            <Input id="nameBn" name="nameBn" lang="bn" maxLength={120} defaultValue={university?.nameBn ?? ""} />
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="City" htmlFor="city">
              <Input id="city" name="city" maxLength={60} defaultValue={university?.city ?? ""} />
            </Field>
            <Field label="Kind" htmlFor="kind">
              <Select value={kind} onValueChange={setKind}>
                <SelectTrigger id="kind" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={NONE}>Not set</SelectItem>
                  <SelectItem value="public">Public</SelectItem>
                  <SelectItem value="private">Private</SelectItem>
                </SelectContent>
              </Select>
            </Field>
          </div>
          <Field label="Website" htmlFor="website" hint="Domain only, e.g. diu.edu.bd">
            <Input id="website" name="website" defaultValue={university?.website ?? ""} autoComplete="off" />
          </Field>
          <Field
            label={`Student email domains${domains.length > 0 ? ` (${domains.length})` : ""}`}
            htmlFor="domain-input"
            hint="Students with these emails are verified. The website above is separate."
          >
            <DomainInput value={domains} onChange={setDomainList} />
          </Field>
          {editing ? (
            <div className="flex items-center justify-between rounded-lg border px-3 py-2.5">
              <div>
                <Label htmlFor="active">Active</Label>
                <p className="text-xs text-muted-foreground">Inactive universities are hidden from the app.</p>
              </div>
              <Switch id="active" checked={active} onCheckedChange={setActive} />
            </div>
          ) : null}
          {error ? (
            <p role="alert" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
              {error}
            </p>
          ) : null}
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setOpen(false)} disabled={pending}>
              Cancel
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? <Loader2 className="animate-spin" /> : null}
              {editing ? "Save" : "Add university"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

/** Only the fields that differ from the saved university. */
function changes(
  u: AdminUniversity,
  next: { name: string; nameBn: string; city: string; kind: "" | "public" | "private"; website: string; active: boolean },
) {
  const before = {
    name: u.name,
    nameBn: u.nameBn ?? "",
    city: u.city ?? "",
    kind: u.kind ?? "",
    website: u.website ?? "",
    active: u.active,
  };
  return Object.fromEntries(
    Object.entries(next).filter(([k, v]) => {
      const old = before[k as keyof typeof before];
      return typeof v === "string" ? v.trim() !== String(old).trim() : v !== old;
    }),
  ) as Partial<typeof next>;
}

/** Edit the email domains of a university. */
export function DomainsDialog({ university }: { university: AdminUniversity }) {
  const [open, setOpen] = useState(false);
  const [list, setList] = useState(university.domains);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();
  const changed = list.join(",") !== university.domains.join(",");

  function save() {
    setError(undefined);
    startTransition(async () => {
      const res = await setDomains(university.id, list);
      if (res.ok) {
        toast.success("Domains saved");
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
          setList(university.domains);
          setError(undefined);
        }
      }}
    >
      <DialogTrigger asChild>
        <Button variant="link" size="sm" className="h-auto p-0 text-xs">
          Edit domains
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Email domains · {university.name}</DialogTitle>
          <DialogDescription>
            Students who sign in with an email on these domains are verified students of this university. Free email
            providers and shared suffixes (like ac.bd) are refused.
          </DialogDescription>
        </DialogHeader>
        <DomainInput value={list} onChange={setList} />
        {error ? (
          <p role="alert" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {error}
          </p>
        ) : null}
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={pending}>
            Cancel
          </Button>
          <Button onClick={save} disabled={!changed || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            Save domains
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function DomainInput({ value, onChange }: { value: string[]; onChange: (v: string[]) => void }) {
  const [text, setText] = useState("");
  function add() {
    const items = text
      .split(/[\s,]+/)
      .map((d) => d.trim().toLowerCase().replace(/^@/, ""))
      .filter(Boolean);
    if (items.length === 0) return;
    onChange([...new Set([...value, ...items])]);
    setText("");
  }
  return (
    <div className="space-y-2">
      <div className="flex gap-2">
        <Input
          id="domain-input"
          value={text}
          placeholder="diu.edu.bd"
          autoComplete="off"
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === ",") {
              e.preventDefault();
              add();
            }
          }}
        />
        <Button type="button" variant="outline" onClick={add}>
          Add
        </Button>
      </div>
      {value.length > 0 ? (
        <ul className="flex flex-wrap gap-1.5" aria-label="Domains">
          {value.map((d) => (
            <li key={d}>
              <Badge variant="secondary" className="gap-1 py-1 ps-2.5 pe-1 font-mono text-xs">
                {d}
                <button
                  type="button"
                  className="rounded-full p-0.5 hover:bg-background focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
                  aria-label={`Remove ${d}`}
                  onClick={() => onChange(value.filter((x) => x !== d))}
                >
                  <X className="size-3" />
                </button>
              </Badge>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-xs text-muted-foreground">No domains: students can only pick it (not verified).</p>
      )}
    </div>
  );
}

function Field({
  label,
  htmlFor,
  hint,
  children,
}: {
  label: string;
  htmlFor: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="grid gap-1.5">
      <Label htmlFor={htmlFor}>{label}</Label>
      {children}
      {hint ? <p className="text-xs text-muted-foreground">{hint}</p> : null}
    </div>
  );
}

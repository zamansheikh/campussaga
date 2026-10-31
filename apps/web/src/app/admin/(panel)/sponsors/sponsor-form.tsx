"use client";

import { Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { type AdminSponsor, limits, type SponsorCategory } from "@/lib/admin/sponsors";
import { cn } from "@/lib/utils";

import { saveSponsor } from "./actions";

/** A sponsor's details. The contact and notes are for the team only; students see the name and logo. */
export function SponsorForm({ sponsor, compact = false }: { sponsor?: AdminSponsor; compact?: boolean }) {
  const router = useRouter();
  const [name, setName] = useState(sponsor?.name ?? "");
  const [category, setCategory] = useState<SponsorCategory>(sponsor?.category ?? "general");
  const [website, setWebsite] = useState(sponsor?.website ?? "");
  const [contactName, setContactName] = useState(sponsor?.contactName ?? "");
  const [contactPhone, setContactPhone] = useState(sponsor?.contactPhone ?? "");
  const [contactEmail, setContactEmail] = useState(sponsor?.contactEmail ?? "");
  const [notes, setNotes] = useState(sponsor?.notes ?? "");
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();
  const archived = Boolean(sponsor?.archivedAt);

  function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(undefined);
    startTransition(async () => {
      const res = await saveSponsor(sponsor?.id ?? null, { name, category, website, contactName, contactPhone, contactEmail, notes });
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success(sponsor ? "Sponsor saved" : "Sponsor added");
      if (!sponsor) router.push(`/admin/sponsors/${res.data?.id}`);
      router.refresh();
    });
  }

  return (
    <form onSubmit={submit} className={cn("space-y-6", compact ? "" : "max-w-2xl")}>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Brand</CardTitle>
          <CardDescription>Students see the name and logo on the brand&apos;s ads.</CardDescription>
        </CardHeader>
        <CardContent className={cn("grid gap-4", compact ? "" : "sm:grid-cols-2")}>
          <div className="space-y-2">
            <Label htmlFor="s-name">Name</Label>
            <Input id="s-name" value={name} maxLength={limits.name} onChange={(e) => setName(e.target.value)} disabled={archived} required />
          </div>
          <div className="space-y-2">
            <Label htmlFor="s-website">Website (optional)</Label>
            <Input
              id="s-website"
              type="url"
              inputMode="url"
              placeholder="https://"
              value={website}
              maxLength={limits.website}
              onChange={(e) => setWebsite(e.target.value)}
              disabled={archived}
            />
          </div>
          <fieldset className={cn("space-y-2", compact ? "" : "sm:col-span-2")} disabled={archived}>
            <legend className="mb-2 text-sm font-medium">Category</legend>
            <div role="radiogroup" aria-label="Category" className="grid gap-2 sm:grid-cols-2">
              {(
                [
                  ["general", "General", "Any brand: shops, cafés, telecom, coaching, ed-tech."],
                  ["health", "Health", "Hospitals, clinics and health NGOs. Only these may appear on the blood page."],
                ] as const
              ).map(([v, l, hint]) => (
                <label
                  key={v}
                  className={cn(
                    "flex cursor-pointer gap-3 rounded-xl border p-3 text-sm transition-colors has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-ring",
                    category === v ? "border-primary bg-primary-soft/60" : "hover:bg-muted/50",
                  )}
                >
                  <input type="radio" name="s-category" className="mt-1" checked={category === v} onChange={() => setCategory(v)} />
                  <span>
                    <span className="block font-medium">{l}</span>
                    <span className="block text-xs text-muted-foreground">{hint}</span>
                  </span>
                </label>
              ))}
            </div>
          </fieldset>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Contact</CardTitle>
          <CardDescription>For the team only. Never shown in the app.</CardDescription>
        </CardHeader>
        <CardContent className={cn("grid gap-4", compact ? "" : "sm:grid-cols-3")}>
          <div className="space-y-2">
            <Label htmlFor="s-contact">Contact person</Label>
            <Input id="s-contact" value={contactName} maxLength={limits.contactName} onChange={(e) => setContactName(e.target.value)} disabled={archived} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="s-phone">Phone</Label>
            <Input
              id="s-phone"
              type="tel"
              inputMode="tel"
              value={contactPhone}
              maxLength={limits.contactPhone}
              onChange={(e) => setContactPhone(e.target.value)}
              disabled={archived}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="s-email">Email</Label>
            <Input
              id="s-email"
              type="email"
              inputMode="email"
              value={contactEmail}
              maxLength={limits.contactEmail}
              onChange={(e) => setContactEmail(e.target.value)}
              disabled={archived}
            />
          </div>
          <div className={cn("space-y-2", compact ? "" : "sm:col-span-3")}>
            <div className="flex items-baseline justify-between">
              <Label htmlFor="s-notes">Notes</Label>
              <span className="text-xs text-muted-foreground tabular-nums">
                {notes.length}/{limits.notes}
              </span>
            </div>
            <Textarea
              id="s-notes"
              rows={4}
              value={notes}
              maxLength={limits.notes}
              placeholder="What they paid for, invoices, who to talk to…"
              onChange={(e) => setNotes(e.target.value)}
              disabled={archived}
            />
          </div>
        </CardContent>
      </Card>

      {error ? (
        <p role="alert" className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      ) : null}
      {!archived ? (
        <div className="flex gap-2">
          <Button type="submit" disabled={pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            {sponsor ? "Save" : "Add sponsor"}
          </Button>
          {!sponsor ? (
            <Button type="button" variant="outline" onClick={() => router.back()} disabled={pending}>
              Cancel
            </Button>
          ) : null}
        </div>
      ) : null}
    </form>
  );
}

"use client";

import { Check, Loader2, Pencil, Plus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toast } from "sonner";

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
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { type BusRoute, defaultRouteColor, routeColors } from "@/lib/admin/transport";
import { cn } from "@/lib/utils";

import { createRoute, updateRoute } from "./actions";

/**
 * Adds a route to [universityId], or edits [route]'s name, colour, notes and
 * whether students see it. A new route opens its page for stops and times.
 */
export function RouteDialog({ universityId, route }: { universityId?: string; route?: BusRoute }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(route?.name ?? "");
  const [color, setColor] = useState(route?.color ?? defaultRouteColor);
  const [notes, setNotes] = useState(route?.notes ?? "");
  const [active, setActive] = useState(route?.active ?? true);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function reset() {
    setName(route?.name ?? "");
    setColor(route?.color ?? defaultRouteColor);
    setNotes(route?.notes ?? "");
    setActive(route?.active ?? true);
    setError(undefined);
  }

  function submit() {
    setError(undefined);
    startTransition(async () => {
      const input = { name, color, notes, active };
      const res = route ? await updateRoute(route.id, input) : await createRoute(universityId ?? "", input);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      toast.success(route ? "Route saved" : "Route added");
      setOpen(false);
      if (!route && res.data) router.push(`/admin/transport/${res.data.id}`);
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
        {route ? (
          <Button variant="outline">
            <Pencil /> Edit route
          </Button>
        ) : (
          <Button disabled={!universityId}>
            <Plus /> Add route
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{route ? "Edit route" : "Add a bus route"}</DialogTitle>
          <DialogDescription>
            {route ? "Students see these changes the next time they open Bus routes." : "Add its stops and times on the next page."}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4">
          <div className="space-y-2">
            <Label htmlFor="route-name">Name</Label>
            <Input
              id="route-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              maxLength={60}
              placeholder="e.g. Mirpur 10 – Campus"
              autoComplete="off"
            />
          </div>

          <fieldset className="space-y-2">
            <legend className="mb-2 text-sm font-medium">Colour</legend>
            <div className="flex flex-wrap gap-2">
              {routeColors.map((c) => (
                <label
                  key={c}
                  className={cn(
                    "flex size-9 cursor-pointer items-center justify-center rounded-full ring-offset-2 ring-offset-background",
                    "has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-ring",
                    color === c && "ring-2 ring-foreground",
                  )}
                  style={{ backgroundColor: c }}
                >
                  <input
                    type="radio"
                    name="route-color"
                    value={c}
                    checked={color === c}
                    onChange={() => setColor(c)}
                    className="sr-only"
                    aria-label={c}
                  />
                  {color === c ? <Check className="size-4 text-white" aria-hidden /> : null}
                </label>
              ))}
            </div>
          </fieldset>

          <div className="space-y-2">
            <Label htmlFor="route-notes">Notes (optional)</Label>
            <Textarea
              id="route-notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              maxLength={500}
              rows={3}
              placeholder="e.g. Show your student ID card. No bus on government holidays."
            />
          </div>

          <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
            <div>
              <Label htmlFor="route-active">Show to students</Label>
              <p className="text-xs text-muted-foreground">Turn off to prepare a route before students see it.</p>
            </div>
            <Switch id="route-active" checked={active} onCheckedChange={setActive} />
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
          <Button onClick={submit} disabled={!name.trim() || pending}>
            {pending ? <Loader2 className="animate-spin" /> : null}
            {route ? "Save" : "Add route"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

"use client";

import { Loader2 } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";

import { updateConfig } from "./actions";

const featureNames: Record<string, { label: string; hint: string }> = {
  myClass: { label: "My Class", hint: "Class groups, routine, reminders and announcements (R1)." },
  campusVoice: { label: "Campus Voice", hint: "Anonymous campus issues (R2, not built yet)." },
};

/** One switch per feature flag; each change asks first (it reaches every phone). */
export function FeatureFlags({ features }: { features: Record<string, boolean> }) {
  const [pendingKey, setPendingKey] = useState<string | null>(null);
  const keys = Object.keys(features).sort();
  if (keys.length === 0) return <p className="text-sm text-muted-foreground">No feature flags.</p>;
  return (
    <ul className="divide-y">
      {keys.map((k) => {
        const on = Boolean(features[k]);
        const meta = featureNames[k];
        return (
          <li key={k} className="flex items-center justify-between gap-4 py-3">
            <div>
              <p className="font-medium">
                {meta?.label ?? k} <span className="font-mono text-xs text-muted-foreground">{k}</span>
              </p>
              {meta ? <p className="text-sm text-muted-foreground">{meta.hint}</p> : null}
            </div>
            <Switch
              checked={on}
              aria-label={`${meta?.label ?? k} ${on ? "on" : "off"}`}
              onCheckedChange={() => setPendingKey(k)}
            />
            <ConfirmAction
              open={pendingKey === k}
              onOpenChange={(o) => setPendingKey(o ? k : null)}
              title={`Turn ${meta?.label ?? k} ${on ? "off" : "on"}?`}
              description={
                <p>
                  Every phone picks this up the next time the app starts.
                  {on ? " Students lose access to this feature until it is turned back on." : ""}
                </p>
              }
              confirmLabel={on ? "Turn off" : "Turn on"}
              destructive={on}
              action={() => updateConfig("features", { ...features, [k]: !on })}
              success={`${meta?.label ?? k} is ${on ? "off" : "on"}`}
            />
          </li>
        );
      })}
    </ul>
  );
}

export function MinBuild({ value }: { value: number }) {
  const [next, setNext] = useState(String(value));
  const n = Number(next);
  const valid = Number.isInteger(n) && n >= 1;
  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
      <div className="space-y-1.5">
        <Label htmlFor="min-build">Minimum app build</Label>
        <Input
          id="min-build"
          type="number"
          min={1}
          step={1}
          inputMode="numeric"
          className="w-40"
          value={next}
          onChange={(e) => setNext(e.target.value)}
          aria-invalid={!valid}
        />
      </div>
      <ConfirmAction
        trigger={
          <Button variant="outline" disabled={!valid || n === value}>
            Save
          </Button>
        }
        title={`Require build ${n} or newer?`}
        description={
          <p>
            Phones running an older build ({n > value ? `below ${n}` : "older"}) are blocked with an &quot;Update
            required&quot; screen until they update from the store. Make sure build {n} is live in the stores first.
          </p>
        }
        confirmLabel="Require update"
        destructive={n > value}
        action={() => updateConfig("minSupportedBuild", n)}
        success={`Minimum build is now ${n}`}
      />
    </div>
  );
}

/** Raw JSON editor for any other key. */
export function JsonSetting({ k, value }: { k: string; value: unknown }) {
  const initial = JSON.stringify(value, null, 2);
  const [text, setText] = useState(initial);
  const [pending, startTransition] = useTransition();
  let parsed: unknown;
  let error: string | undefined;
  try {
    parsed = JSON.parse(text);
  } catch (e) {
    error = e instanceof Error ? e.message : "Invalid JSON";
  }
  return (
    <div className="space-y-2">
      <Label htmlFor={`cfg-${k}`} className="font-mono">
        {k}
      </Label>
      <Textarea
        id={`cfg-${k}`}
        value={text}
        onChange={(e) => setText(e.target.value)}
        rows={Math.min(12, Math.max(3, text.split("\n").length))}
        className="font-mono text-xs"
        spellCheck={false}
        aria-invalid={Boolean(error)}
        aria-describedby={error ? `cfg-${k}-error` : undefined}
      />
      {error ? (
        <p id={`cfg-${k}-error`} className="text-xs text-destructive">
          {error}
        </p>
      ) : null}
      <div className="flex gap-2">
        <Button
          size="sm"
          disabled={Boolean(error) || text === initial || pending}
          onClick={() =>
            startTransition(async () => {
              const res = await updateConfig(k, parsed);
              if (res.ok) toast.success(`${k} saved`);
              else toast.error(res.error);
            })
          }
        >
          {pending ? <Loader2 className="animate-spin" /> : null}
          Save
        </Button>
        <Button size="sm" variant="ghost" disabled={text === initial || pending} onClick={() => setText(initial)}>
          Reset
        </Button>
      </div>
    </div>
  );
}

"use client";

import { useOptimistic, useTransition } from "react";
import { toast } from "sonner";

import { Switch } from "@/components/ui/switch";

import { setActive } from "./actions";

export function ActiveSwitch({ id, name, active }: { id: string; name: string; active: boolean }) {
  const [optimistic, setOptimistic] = useOptimistic(active);
  const [pending, startTransition] = useTransition();
  return (
    <Switch
      checked={optimistic}
      disabled={pending}
      aria-label={`${name} active`}
      onCheckedChange={(on) =>
        startTransition(async () => {
          setOptimistic(on);
          const res = await setActive(id, on);
          if (res.ok) toast.success(on ? `${name} is active` : `${name} is hidden from the app`);
          else toast.error(res.error);
        })
      }
    />
  );
}

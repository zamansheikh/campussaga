"use client";

import { Check, ChevronsUpDown, Loader2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { searchUsers } from "@/app/admin/(panel)/users/actions";
import { Button } from "@/components/ui/button";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";

export type PickedUser = { id: string; email: string; displayName: string | null };

/** Find one user by email or name (admins only: it uses /admin/users). */
export function UserPicker({
  value,
  onChange,
  id,
}: {
  value: PickedUser | undefined;
  onChange: (u: PickedUser) => void;
  id?: string;
}) {
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [results, setResults] = useState<PickedUser[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const term = q.trim();
    if (term.length < 2) return;
    let live = true;
    const t = setTimeout(async () => {
      setLoading(true);
      const res = await searchUsers(term);
      if (!live) return;
      setLoading(false);
      if (res.ok) setResults(res.data ?? []);
      else toast.error(res.error);
    }, 250);
    return () => {
      live = false;
      clearTimeout(t);
    };
  }, [q]);

  const shown = q.trim().length < 2 ? [] : results;

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          id={id}
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className="w-full justify-between font-normal"
        >
          <span className={cn("truncate", !value && "text-muted-foreground")}>
            {value ? `${value.displayName || value.email} · ${value.email}` : "Find a user by email or name"}
          </span>
          <ChevronsUpDown className="opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-(--radix-popover-trigger-width) min-w-80 p-0" align="start">
        <Command shouldFilter={false}>
          <CommandInput placeholder="Type at least 2 letters…" value={q} onValueChange={setQ} />
          <CommandList>
            {loading ? (
              <div className="flex items-center justify-center py-6 text-sm text-muted-foreground">
                <Loader2 className="me-2 size-4 animate-spin" /> Searching…
              </div>
            ) : (
              <CommandEmpty>{q.trim().length < 2 ? "Type an email or name." : "No user found."}</CommandEmpty>
            )}
            <CommandGroup>
              {shown.map((u) => (
                <CommandItem
                  key={u.id}
                  value={u.id}
                  onSelect={() => {
                    onChange(u);
                    setOpen(false);
                  }}
                >
                  <Check className={cn("size-4", u.id === value?.id ? "opacity-100" : "opacity-0")} />
                  <span className="min-w-0">
                    <span className="block truncate">{u.displayName || "No name yet"}</span>
                    <span className="block truncate text-xs text-muted-foreground">{u.email}</span>
                  </span>
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}

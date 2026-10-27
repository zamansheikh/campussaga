"use client";

import { Check, ChevronsUpDown, X } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";

export type UniversityOption = { id: string; slug: string; name: string };

/** Searchable university picker (by name or slug). */
export function UniversityCombobox({
  universities,
  value,
  onChange,
  placeholder = "Choose a university",
  allowClear = false,
  id,
}: {
  universities: UniversityOption[];
  value: string | null;
  onChange: (id: string | null) => void;
  placeholder?: string;
  allowClear?: boolean;
  id?: string;
}) {
  const [open, setOpen] = useState(false);
  const selected = universities.find((u) => u.id === value);
  return (
    <div className="flex gap-1">
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            id={id}
            variant="outline"
            role="combobox"
            aria-expanded={open}
            className="min-w-0 flex-1 justify-between font-normal"
          >
            <span className={cn("truncate", !selected && "text-muted-foreground")}>
              {selected ? selected.name : placeholder}
            </span>
            <ChevronsUpDown className="opacity-50" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-(--radix-popover-trigger-width) min-w-72 p-0" align="start">
          <Command
            filter={(itemValue, search) => (itemValue.toLowerCase().includes(search.trim().toLowerCase()) ? 1 : 0)}
          >
            <CommandInput placeholder="Search by name or slug…" />
            <CommandList>
              <CommandEmpty>No university found.</CommandEmpty>
              <CommandGroup>
                {universities.map((u) => (
                  <CommandItem
                    key={u.id}
                    value={`${u.name} ${u.slug}`}
                    onSelect={() => {
                      onChange(u.id);
                      setOpen(false);
                    }}
                  >
                    <Check className={cn("size-4", u.id === value ? "opacity-100" : "opacity-0")} />
                    <span className="truncate">{u.name}</span>
                    <span className="ms-auto text-xs text-muted-foreground">{u.slug}</span>
                  </CommandItem>
                ))}
              </CommandGroup>
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
      {allowClear && selected ? (
        <Button variant="ghost" size="icon" aria-label="Clear university" onClick={() => onChange(null)}>
          <X />
        </Button>
      ) : null}
    </div>
  );
}

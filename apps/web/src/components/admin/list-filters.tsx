"use client";

import { Search, X } from "lucide-react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useEffect, useRef, useState, useTransition } from "react";

import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

type SelectFilter = { name: string; label: string; options: { value: string; label: string }[] };

const ALL = "__all";

/** Search box and filters that live in the URL (?q=, ?status=, …). */
export function ListFilters({
  searchPlaceholder,
  selects = [],
  universities,
}: {
  searchPlaceholder: string;
  selects?: SelectFilter[];
  universities?: UniversityOption[];
}) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [pending, startTransition] = useTransition();
  const [q, setQ] = useState(params.get("q") ?? "");
  const timer = useRef<ReturnType<typeof setTimeout>>(undefined);

  function update(changes: Record<string, string | null>) {
    const next = new URLSearchParams(params.toString());
    for (const [k, v] of Object.entries(changes)) {
      if (v) next.set(k, v);
      else next.delete(k);
    }
    next.delete("page");
    const s = next.toString();
    startTransition(() => router.replace(s ? `${pathname}?${s}` : pathname));
  }

  useEffect(() => () => clearTimeout(timer.current), []);

  const hasFilters = Boolean(params.get("q")) || selects.some((s) => params.get(s.name)) || Boolean(params.get("universityId"));

  return (
    <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-center" aria-busy={pending}>
      <div className="relative sm:w-72">
        <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          type="search"
          aria-label="Search"
          placeholder={searchPlaceholder}
          className="ps-9"
          value={q}
          onChange={(e) => {
            const v = e.target.value;
            setQ(v);
            clearTimeout(timer.current);
            timer.current = setTimeout(() => update({ q: v.trim() || null }), 300);
          }}
        />
      </div>
      {selects.map((s) => (
        <Select
          key={s.name}
          value={params.get(s.name) ?? ALL}
          onValueChange={(v) => update({ [s.name]: v === ALL ? null : v })}
        >
          <SelectTrigger className="sm:w-44" aria-label={s.label}>
            <SelectValue placeholder={s.label} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value={ALL}>All {s.label.toLowerCase()}</SelectItem>
            {s.options.map((o) => (
              <SelectItem key={o.value} value={o.value}>
                {o.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      ))}
      {universities ? (
        <div className="sm:w-64">
          <UniversityCombobox
            universities={universities}
            value={params.get("universityId")}
            onChange={(id) => update({ universityId: id })}
            placeholder="All universities"
            allowClear
          />
        </div>
      ) : null}
      {hasFilters ? (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => {
            setQ("");
            startTransition(() => router.replace(pathname));
          }}
        >
          <X /> Clear
        </Button>
      ) : null}
    </div>
  );
}

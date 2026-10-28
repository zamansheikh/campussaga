"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTransition } from "react";

import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";

/** ?universityId= for the moderation queue (keeps the tab, starts at page 1). */
export function UniversityFilter({ universities }: { universities: UniversityOption[] }) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [pending, startTransition] = useTransition();

  function set(id: string | null) {
    const next = new URLSearchParams(params.toString());
    if (id) next.set("universityId", id);
    else next.delete("universityId");
    next.delete("cursor");
    const s = next.toString();
    startTransition(() => router.replace(s ? `${pathname}?${s}` : pathname));
  }

  return (
    <div className="sm:w-80" aria-busy={pending}>
      <UniversityCombobox
        universities={universities}
        value={params.get("universityId")}
        onChange={set}
        placeholder="All universities"
        allowClear
      />
    </div>
  );
}

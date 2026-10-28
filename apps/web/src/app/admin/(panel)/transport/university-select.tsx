"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTransition } from "react";

import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";

/** Picks the university whose bus routes are shown (?universityId=); none = all. */
export function UniversitySelect({ universities }: { universities: UniversityOption[] }) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [pending, startTransition] = useTransition();

  return (
    <div className="flex flex-wrap items-center gap-2" aria-busy={pending}>
      <div className="w-full sm:w-80">
        <UniversityCombobox
          id="transport-university"
          universities={universities}
          value={params.get("universityId")}
          onChange={(id) =>
            startTransition(() => router.replace(id ? `${pathname}?universityId=${id}` : pathname))
          }
          placeholder="All universities"
        />
      </div>
      {params.get("universityId") ? (
        <button
          type="button"
          className="text-sm font-medium text-primary underline-offset-4 hover:underline"
          onClick={() => startTransition(() => router.replace(pathname))}
        >
          Show all
        </button>
      ) : null}
    </div>
  );
}

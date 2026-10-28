"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTransition } from "react";

import { UniversityCombobox, type UniversityOption } from "@/components/admin/university-combobox";

/** Picks the university whose bus routes are shown (?universityId=). */
export function UniversitySelect({ universities }: { universities: UniversityOption[] }) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [pending, startTransition] = useTransition();

  return (
    <div className="sm:w-80" aria-busy={pending}>
      <UniversityCombobox
        id="transport-university"
        universities={universities}
        value={params.get("universityId")}
        onChange={(id) =>
          startTransition(() => router.replace(id ? `${pathname}?universityId=${id}` : pathname))
        }
        placeholder="Choose a university"
      />
    </div>
  );
}

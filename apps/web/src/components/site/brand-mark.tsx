import { GraduationCap } from "lucide-react";

import { cn } from "@/lib/utils";

/** The teal graduation-cap mark, as in the app. */
export function BrandMark({ className }: { className?: string }) {
  return (
    <span
      aria-hidden
      className={cn(
        "inline-flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground",
        className,
      )}
    >
      <GraduationCap className="size-5" />
    </span>
  );
}

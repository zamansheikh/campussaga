import { cn } from "@/lib/utils";

/** A sponsor's logo in a circle, or its initials. */
export function SponsorLogo({ url, name, className }: { url?: string | null; name: string; className?: string }) {
  const initials =
    name
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((w) => w[0]?.toUpperCase() ?? "")
      .join("") || "?";
  return url ? (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={url} alt="" className={cn("size-9 shrink-0 rounded-full border bg-white object-contain", className)} />
  ) : (
    <span
      aria-hidden
      className={cn("inline-flex size-9 shrink-0 items-center justify-center rounded-full bg-primary-soft text-xs font-semibold text-primary-soft-foreground", className)}
    >
      {initials}
    </span>
  );
}

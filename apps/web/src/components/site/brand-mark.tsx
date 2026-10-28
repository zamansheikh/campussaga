import { brandColors, brandPaths } from "@/lib/brand";
import { cn } from "@/lib/utils";

/** The VarsityKotha mark (ক in a speech bubble), as in the app icon. */
export function BrandMark({ className }: { className?: string }) {
  return (
    <span
      aria-hidden
      className={cn("inline-flex size-8 shrink-0 overflow-hidden rounded-[23%] shadow-sm", className)}
      style={{
        background: `linear-gradient(160deg, ${brandColors.tileFrom} 0%, ${brandColors.tileVia} 48%, ${brandColors.tileTo} 100%)`,
      }}
    >
      <svg viewBox="0 0 1024 1024" className="size-full">
        <path d={brandPaths.bubble} fill="#fff" />
        <path d={brandPaths.ka} fill={brandColors.ink} />
      </svg>
    </span>
  );
}

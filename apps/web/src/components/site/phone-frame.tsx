import Image, { type StaticImageData } from "next/image";

import { cn } from "@/lib/utils";

/**
 * A phone showing one app screen (src/assets/screens, rendered from the app by
 * tool/store/build.sh). The screens have no status bar, so one is drawn here.
 * `crop` shows only the top of the phone and fades it out, for compact rows.
 */
export function PhoneFrame({
  src,
  alt,
  className,
  crop = false,
  eager = false,
  dark = false,
}: {
  src: StaticImageData;
  alt: string;
  className?: string;
  crop?: boolean;
  eager?: boolean;
  /** The screen is in the app's dark theme. */
  dark?: boolean;
}) {
  return (
    <div
      className={cn(
        "relative shrink-0",
        crop && "max-h-[30rem] overflow-hidden [mask-image:linear-gradient(to_bottom,black_70%,transparent)]",
        className,
      )}
    >
      <div className="rounded-[2.6rem] bg-[#0a0f1a] p-[0.55rem] shadow-[0_30px_60px_-20px_rgba(4,47,46,0.55),0_0_0_1px_rgba(255,255,255,0.06)_inset]">
        <div className={cn("overflow-hidden rounded-[2.1rem]", dark ? "bg-[#0b1220]" : "bg-[#f8fafc]")}>
          <div
            aria-hidden
            className={cn(
              "flex h-7 items-center justify-between px-6 text-[0.7rem] font-semibold",
              dark ? "text-slate-100" : "text-slate-900",
            )}
          >
            <span>10:05</span>
            <span className="size-2.5 rounded-full bg-black ring-1 ring-white/10" />
            <span className="flex items-center gap-1">
              <SignalIcon />
              <BatteryIcon />
            </span>
          </div>
          <Image
            src={src}
            alt={alt}
            unoptimized
            loading={eager ? "eager" : "lazy"}
            fetchPriority={eager ? "high" : "auto"}
            className="block h-auto w-full"
          />
        </div>
      </div>
    </div>
  );
}

function SignalIcon() {
  return (
    <svg viewBox="0 0 16 12" className="h-2.5 w-auto" fill="currentColor">
      <rect x="0" y="8" width="3" height="4" rx="0.5" />
      <rect x="4.3" y="5.5" width="3" height="6.5" rx="0.5" />
      <rect x="8.6" y="3" width="3" height="9" rx="0.5" />
      <rect x="12.9" y="0" width="3" height="12" rx="0.5" />
    </svg>
  );
}

function BatteryIcon() {
  return (
    <svg viewBox="0 0 26 12" className="h-2.5 w-auto">
      <rect x="0.75" y="0.75" width="21.5" height="10.5" rx="3" fill="none" stroke="currentColor" strokeWidth="1.5" />
      <rect x="3" y="3" width="15" height="6" rx="1.5" fill="currentColor" />
      <rect x="23.5" y="4" width="2" height="4" rx="1" fill="currentColor" />
    </svg>
  );
}

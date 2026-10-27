import Link from "next/link";

import { BrandMark } from "@/components/site/brand-mark";
import { ThemeToggle } from "@/components/theme-toggle";
import { site } from "@/lib/site";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-30 border-b bg-background/80 backdrop-blur supports-[backdrop-filter]:bg-background/70">
      <div className="mx-auto flex h-16 max-w-5xl items-center justify-between gap-2 px-4">
        <Link href="/" className="flex shrink-0 items-center gap-2 font-semibold tracking-tight whitespace-nowrap">
          <BrandMark />
          <span className="text-base sm:text-lg">{site.name}</span>
        </Link>
        <nav aria-label="Main" className="flex items-center text-[13px] whitespace-nowrap sm:gap-2 sm:text-sm">
          <Link href="/privacy" className="rounded-md px-1.5 py-1.5 text-muted-foreground hover:text-foreground sm:px-3">
            Privacy
          </Link>
          <Link
            href="/delete-account"
            className="rounded-md px-1.5 py-1.5 text-muted-foreground hover:text-foreground sm:px-3"
          >
            Delete account
          </Link>
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}

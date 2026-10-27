import Link from "next/link";

import { site } from "@/lib/site";

export function SiteFooter() {
  return (
    <footer className="border-t">
      <div className="mx-auto flex max-w-5xl flex-col gap-2 px-4 py-8 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
        <p>
          Made by{" "}
          <a href={site.company.url} className="font-medium text-foreground hover:underline">
            {site.company.name}
          </a>
        </p>
        <nav aria-label="Footer" className="flex flex-wrap gap-x-4 gap-y-1">
          <Link href="/privacy" className="hover:text-foreground">
            Privacy policy
          </Link>
          <Link href="/delete-account" className="hover:text-foreground">
            Delete your account
          </Link>
          <a href={`mailto:${site.supportEmail}`} className="hover:text-foreground">
            {site.supportEmail}
          </a>
        </nav>
      </div>
    </footer>
  );
}

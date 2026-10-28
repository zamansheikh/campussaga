import type { Metadata } from "next";
import Link from "next/link";

import { MobileNav } from "@/components/admin/mobile-nav";
import { homeFor } from "@/components/admin/nav";
import { SidebarNav } from "@/components/admin/sidebar-nav";
import { UserMenu } from "@/components/admin/user-menu";
import { BrandMark } from "@/components/site/brand-mark";
import { ThemeToggle } from "@/components/theme-toggle";
import { getAdmin } from "@/lib/admin/session";

export const metadata: Metadata = {
  title: { default: "Admin", template: "%s · Admin — VarsityKotha" },
  robots: { index: false, follow: false },
};

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const me = await getAdmin();
  return (
    <div className="flex min-h-dvh">
      <aside className="sticky top-0 hidden h-dvh w-64 shrink-0 flex-col border-r bg-sidebar p-4 lg:flex">
        <Link href={homeFor(me.role)} className="mb-6 flex items-center gap-2.5 px-2 font-semibold">
          <BrandMark />
          <span>
            VarsityKotha
            <span className="block text-xs font-normal text-muted-foreground">
              {me.role === "admin" ? "Superadmin" : "Moderator"}
            </span>
          </span>
        </Link>
        <SidebarNav role={me.role} />
        <p className="mt-auto px-2 text-xs text-muted-foreground">Every change is recorded in the audit log.</p>
      </aside>
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-20 flex h-14 items-center gap-2 border-b bg-background/80 px-4 backdrop-blur">
          <MobileNav role={me.role} />
          <Link href={homeFor(me.role)} className="flex items-center gap-2 font-semibold lg:hidden">
            <BrandMark className="size-7" />
            <span className="sr-only sm:not-sr-only">Admin</span>
          </Link>
          <div className="ms-auto flex items-center gap-1">
            <ThemeToggle />
            <UserMenu me={me} />
          </div>
        </header>
        <main id="main" className="mx-auto w-full max-w-7xl flex-1 px-4 py-6 sm:px-6">
          {children}
        </main>
      </div>
    </div>
  );
}

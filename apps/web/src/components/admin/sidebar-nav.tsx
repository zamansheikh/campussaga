"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { navFor } from "@/components/admin/nav";
import type { NavCounts } from "@/components/admin/nav";
import type { PanelRole } from "@/lib/admin/types";
import { cn } from "@/lib/utils";

export function SidebarNav({ role, onNavigate, counts = {} }: { role: PanelRole; onNavigate?: () => void; counts?: NavCounts }) {
  const pathname = usePathname();
  return (
    <nav aria-label="Admin" className="flex flex-col gap-1">
      {navFor(role).map(({ href, label, icon: Icon, badge }) => {
        const active = href === "/admin" ? pathname === "/admin" : pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            onClick={onNavigate}
            aria-current={active ? "page" : undefined}
            className={cn(
              "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-sidebar-foreground/80 transition-colors",
              "hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground",
              active && "bg-sidebar-accent text-sidebar-accent-foreground",
            )}
          >
            <Icon className="size-4" aria-hidden />
            {label}
            {badge && (counts[badge] ?? 0) > 0 ? (
              <span className="ms-auto rounded-full bg-primary px-2 py-0.5 text-xs font-semibold text-primary-foreground tabular-nums">
                <span className="sr-only">{counts[badge]} open: </span>
                {(counts[badge] ?? 0) > 99 ? "99+" : counts[badge]}
              </span>
            ) : null}
          </Link>
        );
      })}
    </nav>
  );
}

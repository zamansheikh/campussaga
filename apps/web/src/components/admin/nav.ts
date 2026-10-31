import {
  Bell,
  Building2,
  Bus,
  Droplet,
  MessageSquareText,
  Inbox,
  LayoutDashboard,
  ScrollText,
  Settings,
  ShieldCheck,
  ShieldHalf,
  Users,
  UsersRound,
} from "lucide-react";

import type { PanelRole } from "@/lib/admin/types";

type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string; "aria-hidden"?: boolean }>;
  /** Who sees it; admins see everything. */
  roles: readonly PanelRole[];
  /** Shows the "needs attention" count next to the label. */
  badge?: "attention" | "feedback";
};

const ADMIN = ["admin"] as const;
const STAFF = ["admin", "moderator"] as const;

export const adminNav: readonly NavItem[] = [
  { href: "/admin/inbox", label: "Needs attention", icon: Inbox, roles: ADMIN, badge: "attention" },
  { href: "/admin", label: "Dashboard", icon: LayoutDashboard, roles: ADMIN },
  { href: "/admin/moderation", label: "Moderation", icon: ShieldHalf, roles: STAFF },
  { href: "/admin/users", label: "Users", icon: Users, roles: ADMIN },
  { href: "/admin/universities", label: "Universities", icon: Building2, roles: ADMIN },
  { href: "/admin/groups", label: "Class groups", icon: UsersRound, roles: ADMIN },
  { href: "/admin/transport", label: "Bus routes", icon: Bus, roles: ADMIN },
  { href: "/admin/blood", label: "Blood donation", icon: Droplet, roles: ADMIN },
  { href: "/admin/feedback", label: "Feedback", icon: MessageSquareText, roles: ADMIN, badge: "feedback" },
  { href: "/admin/staff", label: "Staff", icon: ShieldCheck, roles: ADMIN },
  { href: "/admin/push", label: "Push", icon: Bell, roles: ADMIN },
  { href: "/admin/settings", label: "Settings", icon: Settings, roles: ADMIN },
  { href: "/admin/audit", label: "Audit log", icon: ScrollText, roles: ADMIN },
];

/** Counts shown next to nav items. */
export type NavCounts = Partial<Record<"attention" | "feedback", number>>;

/** The menu for a role. */
export function navFor(role: PanelRole): readonly NavItem[] {
  return adminNav.filter((i) => i.roles.includes(role));
}

/** Where a role lands after signing in or opening /admin. */
export function homeFor(role: PanelRole): string {
  return role === "admin" ? "/admin" : "/admin/moderation";
}

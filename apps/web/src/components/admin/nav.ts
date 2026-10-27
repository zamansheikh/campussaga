import { Bell, Building2, LayoutDashboard, ScrollText, Settings, Users, UsersRound } from "lucide-react";

export const adminNav = [
  { href: "/admin", label: "Dashboard", icon: LayoutDashboard },
  { href: "/admin/users", label: "Users", icon: Users },
  { href: "/admin/universities", label: "Universities", icon: Building2 },
  { href: "/admin/groups", label: "Class groups", icon: UsersRound },
  { href: "/admin/push", label: "Push", icon: Bell },
  { href: "/admin/settings", label: "Settings", icon: Settings },
  { href: "/admin/audit", label: "Audit log", icon: ScrollText },
] as const;

import { Badge } from "@/components/ui/badge";
import type { AdminUser } from "@/lib/admin/types";

export function UserBadges({ user }: { user: Pick<AdminUser, "verified" | "role" | "blockedAt"> }) {
  return (
    <span className="flex flex-wrap gap-1">
      {user.blockedAt ? <Badge variant="destructive">Blocked</Badge> : null}
      {user.role === "admin" ? <Badge variant="soft">Admin</Badge> : null}
      {user.verified ? <Badge variant="success">Verified</Badge> : <Badge variant="warning">Not verified</Badge>}
    </span>
  );
}

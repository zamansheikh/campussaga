"use client";

import { UserMinus } from "lucide-react";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";

import { removeStaff } from "./actions";

export function RemoveStaffButton({ userId, name, kind }: { userId: string; name: string; kind: string }) {
  return (
    <ConfirmAction
      trigger={
        <Button variant="ghost" size="sm" aria-label={`Remove ${name} from staff`}>
          <UserMinus /> Remove
        </Button>
      }
      title={`Remove ${name} from staff?`}
      description={
        <p>
          They become a student again{kind === "authority" ? " and can no longer reply officially or change issue status" : " and lose access to this panel"}
          . Their earlier official replies stay.
        </p>
      }
      confirmLabel="Remove"
      destructive
      action={() => removeStaff(userId)}
      success="Removed from staff"
    />
  );
}

"use client";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";

import { endLiveSharing } from "../actions";

/** Ends every open sharing session on the route (a fake or stuck bus), after asking. */
export function EndSharingButton({ routeId, name }: { routeId: string; name: string }) {
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline" size="sm">
          End all sharing
        </Button>
      }
      title={`End all live sharing on ${name}?`}
      description={
        <p>
          Every student sharing this route stops sharing, and the bus disappears from the live map. Their apps treat it
          as stopped. Use this for a fake or stuck bus.
        </p>
      }
      confirmLabel="End all sharing"
      destructive
      action={() => endLiveSharing(routeId)}
      success="Sharing ended"
    />
  );
}

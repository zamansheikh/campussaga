"use client";

import { useState } from "react";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

import { closeBloodRequest } from "./actions";

/** Closes an open request after asking, with an optional reason for the audit log. */
export function CloseRequestButton({ requestId, summary }: { requestId: string; summary: string }) {
  const [reason, setReason] = useState("");
  return (
    <ConfirmAction
      trigger={
        <Button variant="outline" size="sm">
          Close
        </Button>
      }
      title="Close this blood request?"
      description={
        <>
          <p>{summary} will stop showing as open in the app.</p>
          <div className="space-y-1.5">
            <Label htmlFor={`close-reason-${requestId}`}>Reason (optional)</Label>
            <Textarea
              id={`close-reason-${requestId}`}
              value={reason}
              maxLength={300}
              rows={3}
              onChange={(e) => setReason(e.target.value)}
              placeholder="For example: duplicate, or a fake request"
            />
          </div>
        </>
      }
      confirmLabel="Close request"
      destructive
      action={() => closeBloodRequest(requestId, reason)}
      success="Request closed"
      onDone={() => setReason("")}
    />
  );
}

"use client";

import { RotateCcw, Ban } from "lucide-react";
import { useRouter } from "next/navigation";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { ReasonAction } from "@/components/admin/reason-action";
import { Button } from "@/components/ui/button";

import { setInviteDisqualified, setParticipantDisqualified } from "./actions";

/** Disqualify an invite (with a reason) or restore it. */
export function InviteActions({ referredId, referredName, disqualified }: { referredId: string; referredName: string; disqualified: boolean }) {
  const router = useRouter();
  return disqualified ? (
    <ConfirmAction
      trigger={
        <Button variant="outline" size="sm">
          <RotateCcw /> Restore
        </Button>
      }
      title="Restore this invite?"
      description={<p>The invite of {referredName} counts again if it qualifies.</p>}
      confirmLabel="Restore"
      action={() => setInviteDisqualified(referredId, false, "")}
      success="Invite restored"
      onDone={() => router.refresh()}
    />
  ) : (
    <ReasonAction
      trigger={
        <Button variant="outline" size="sm">
          <Ban /> Disqualify
        </Button>
      }
      title="Disqualify this invite?"
      description={<p>The invite of {referredName} stops counting for every campaign. You can restore it later.</p>}
      confirmLabel="Disqualify"
      action={(reason) => setInviteDisqualified(referredId, true, reason)}
      success="Invite disqualified"
    />
  );
}

/** Remove a participant from this campaign (with a reason) or undo it. */
export function ParticipantActions({
  campaignId,
  userId,
  name,
  disqualified,
}: {
  campaignId: string;
  userId: string;
  name: string;
  disqualified: boolean;
}) {
  const router = useRouter();
  return disqualified ? (
    <ConfirmAction
      trigger={
        <Button variant="outline" size="sm">
          <RotateCcw /> Undo
        </Button>
      }
      title="Let this person take part again?"
      description={<p>{name} goes back into this campaign&apos;s standings.</p>}
      confirmLabel="Undo"
      action={() => setParticipantDisqualified(campaignId, userId, false, "")}
      success="Participant restored"
      onDone={() => router.refresh()}
    />
  ) : (
    <ReasonAction
      trigger={
        <Button variant="outline" size="sm">
          <Ban /> Disqualify person
        </Button>
      }
      title="Remove this person from the campaign?"
      description={<p>{name} can&apos;t win this campaign. Their invites still count for other things. You can undo this.</p>}
      confirmLabel="Disqualify"
      action={(reason) => setParticipantDisqualified(campaignId, userId, true, reason)}
      success="Participant disqualified"
    />
  );
}

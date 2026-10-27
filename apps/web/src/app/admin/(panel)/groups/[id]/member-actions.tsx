"use client";

import { MoreHorizontal, Shield, ShieldOff, Trash2, UserMinus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toast } from "sonner";

import { ConfirmAction } from "@/components/admin/confirm-action";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type { GroupMember } from "@/lib/admin/types";

import { deleteGroup, removeMember, setMemberRole } from "../actions";

export function MemberActions({ groupId, member }: { groupId: string; member: GroupMember }) {
  const [pending, startTransition] = useTransition();
  const [confirmRemove, setConfirmRemove] = useState(false);
  const name = member.name || member.email;

  function role(next: "cr" | "member") {
    startTransition(async () => {
      const res = await setMemberRole(groupId, member.userId, next);
      if (res.ok) toast.success(next === "cr" ? `${name} is now a CR` : `${name} is now a member`);
      else toast.error(res.error);
    });
  }

  return (
    <div className="flex justify-end">
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon-sm" aria-label={`Actions for ${name}`} disabled={pending}>
            <MoreHorizontal />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          {member.role === "cr" ? (
            <DropdownMenuItem onSelect={() => role("member")}>
              <ShieldOff /> Make member
            </DropdownMenuItem>
          ) : (
            <DropdownMenuItem onSelect={() => role("cr")}>
              <Shield /> Make CR
            </DropdownMenuItem>
          )}
          <DropdownMenuSeparator />
          <DropdownMenuItem variant="destructive" onSelect={() => setConfirmRemove(true)}>
            <UserMinus /> Remove from group
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
      <ConfirmAction
        open={confirmRemove}
        onOpenChange={setConfirmRemove}
        title={`Remove ${name} from this group?`}
        description={
          <p>
            They stop seeing this routine and its changes. They can rejoin with the join code.
            {member.role === "cr" ? " If they are the only CR, the role passes to the longest member." : ""}
          </p>
        }
        confirmLabel="Remove"
        destructive
        action={() => removeMember(groupId, member.userId)}
        success={`${name} removed`}
      />
    </div>
  );
}

export function DeleteGroup({ groupId, title, joinCode }: { groupId: string; title: string; joinCode: string }) {
  const router = useRouter();
  return (
    <ConfirmAction
      trigger={
        <Button variant="destructive">
          <Trash2 /> Delete group
        </Button>
      }
      title={`Delete ${title}?`}
      description={
        <>
          <p>This deletes the group for every member: its routine, changes and announcements.</p>
          <p>This can&apos;t be undone.</p>
        </>
      }
      confirmLabel="Delete group"
      destructive
      typeToConfirm={joinCode}
      action={() => deleteGroup(groupId)}
      success="Group deleted"
      onDone={() => router.push("/admin/groups")}
    />
  );
}

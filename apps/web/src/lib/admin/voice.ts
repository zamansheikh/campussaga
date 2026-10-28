// Campus Voice words for the panel (docs/CAMPUS_VOICE.md). Shared by server
// pages and client components, so no "server-only" here.

import type { ModerationAction, QueueKind, Visibility } from "@/lib/admin/types";

export const categoryLabel: Record<string, string> = {
  academic: "Academic",
  hostel: "Hostel",
  transport: "Transport",
  facilities: "Facilities",
  safety: "Safety",
  administration: "Administration",
  food: "Food",
  it: "IT / Wi-Fi",
  other: "Other",
};

export const statusLabel: Record<string, string> = {
  open: "Open",
  acknowledged: "Acknowledged",
  in_progress: "In progress",
  solved: "Solved",
  rejected: "Rejected",
};

export type BadgeTone = "outline" | "soft" | "success" | "warning" | "info" | "destructive" | "secondary";

export const statusTone: Record<string, BadgeTone> = {
  open: "info",
  acknowledged: "soft",
  in_progress: "warning",
  solved: "success",
  rejected: "secondary",
};

export const visibilityLabel: Record<string, string> = {
  visible: "Public",
  held: "Held for review",
  hidden: "Hidden",
  removed: "Removed",
};

export const visibilityTone: Record<string, BadgeTone> = {
  visible: "success",
  held: "warning",
  hidden: "secondary",
  removed: "destructive",
};

export const reportReasonLabel: Record<string, string> = {
  spam: "Spam",
  abuse: "Abuse",
  personal_info: "Personal info",
  false_info: "False info",
  inappropriate: "Inappropriate",
  other: "Other",
};

/** Why the automatic check held something (§6). */
export const holdReasonLabel: Record<string, string> = {
  personal_info: "Looks like personal info (phone, email, link or ID number)",
  language: "Matched the word list",
  unverified: "Posted by a not-verified student",
  reports: "Hidden automatically after 5 reports",
  moderator: "Hidden by a moderator",
};

export const actorLabel: Record<string, string> = {
  authority: "University official",
  moderator: "Moderator",
  author: "Author",
  system: "Campus Saga",
};

export const queueTabs: { kind: QueueKind; label: string; hint: string }[] = [
  { kind: "held", label: "Held", hint: "Stopped by the automatic check; nobody else sees them until approved." },
  { kind: "reported", label: "Reported", hint: "Public posts with open reports." },
  { kind: "hidden", label: "Hidden", hint: "Hidden by 5 reports or a moderator." },
  { kind: "private", label: "Safety", hint: "Private safety reports: only moderators and that university's officials see them." },
];

export function isQueueKind(v: string | undefined): v is QueueKind {
  return v === "held" || v === "reported" || v === "hidden" || v === "private";
}

/** The moderation actions that make sense for content in a state. */
export function actionsFor(visibility: Visibility | string): ModerationAction[] {
  switch (visibility) {
    case "held":
      return ["approve", "remove"];
    case "visible":
      return ["hide", "remove"];
    case "hidden":
      return ["restore", "remove"];
    case "removed":
      return ["restore"];
    default:
      return [];
  }
}

export const actionLabel: Record<ModerationAction, string> = {
  approve: "Approve",
  hide: "Hide",
  remove: "Remove",
  restore: "Restore",
};

export const reportStateLabel: Record<string, string> = {
  open: "Open",
  resolved: "Resolved",
  dismissed: "Dismissed",
};

/** A named author's name ("Deleted account" when that account is gone). */
export function authorName(author: { name: string | null } | null): string | null {
  if (!author) return null;
  return author.name ?? "Deleted account";
}

/** "Student 7KQF" for anonymous content. */
export function handleText(handle: string): string {
  return handle ? `Student ${handle}` : "Student";
}

export function label(map: Record<string, string>, key: string): string {
  return map[key] ?? key.replaceAll("_", " ");
}

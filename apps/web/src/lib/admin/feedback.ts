export const feedbackKindLabel: Record<string, string> = { bug: "Bug", idea: "Idea", other: "Other" };
export const feedbackKindTone: Record<string, "destructive" | "info" | "outline"> = { bug: "destructive", idea: "info", other: "outline" };

export const feedbackStatusLabel: Record<string, string> = {
  new: "New",
  seen: "Seen",
  planned: "Planned",
  in_progress: "In progress",
  done: "Done",
  wont_do: "Won't do",
};
export const feedbackStatusTone: Record<string, "warning" | "info" | "soft" | "success" | "outline"> = {
  new: "warning",
  seen: "outline",
  planned: "info",
  in_progress: "soft",
  done: "success",
  wont_do: "outline",
};

/** The proxy address for an attached screenshot (the browser has no token). */
export function feedbackImageSrc(url: string): string {
  return `/admin/feedback-image?src=${encodeURIComponent(url)}`;
}

export function universityName(u: string | { id: string; name: string } | null | undefined): string | null {
  return typeof u === "string" ? u : (u?.name ?? null);
}

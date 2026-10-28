/** An error answer from the Go API: `{"error": {code, message, details}}`. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

const messages: Record<string, string> = {
  NOT_ADMIN: "This account isn't an admin or a moderator.",
  BAD_CURSOR: "That page link has expired. Start again from the first page.",
  CANNOT_CHANGE_SELF: "You can't block, demote or delete your own account.",
  ACCOUNT_BLOCKED: "This account is blocked.",
  LAST_CR: "A class group must keep at least one CR. Make someone else CR first.",
  CR_LIMIT_REACHED: "This group already has the most CRs allowed.",
  SLUG_TAKEN: "Another university already uses this slug.",
  DOMAIN_TAKEN: "Another university already uses one of these email domains.",
  DOMAIN_NOT_ALLOWED: "That domain can't be a university domain (free email providers and shared suffixes like ac.bd aren't allowed).",
  UNIVERSITY_NOT_FOUND: "That university doesn't exist.",
  UNIVERSITY_REQUIRED: "Choose a university first.",
  USER_NOT_FOUND: "That user doesn't exist (maybe already deleted).",
  GROUP_NOT_FOUND: "That class group doesn't exist (maybe already deleted).",
  MEMBER_NOT_FOUND: "That person isn't in this group any more.",
  CONFIG_KEY_UNKNOWN: "That setting doesn't exist.",
  CONFIG_VALUE_INVALID: "That value isn't valid for this setting.",
  EMAIL_IN_USE: "Another account already uses that email.",
  CODE_INVALID: "That code isn't right.",
  CODE_EXPIRED: "That code has expired. Ask for a new one.",
  CODE_TOO_MANY_ATTEMPTS: "Too many wrong codes. Ask for a new one.",
  CODE_RESEND_TOO_SOON: "Please wait a little before asking for another code.",
  CODE_LIMIT_REACHED: "Too many codes requested. Try again later.",
  EMAIL_SEND_FAILED: "We couldn't send the email. Try again in a moment.",
  VALIDATION_FAILED: "Some fields are invalid.",
  TOO_MANY_REQUESTS: "Too many requests. Please wait a moment.",
  UNAUTHORIZED: "Please sign in again.",
  TOKEN_EXPIRED: "Your session expired. Please sign in again.",
  TOKEN_INVALID: "Please sign in again.",
  SESSION_ENDED: "Your session ended. Please sign in again.",
  REFRESH_INVALID: "Your session ended. Please sign in again.",
  FEATURE_DISABLED: "Campus Voice is turned off.",
  VOICE_BANNED: "This account is banned from Campus Voice.",
  ISSUE_NOT_FOUND: "That issue doesn't exist (maybe it was deleted).",
  COMMENT_NOT_FOUND: "That comment doesn't exist (maybe it was deleted).",
  UPLOAD_NOT_FOUND: "That photo doesn't exist.",
  IMAGE_INVALID: "That file isn't a photo we can use.",
  IMAGE_TOO_LARGE: "That photo is too large.",
  PHOTO_NOT_ALLOWED: "The photo check refused this photo.",
  ISSUE_CLOSED: "This issue is closed.",
  ALREADY_REPORTED: "This was already reported.",
  STATUS_CHANGE_INVALID: "That status change isn't allowed.",
  NOTE_REQUIRED: "Add a note explaining why.",
  CANNOT_BAN_OFFICIAL: "Official replies come from university staff; their authors can't be banned here.",
  ROLE_CONFLICT: "Admins can't also be staff. Make them a student first.",
  NOT_FOUND: "Not found.",
  FORBIDDEN: "You don't have access to this.",
  NETWORK: "Can't reach the Campus Saga server. Is it running?",
  INTERNAL_ERROR: "Something went wrong on the server. Try again.",
};

function seconds(n: number) {
  return n < 60 ? `${n} s` : `${Math.ceil(n / 60)} min`;
}

/** Plain-words message for an API error code (with details where they help). */
export function errorMessage(code: string, details?: unknown, fallback?: string): string {
  const d = (details ?? {}) as Record<string, unknown>;
  if (code === "CODE_INVALID" && typeof d.remainingAttempts === "number") {
    const n = d.remainingAttempts;
    return `That code isn't right. ${n} ${n === 1 ? "try" : "tries"} left.`;
  }
  if ((code === "CODE_RESEND_TOO_SOON" || code === "CODE_LIMIT_REACHED" || code === "TOO_MANY_REQUESTS") &&
      typeof d.retryAfterSeconds === "number") {
    return `${messages[code]} (${seconds(d.retryAfterSeconds)})`;
  }
  if (code === "VALIDATION_FAILED" && d.fields && typeof d.fields === "object") {
    const list = Object.entries(d.fields as Record<string, unknown>)
      .map(([k, v]) => `${k}: ${String(v)}`)
      .join("; ");
    if (list) return `Some fields are invalid — ${list}`;
  }
  return messages[code] ?? fallback ?? "Something went wrong. Try again.";
}

/** The result every admin Server Action returns. */
export type ActionResult<T = undefined> = { ok: true; data?: T; message?: string } | { ok: false; error: string };

export function failure(e: unknown): { ok: false; error: string } {
  if (e instanceof ApiError) return { ok: false, error: errorMessage(e.code, e.details, e.message) };
  console.error(e);
  return { ok: false, error: errorMessage("INTERNAL_ERROR") };
}

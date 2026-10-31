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
  INVALID_IMAGE: "That file isn't a photo we can use. Send a JPEG, PNG or WebP.",
  MEDIA_UNAVAILABLE: "Photos can't be stored right now. Try again later.",
  BANNER_NOT_FOUND: "This campaign has no banner.",
  INVALID_PROMO: "Something in this ad isn't valid. Check the fields and the preview.",
  PROMO_NOT_FOUND: "That ad doesn't exist (maybe a deleted draft).",
  SPONSOR_NOT_FOUND: "That sponsor doesn't exist.",
  PROMO_LOCKED: "This can't change in the ad's current status. Pause a live ad to change more than its end, views, times a day and priority; an ended ad can only be duplicated.",
  IMAGE_NOT_FOUND: "There's no image here.",
  HEALTH_SPONSOR_ONLY:
    "The blood page only takes Health sponsors (hospitals, clinics, health NGOs). Choose another page, or mark the sponsor as Health.",
  NOT_A_FINISHER: "That student hasn't entered this campaign's prize race.",
  NO_REWARD: "That finisher is after the ones who get the reward.",
  INVALID_PHONE: "That isn't a Bangladesh mobile number (11 digits, 01…).",
  NOT_ELIGIBLE: "A winner you chose isn't eligible: they don't have enough friends from their own university or from other universities. Pick from the ranked students.",
  INVALID_SCORING: "Some points values aren't allowed. Use whole numbers in the range shown under each field; points can only change while the campaign is a draft.",
  PHOTO_NOT_ALLOWED: "The photo check refused this photo.",
  ISSUE_CLOSED: "This issue is closed.",
  ALREADY_REPORTED: "This was already reported.",
  STATUS_CHANGE_INVALID: "That status change isn't allowed.",
  NOTE_REQUIRED: "Add a note explaining why.",
  CANNOT_BAN_OFFICIAL: "Official replies come from university staff; their authors can't be banned here.",
  ROLE_CONFLICT: "Admins can't also be staff. Make them a student first.",
  BLOOD_REQUEST_NOT_OPEN: "This request is already fulfilled or closed, so it can't be closed again. Refresh the list.",
  CAMPUS_ADMIN_LIMIT: "This university already has 5 campus admins. Remove one first.",
  NOT_VERIFIED: "Only a verified student can be a campus admin. Verify them first.",
  ESCALATION_NOT_FOUND: "That request doesn't exist or was already resolved.",
  DOMAIN_REQUEST_NOT_FOUND: "That request doesn't exist or was already decided.",
  FEEDBACK_NOT_FOUND: "That feedback doesn't exist (maybe it was deleted).",
  CAMPAIGN_NOT_FOUND: "That campaign doesn't exist.",
  CAMPAIGN_NOT_EDITABLE: "This field can't be changed once a campaign is live.",
  CAMPAIGN_NOT_SETTLED: "Winners can only be announced after the settle date.",
  CAMPAIGN_ALREADY_ANNOUNCED: "The winners of this campaign are already announced.",
  REFERRAL_NOT_FOUND: "That invite doesn't exist.",
  NOT_FOUND: "Not found.",
  FORBIDDEN: "You don't have access to this.",
  NETWORK: "Can't reach the VarsityKotha server. Is it running?",
  INTERNAL_ERROR: "Something went wrong on the server. Try again.",
};

/** Field names in INVALID_PROMO details, as the panel calls them. */
const promoFieldNames: Record<string, string> = {
  name: "The name",
  website: "The website",
  contactEmail: "The email",
  archived: "Archived",
  kind: "The kind",
  placement: "The place",
  campaignId: "The campaign",
  code: "The promo code",
  link: "The link",
  linkKind: "The link",
  startsAt: "The start",
  endsAt: "The end",
  expiresAt: "The deal's end date",
  universityIds: "Universities",
  cities: "Cities",
  totalViews: "Total views",
  sponsorId: "The sponsor",
  status: "The status",
  titleEn: "The English title",
  image: "The image",
  from: "The start date",
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
  // The API names the field and the problem ({field: reason}); that says more than a generic line.
  if (code === "INVALID_PROMO") {
    const parts = Object.entries(d)
      .filter(([, v]) => typeof v === "string" && v)
      .map(([k, v]) => `${promoFieldNames[k] ?? k} ${String(v)}.`);
    if (parts.length) return parts.join(" ");
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

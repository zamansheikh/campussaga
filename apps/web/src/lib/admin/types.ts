// Shapes of the Go admin API (docs/ADMIN.md).

export type Paged<T> = { items: T[]; total: number; page: number; pageSize: number };

export type UniversityRef = { id: string; slug: string; name: string };

export type Tokens = {
  accessToken: string;
  accessTokenExpiresAt: string;
  refreshToken: string;
  refreshTokenExpiresAt: string;
};

export type Me = {
  id: string;
  email: string;
  displayName: string | null;
  role: string;
  university: UniversityRef | null;
  photoVersion?: string | null;
  googlePhotoUrl?: string | null;
};

export type SignedIn = { tokens: Tokens; user: Me };

export type CodeSent = { expiresInSeconds: number; resendAfterSeconds: number };

export type Stats = {
  users: {
    total: number;
    verified: number;
    notVerified: number;
    admins: number;
    blocked: number;
    newLast7Days: number;
  };
  groups: { total: number; memberships: number; slots: number; announcements: number };
  devices: { android: number; ios: number };
  universities: { active: number; total: number };
  signupsByDay: { date: string; count: number }[];
  topUniversities: { id: string; name: string; users: number }[];
  /** Campus Voice numbers (once the API has them). */
  voice?: VoiceStats;
};

export type Role = "student" | "admin";

export type AdminUser = {
  id: string;
  email: string;
  displayName: string | null;
  department: string | null;
  batch: string | null;
  role: Role | string;
  verified: boolean;
  verifiedAt: string | null;
  universityEmail: string | null;
  university: UniversityRef | null;
  blockedAt: string | null;
  createdAt: string;
  lastActiveAt: string | null;
  groups: number;
  photoVersion: string | null;
  googlePhotoUrl: string | null;
};

export type AdminUserDetail = AdminUser & {
  memberships: { groupId: string; title: string; role: "cr" | "member" }[];
  devices: { platform: string; createdAt: string }[];
  activeSessions: number;
};

export type UserStatus = "verified" | "notVerified" | "blocked" | "admin";

export type UniversityKind = "public" | "private";

export type AdminUniversity = {
  id: string;
  slug: string;
  name: string;
  nameBn: string | null;
  city: string | null;
  kind: UniversityKind | null;
  website: string | null;
  active: boolean;
  domains: string[];
  users: number;
  groups: number;
};

export type AdminGroup = {
  id: string;
  title: string;
  department: string;
  batch: string;
  section: string;
  semester: string;
  joinCode: string;
  university: UniversityRef;
  members: number;
  crs: { id: string; name: string | null; email: string }[];
  slots: number;
  /** A published routine that stays when its last member leaves. */
  keepWhenEmpty: boolean;
  createdAt: string;
};

export type GroupMember = {
  userId: string;
  name: string | null;
  email: string;
  role: "cr" | "member";
  verified: boolean;
  joinedAt: string;
};

export type AdminGroupDetail = AdminGroup & { memberList: GroupMember[] };

export type ConfigItem = { key: string; value: unknown; updatedAt: string };

export type PushResult = { users: number; devices: number };

export type AuditEntry = {
  id: number;
  actor: { id: string; email: string; name: string | null } | null;
  action: string;
  targetType: string | null;
  targetId: string | null;
  meta: Record<string, unknown>;
  createdAt: string;
};

// ---- Campus Voice (docs/CAMPUS_VOICE.md §4) --------------------------------

/** Who may use the panel: admins see everything, moderators only Moderation. */
export type PanelRole = "admin" | "moderator";

export type VoiceStats = { open: number; solved: number; held: number; reported: number; issuesLast7Days: number };

export type IssueCategory =
  | "academic"
  | "hostel"
  | "transport"
  | "facilities"
  | "safety"
  | "administration"
  | "food"
  | "it"
  | "other";

export type IssueStatus = "open" | "acknowledged" | "in_progress" | "solved" | "rejected";

export type Visibility = "visible" | "held" | "hidden" | "removed";

export type ReportReason = "spam" | "abuse" | "personal_info" | "false_info" | "inappropriate" | "other";

/**
 * Only for named posts and official replies; anonymous content has none.
 * `name: null` = a named post whose account was deleted.
 */
export type VoiceAuthor = { name: string | null; verified: boolean } | null;

export type IssueCard = {
  id: string;
  category: IssueCategory | string;
  private: boolean;
  title: string;
  preview: string;
  status: IssueStatus | string;
  visibility: Visibility | string;
  meTooCount: number;
  commentCount: number;
  imageCount: number;
  thumbnail: string | null;
  voted: boolean;
  following: boolean;
  mine: boolean;
  author: VoiceAuthor;
  locationLabel: string;
  createdAt: string;
  statusChangedAt: string;
};

export type TimelineEntry = {
  from: string;
  to: string;
  actorKind: "authority" | "moderator" | "author" | "system" | string;
  actorTitle: string;
  note: string;
  createdAt: string;
};

export type Issue = IssueCard & {
  body: string;
  images: { id: string; width: number; height: number }[];
  timeline: TimelineEntry[];
  holdReason: string;
  removedReason: string;
  reportCount: number;
};

export type VoiceComment = {
  id: string;
  kind: "student" | "official" | string;
  handle: string;
  isIssueAuthor: boolean;
  mine: boolean;
  author: VoiceAuthor;
  officialTitle: string;
  body: string;
  visibility: Visibility | string;
  removedReason: string;
  createdAt: string;
};

/** A report never carries who sent it. */
export type VoiceReport = {
  targetType: "issue" | "comment" | string;
  targetId: string;
  reason: ReportReason | string;
  details: string;
  state: "open" | "resolved" | "dismissed" | string;
  createdAt: string;
};

export type ModerationIssue = Issue & {
  reports: VoiceReport[];
  comments: VoiceComment[];
  /** The photo check's result per image (older servers: absent). */
  photoChecks?: { imageId: string; score: number | null; flagged: boolean }[];
};

export type QueueKind = "held" | "reported" | "hidden" | "private";

export type QueueItem = {
  targetType: "issue" | "comment" | string;
  issue: IssueCard;
  comment: VoiceComment | null;
  university: UniversityRef;
  reasons: Record<string, number>;
  holdReason: string;
  createdAt: string;
};

export type CursorPage<T> = { items: T[]; nextCursor: string | null };

export type ModerationAction = "approve" | "hide" | "remove" | "restore";

export type StaffKind = "authority" | "moderator";

export type StaffItem = {
  user: { id: string; email: string; displayName: string | null };
  kind: StaffKind | string;
  university: UniversityRef | null;
  title: string;
  createdAt: string;
};

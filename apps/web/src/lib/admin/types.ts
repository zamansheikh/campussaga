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
  /** Build 6 numbers (an older API doesn't send them). */
  campus?: CampusStats;
  blood?: BloodStats;
  bus?: BusStats;
  feedback?: { new?: number; open?: number; last7Days?: number };
};

export type CampusStats = {
  postsLast7Days?: Partial<Record<"issue" | "post" | "question" | "poll", number>>;
  commentsLast7Days?: number;
  reactionsLast7Days?: number;
};

export type BloodStats = {
  donors?: number;
  available?: number;
  openRequests?: number;
  requestsLast7Days?: number;
  responsesLast7Days?: number;
};

export type BusStats = { liveNow?: number; sharesLast7Days?: number; tripsShared?: number; ratingsLast30Days?: number };

export type BloodRequestStatus = "open" | "fulfilled" | "closed";

export type BloodRequest = {
  id: string;
  university: { id: string; name: string };
  bloodGroup: string;
  units: number;
  hospital: string;
  area: string;
  neededBy: string;
  urgent: boolean;
  contactName: string;
  contactPhone: string;
  note: string;
  status: BloodRequestStatus | string;
  notified: number;
  responses: number;
  requester: { id: string; name: string | null; email: string } | null;
  createdAt: string;
  closedAt: string | null;
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

/** issue | post | question | poll (docs/CAMPUS_SOCIAL.md). Older items: issue. */
export type PostKind = "issue" | "post" | "question" | "poll";

export type Poll = {
  options: { id: string; label: string; votes: number | null }[];
  totalVotes: number;
  myVote: string | null;
  closesAt: string;
  closed: boolean;
};

export type IssueCard = {
  id: string;
  kind?: PostKind | string;
  /** Hidden from students visiting other campuses (older servers: absent). */
  campusOnly?: boolean;
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
  reactions?: Record<string, number>;
  poll?: Poll | null;
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
  parentId?: string | null;
  likeCount?: number;
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

// Campus admins and verification by people (docs/CAMPUS_ADMINS.md, section 3).

export type CampusAdmin = {
  user: { id: string; name: string | null; email: string };
  university: { id: string; name: string };
  appointedAt: string;
};

export type EscalationKind = "student" | "section" | "report" | "other";

export type Escalation = {
  id: string;
  universityId: string;
  universityName?: string | null;
  university?: { id: string; name: string } | null;
  kind: EscalationKind | string;
  targetId: string | null;
  note: string;
  createdBy?: { id: string; name: string | null } | null;
  createdByName?: string | null;
  createdAt: string;
};

export type DomainRequest = {
  id: string;
  domain: string;
  email: string;
  universityId: string | null;
  universityName: string | null;
  mxOk: boolean;
  requester?: { id: string; name: string | null } | null;
  createdAt: string;
};

export type AutoVouchBlock = {
  userId: string;
  user?: { id: string; name: string | null } | null;
  name?: string | null;
  reason: string | null;
  createdAt: string;
};

export type AdminInbox = {
  escalations: Escalation[];
  domainRequests: DomainRequest[];
  universitiesWithoutCampusAdmin: { id: string; name: string; students: number }[];
  autoVouchBlocks: AutoVouchBlock[];
  reportsWaiting: number;
  /** Feedback that is new or has student replies the team hasn't opened. */
  feedbackNew?: number;
};

export type AttentionReason = "no_campus_admin" | "sections_without_cr" | "reports_waiting" | "low_verified";

export type UniversityHealth = {
  id: string;
  name: string;
  students: number;
  verified: number;
  verifiedPct: number;
  campusAdmins: number;
  sections: number;
  sectionsWithCr: number;
  busRoutes: number;
  openReports: number;
  openEscalations: number;
  attention: (AttentionReason | string)[];
};

export type FeedbackKind = "bug" | "idea" | "other";
export type FeedbackStatus = "new" | "seen" | "planned" | "in_progress" | "done" | "wont_do";

export type FeedbackImage = { url: string; thumbUrl: string };

export type FeedbackItem = {
  id: string;
  kind: FeedbackKind | string;
  message: string;
  status: FeedbackStatus | string;
  images: FeedbackImage[];
  createdAt: string;
  lastMessageAt: string;
  unread?: number | boolean;
  user: { id: string; name: string | null; email: string; university: string | { id: string; name: string } | null } | null;
  teamUnread: number;
  device: string | null;
  os: string | null;
  appVersion: string | null;
  build: number | null;
  platform: string | null;
};

export type FeedbackMessage = {
  id: string;
  fromTeam: boolean;
  body: string;
  createdAt: string;
  author?: { id: string; name: string | null } | null;
};

export type FeedbackDetail = FeedbackItem & { messages: FeedbackMessage[] };

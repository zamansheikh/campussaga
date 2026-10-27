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

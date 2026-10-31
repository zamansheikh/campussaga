# Campus admins and verification by people

With 200+ universities, the central admin can't verify students or settle
section problems one by one. Instead:

- The university email code stays the main way to verify. It is automatic.
- **Campus admins:** one to five trusted students per university, appointed
  by the central admin. They handle their own university inside the app.
- A student with no university email gets verified by people who know them:
  their section's **CR confirms** them, or **two verified classmates vouch**
  for them.
- The central admin works from a **"Needs attention" inbox** and a
  **university health table** instead of browsing every university.

## 1. Data (migration `00720_campus_admins.sql`)

```
campus_admins
  user_id uuid pk → users cascade, university_id uuid → universities,
  appointed_by uuid null → users set null, created_at

users
  + verified_via text null CHECK in ('email','cr','vouch','campus_admin','admin')
    backfill: 'email' where university_email is not null and verified,
    'admin' for other verified users
  + vouch_code text unique null   -- 8 chars [a-z0-9], made on first use

verification_events                -- history, newest first
  id, user_id → users cascade, university_id, method (same values),
  actor_id null → users set null, created_at,
  revoked_at null, revoked_by null → users set null, reason text ≤ 300

vouches
  user_id → users cascade, voucher_id → users cascade, created_at,
  pk (user_id, voucher_id)

vouch_blocks                       -- may not vouch or confirm others
  user_id pk → users cascade, blocked_by null → users set null,
  reason text ≤ 300, auto bool, created_at

escalations                        -- campus admin → central admin
  id, university_id, kind text CHECK in ('student','section','report','other'),
  target_id text null, note text ≤ 500, created_by → users set null,
  created_at, resolved_at null, resolved_by null, resolution text ≤ 300

domain_requests                    -- "my university email isn't recognized"
  id, domain text, email text, university_id null, university_name text ≤ 120,
  requester_id null → users set null, mx_ok bool, created_at,
  status text CHECK in ('open','approved','rejected') default 'open',
  decided_by null, decided_at null
```

## 2. Rules

**Who may vouch or confirm.** A verified student of the same university as
the student being verified. They can't do it for themselves, and they
can't be in `vouch_blocks`.

**Vouch.** Two vouches verify the student (`verified_via='vouch'`). Each
person can vouch at most 5 times in any 30 days (`429 VOUCH_LIMIT`).

**CR confirms.** The CR of a class group the student belongs to taps
Confirm (`verified_via='cr'`). The CR must be verified and at the same
university. Each CR can confirm at most 80 students in any 30 days.

**Campus admin.**
- They can verify anyone at their university (`campus_admin`).
- They can take away verification given by people (`cr`, `vouch`,
  `campus_admin`), with a reason. They can't remove email-proven
  verification (`409 EMAIL_VERIFIED`); only the central admin can.
- When verification is taken away, every event stays in the history.

**Automatic vouch block.** If two students that someone vouched for or
confirmed have their verification taken away within 90 days, that person
gets a vouch block (`auto=true`).

**Every verification:**
- writes a `verification_events` row and an `audit_log` row (actions
  `campus.verify`, `campus.unverify`, `campus.vouch_block` and so on);
- sends the student a push: "You're verified at {university}" /
  "{university}-এ তুমি এখন ভেরিফায়েড".

**Who can be a campus admin.** A verified member of that university, at
most 5 per university.

**What campus admins see.**
- Students' names, department, batch, photo and verification history,
  including who vouched or confirmed.
- **Never students' emails.**

## 3. API (prefix `/api/v1`)

### Students
| Method | Path | Notes |
|---|---|---|
| GET | `/me/verification` | `{verified, via, emailPossible, vouches, needed: 2, vouchedBy: [{id,name}], code, link, crs: [{groupId, groupName, crId, crName}]}`. `emailPossible`: their university has known email domains. `link` = `https://varsitykotha.com/v/{code}`. `crs`: the CRs of their groups. |
| GET | `/vouch/{code}` | `{student: {id, name, department, batch, photoVersion, googlePhotoUrl}, university: {id, name}, vouches, needed, verified, alreadyVouched, canVouch, reason}`, where `reason` is one of `self`, `not_verified`, `other_university`, `blocked`, `limit`, `already_verified` (or null). `404 VOUCH_NOT_FOUND`. |
| POST | `/vouch/{code}` | Vouches and returns the same shape. Errors match the reasons: `VOUCH_SELF`, `VERIFY_YOURSELF_FIRST`, `OTHER_UNIVERSITY`, `VOUCH_BLOCKED`, `VOUCH_LIMIT` (429), `ALREADY_VERIFIED`. |
| POST | `/groups/{id}/members/{userId}/confirm` | The CR confirms a member. Returns the member view. Errors: `NOT_CR` (403), `VERIFY_YOURSELF_FIRST`, `OTHER_UNIVERSITY`, `ALREADY_VERIFIED`, `VOUCH_BLOCKED`, `CONFIRM_LIMIT` (429). |
| POST | `/universities/domain-requests` | `{email, universityId?, universityName?}` (unauthenticated, rate-limited per IP). Checks the domain's MX record (`mx_ok`). Returns 202. |

`GET /me` adds `campusAdmin: bool` (for the student's own university).

### Campus admins (`/campus-admin/*`, own university only; others get `403 NOT_CAMPUS_ADMIN`)
| Method | Path | Notes |
|---|---|---|
| GET | `/campus-admin/inbox` | `{university: {id,name}, waiting: [Student…] (not verified, with ≥1 vouch or in a group, top 20), waitingCount, reports, sectionsWithoutCr, openBlood, recent: [VerificationEvent…] (10)}` |
| GET | `/campus-admin/students` | Paged. `?status=unverified\|verified\|all&q=`. Student = `{id, name, department, batch, photoVersion, googlePhotoUrl, verified, via, vouches, groups: [{id,name,role}], vouchBlocked, joinedAt}` |
| GET | `/campus-admin/students/{id}` | Student plus `history: [{method, actor: {id,name}\|null, at, revokedAt, reason}]`, `vouchedBy: [{id,name,at}]`, `confirmedOrVouchedFor: n`. |
| POST | `/campus-admin/students/{id}/verify` | Verifies them as `campus_admin`. Returns the Student. |
| POST | `/campus-admin/students/{id}/unverify` | `{reason}`. Returns the Student. `409 EMAIL_VERIFIED` for email-proven students. |
| PUT / DELETE | `/campus-admin/students/{id}/vouch-block` | PUT `{reason}` blocks, DELETE unblocks. Returns the Student. |
| GET | `/campus-admin/sections` | `[{id, name, term, members, cr: [{id,name}], lastActivityAt}]`, sections without a CR first. |
| PUT | `/campus-admin/sections/{id}/cr` | `{userId}` makes a verified member a CR. |
| DELETE | `/campus-admin/sections/{id}/cr/{userId}` | Makes that CR a plain member again. |
| GET / PUT / DELETE | `/campus-admin/bus-reps` | The university's transport reps (same shapes as `/admin/transport/reps`). |
| GET | `/campus-admin/reports` | Reported Campus posts and comments of the university: `[{kind: issue\|comment, id, issueId, excerpt, reports, reasons, createdAt, hidden}]`. |
| POST | `/campus-admin/reports/{kind}/{id}` | `{action: hide\|restore\|dismiss}`. Reuses the Campus Voice moderation rules. |
| GET | `/campus-admin/blood` | The university's open blood requests (same item as `/admin/blood/requests`). |
| POST | `/campus-admin/blood/{id}/close` | `{reason?}` |
| POST | `/campus-admin/escalations` | `{kind, targetId?, note}` sends it to the central inbox. |

### Central admin
| Method | Path | Notes |
|---|---|---|
| GET | `/admin/campus-admins` | `?universityId=`. Returns `[{user: {id,name,email}, university: {id,name}, appointedAt}]`. |
| POST | `/admin/campus-admins` | `{userId}`. The user's university is used; they must be verified. Errors `409 CAMPUS_ADMIN_LIMIT` and `NOT_VERIFIED`. |
| DELETE | `/admin/campus-admins/{userId}` | Removes the campus admin. |
| GET | `/admin/inbox` | `{escalations: [...open], domainRequests: [...open], universitiesWithoutCampusAdmin: [{id,name,students}] (≥5 students), autoVouchBlocks: [...last 14 days], reportsWaiting: n}` |
| POST | `/admin/escalations/{id}/resolve` | `{resolution}` |
| GET | `/admin/domain-requests` | Paged, `?status=`. |
| POST | `/admin/domain-requests/{id}/approve` | `{universityId}` adds the domain to that university (same validation as `/admin/universities/{id}/domains`). |
| POST | `/admin/domain-requests/{id}/reject` | Rejects it. |
| GET | `/admin/universities/health` | Paged, `?sort=students\|verifiedPct\|attention&q=`. Rows: `{id, name, students, verified, verifiedPct, campusAdmins, sections, sectionsWithCr, busRoutes, openReports, openEscalations, attention: ["no_campus_admin","sections_without_cr","reports_waiting","low_verified"]}` |

Every write is audited (actions `campus.*` and `admin.campus_admin.*`).

## 4. App
- **Get verified** (not-verified students), from a Profile banner and the
  Today banner. Three ways:
  1. **University email code**, the existing flow, shown when
     `emailPossible`.
  2. **"Ask your CR"**: lists their groups' CRs ("Rafi, CR of CSE 61 · A")
     with a button that opens the group.
  3. **"Ask 2 classmates"**: progress "1 of 2", who vouched, and a Share
     link button (`varsitykotha.com/v/{code}`).
- **Vouch page** (App Link `/v/{code}`):
  - The student's card (photo, name, department, batch, university), then
    "I know them, they study at {university}".
  - Every `reason` is explained in plain words.
  - After a vouch: "Thanks! 1 more classmate needed" or "{name} is
    verified".
- **CRs:** in the member list, not-verified members get a **Confirm**
  button. The dialog says: "Only confirm classmates you know are in your
  section."
- **Campus admin** (shown when `me.campusAdmin`): a "Campus admin" entry
  on Profile with these tabs:
  - **Inbox:** waiting students, reports, sections without a CR.
  - **Students:** search and filters; a student page with history, plus
    Verify, Remove verification (with a reason) and Block vouching.
  - **Sections:** see and change the CR.
  - **Bus reps.**
  - **Reports:** hide, restore or dismiss.
  - **Blood:** close a request.

  Every detail screen has "Ask the VarsityKotha team" (an escalation).
- **Sign-in:** when a university email's domain isn't recognized, show
  "Request your university" (a domain request).
- **Push:** `campus_verified` opens Profile.
- **Strings:** English and Bangla.

## 5. Web
- `/v/{code}` page for people without the app: "Open in the app / Get
  VarsityKotha". The AndroidManifest App Links add `/v/`.
- **Central admin panel:**
  - **Needs attention** (`/admin/inbox`, first nav item with a count): open
    escalations (resolve), domain requests (approve to a university or
    reject), universities with no campus admin (go to appoint), automatic
    vouch blocks, and a link to moderation.
  - **University health** (`/admin/universities/health`): a sortable table
    with the attention reasons shown as badges.
  - **Campus admins:** on each university (list, appoint by user search,
    remove), and on a user's page ("Make campus admin").
- **Privacy policy:** a short "Verification by classmates and CRs" section.
  Who vouched for or confirmed a student is kept and shown to that
  university's campus admins.

## 6. As implemented (backend notes)
- Extra columns: `vouches.void_at` (set when the verification the vouches gave
  is taken away; they stop counting but still count for the voucher's quota
  and the 90-day block rule). History rows for `email` and `admin` come from
  database triggers on `users`, which also keep `verified_via` in step with
  `verified_at` (so the email code, Google sign-in and the admin's hand switch
  need no change).
- Claims: `Verified` is not stored in the token; the session check reads it
  from the database on every request, so a vouch- or CR-verified student is
  verified on their very next request and on every refreshed token.
- Extra errors: `ADMIN_VERIFIED` (409) when a campus admin tries to remove a
  verification the team gave by hand; `NOT_VERIFIED` (409) for unverify of an
  unverified student or a CR candidate who is not verified; `LAST_CR`,
  `CR_LIMIT_REACHED`, `CR_NOT_FOUND`, `MEMBER_NOT_FOUND`, `GROUP_NOT_FOUND`,
  `REP_NOT_FOUND`, `USER_NOT_FOUND`.
- Arrays: `GET /campus-admin/sections`, `/campus-admin/reports`,
  `/campus-admin/blood` and `/admin/campus-admins` return a bare array in
  `data`. `/campus-admin/bus-reps` returns `{items}` like the admin one, with
  `email` always `""`. Blood items have `requester.email` `""`.
- `POST /campus-admin/reports/{kind}/{id}` and `DELETE .../bus-reps/{user}`
  return 204. `PUT/DELETE .../sections/{id}/cr` return the section list.
- Reports list skips private (safety) issues; those stay with authorities and
  moderators. Hide/restore/dismiss run the Campus Voice moderation code with a
  moderator viewer scoped to the university (audit `moderation.*` plus
  `campus.report_*`).
- The automatic block counts only unverifications done through
  `/campus-admin/students/{id}/unverify`.
- `GET /admin/domain-requests` defaults to `status=open` (`all` for every one).
- `POST /universities/domain-requests` returns `202 {"received": true}`; the
  same email with an open request is not stored twice.
- Health thresholds: `no_campus_admin` when 0 campus admins and >= 5 students;
  `low_verified` when >= 10 students and under 40% verified.

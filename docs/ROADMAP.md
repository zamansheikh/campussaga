# VarsityKotha — Roadmap

We build in **releases**. Each release has a small, fixed set of features that
we finish completely: designed, translated, tested, secure, and polished.
Then we ship it, learn from students, and pick the next release from this roadmap.

**No new features enter a release once it has started.** New ideas go to the
backlog (section 4).

---

## 1. Product pillars

| Pillar | Why students open the app | Frequency |
|---|---|---|
| **My Class** | Class routine, reminders, class cancelled / room changed alerts from the CR | **Every day** |
| **Campus Voice** | Raise campus issues anonymously, "me too", track until solved | When something is wrong |
| **Stay on Track** | Exams, assignments, deadlines, attendance, CGPA | Every week |
| **Campus Life** | Notices, scorecards, lost & found, events, clubs | Regularly |

**Strategy:** *daily utility brings students in; Campus Voice is why we exist.*
A student who opens VarsityKotha every morning for their routine is already
there when they want to raise an issue. Then Campus Voice launches to a real
audience, not an empty feed.

---

## 2. Releases

```
R0 Foundation ─▶ R1 My Class ─▶ R2 Campus Voice ─▶ R3 Stay on Track ─▶ R4 Accountability ─▶ R5 Campus Life
  (internal)      (public)        (public)           (public)            (public)              (public)
```

Time estimates assume one developer working most days. Each release ends with
a 1–2 week beta before going public.

---

### R0 — Foundation (≈ 3 weeks, internal only)

The base every feature stands on. Not visible to students, but done properly
it saves months later.

- Monorepo: `apps/mobile`, `packages/campus_ui|campus_core|campus_data|campus_l10n`, `backend/` (Go API)
- Design system v1: tokens, light/dark theme, Bangla + English fonts, core components, Widgetbook
- Go API + PostgreSQL on the VPS (Docker, behind nginx), HTTPS, backups tested ([DEPLOYMENT.md](DEPLOYMENT.md))
- CI: format, analyze, Flutter tests, Go tests (`go test -race`, incl. security e2e tests), APK build
- Auth: sign in with **university Google account** (Firebase, done) or **university email + OTP code**; session handling; log out everywhere
- Universities list + email domains (seed the launch universities)
- Profile basics: name, department (with suggestions from classmates), batch; first-time setup after sign-in, edit, delete account (done)
- App shell: navigation, settings, language switch, theme switch (remembered), force-update check, crash reporting, bundled Bangla font (done)
- Privacy policy + terms (Bangla + English); **delete my account** works

**Done when:** a student at a launch university can install a test build,
verify with their university email, set language and theme, and delete their
account, all on a cheap Android phone.

---

### R1 — My Class (≈ 8 weeks) ⭐ first public release

**Goal:** every student checks VarsityKotha every morning.

#### How the routine gets into the app

In Bangladeshi universities every section already has a **CR (class
representative)** who shares the routine and announces changes in Messenger
groups. VarsityKotha gives the CR a better tool:

1. CR creates a **class group** (university → department → batch → section → semester).
2. CR enters the weekly routine once: course, teacher, room, day, time, theory/lab.
3. Students join with an **invite link, QR code or 6-letter code**. One CR brings 40–60 students at once.
4. When something changes, the CR taps "Cancel class" / "Change room" / "Reschedule" / "Extra class" → every member gets a push notification, and their routine and reminders update automatically.

#### Features

| Feature | Details |
|---|---|
| **Class groups** | Create / join by link, QR or code; CR + up to 2 co-CRs; CR can transfer role; leave group; member list visible to CRs only |
| **Weekly routine** | CR enters slots; students see it by day and by week; colors per course |
| **Today screen** (home) | Next class with countdown, room and teacher; rest of today; "No classes today 🎉" |
| **Class changes** | Cancel, reschedule, room change, extra/makeup class, for a single date; shown clearly on the day with a badge |
| **Reminders** | Local notification X minutes before each class (default 10, per-course mute); work **offline**; skip cancelled classes; quiet on holidays |
| **CR announcements** | Short text updates to the group ("Bring calculator tomorrow"); push notification; pin one message |
| **Multiple groups** | Students taking a retake course in another section can join that group too and hide the courses they don't take |
| **Personal slots** | Add your own entries (lab, tuition, part-time job) visible only to you |
| **Offline first** | Routine stored on the phone; app opens instantly without internet |
| **Semester switch** | CR archives the old routine and starts the new semester's |

**Not in R1:** issues, exams/assignments, attendance, home-screen widget,
official university routines, web version.

**Done when:**
- A CR can set up a full week's routine in **under 10 minutes**
- A student can join and see today's classes in **under 1 minute** after installing
- Reminders fire on time on Android 12–16, including after a phone restart
- A class cancellation reaches all members within 1 minute
- Works fully in Bangla and English, light and dark, on a 2 GB RAM phone
- Beta with **5+ class groups (200+ students)** for 2 weeks with no critical bugs

**Launch timing:** routines are set up at the **start of a semester**. Run the
beta with a few sections during the current semester, then launch publicly at
the next semester start (e.g. Spring 2027, January). If we're not ready, wait
for the following semester rather than launching half-done.

---

### R2 — Campus Voice (≈ 6–8 weeks)

**Goal:** students can raise issues safely and see them get fixed.

- Post an issue: category, title, details, up to 4 photos (location data removed), **anonymous by default**
- "Similar issues" check before posting
- Campus feed: Trending / New / Solved, category filters
- "Me too" votes; comments with anonymous per-thread handles
- Status timeline: Open → Acknowledged → In progress → Solved / Rejected
- Authority accounts (verified manually) with official replies and status changes
- Report button; moderation queue; automatic text and image checks; audit log
- Rate limits and reputation basics
- "How anonymity works" screen
- Safety reports go privately to moderators/authority, never to the public feed

**Done when:** e2e API tests prove no role can see anonymous authors; one
real authority has replied to and solved at least one issue during beta.

---

### R3 — Stay on Track (≈ 6 weeks)

- **Exams & assignments**: CR posts quiz/mid/final/assignment dates per course → reminders 1 day and 1 hour before
- **Deadlines view**: everything due in the next 7 days
- **Attendance tracker** (personal): tap present/absent after each class, see % per course and a warning below the required %
- **CGPA calculator** with the university's grading scale
- **Android home-screen widget**: next class + next deadline
- **Academic calendar**: holidays and exam weeks per university (reminders pause on holidays)

---

### R4 — Accountability (≈ 6 weeks)

- **University scorecard**: response rate, median time to solve, % solved
- University reviews by category (one per student per semester)
- **Official notice board**: verified authorities post notices; students follow departments
- **Authority web dashboard** (Flutter Web) to manage issues and notices
- Official routines: departments can publish routines that class groups import
- Monthly public accountability report

---

### R5 — Campus Life (pick based on demand)

Lost & found · events and clubs · polls · used book marketplace · campus
reps program · iOS release (could move earlier if demand is high) · study
groups · teacher office hours

---

## 3. Definition of Done (every feature, every release)

A feature is finished only when **all** of these are true:

- [ ] Designed in Figma using design-system components; reviewed on a small screen
- [ ] Bangla and English text, checked by a native speaker
- [ ] Light and dark mode
- [ ] Loading, empty, error and offline states handled
- [ ] Database changes as new migration files; every endpoint has **e2e tests for who may and may not access it**
- [ ] Unit tests for logic; widget/golden tests for new components
- [ ] Screen reader labels; touch targets ≥ 48 dp; works with large text
- [ ] Tested on a low-end Android phone and a slow network
- [ ] Analytics events added (no personal data)
- [ ] Docs updated (architecture / data model / changelog)

---

## 4. Backlog and how features get picked

Ideas from students, CRs and the team go to a backlog (GitHub Issues with a
`idea` label, or a project board).

Before each release we score backlog items:

| Question | Score 1–5 |
|---|---|
| How often will a student use it? (daily = 5) | |
| How many students need it? | |
| Does it strengthen a pillar we already have? | |
| Effort (5 = small) | |
| Risk to privacy / safety (5 = no risk) | |

Highest scores go into the next release, as long as the release stays
small enough to finish properly.

---

## 5. Release rhythm

```
Plan scope (1–2 days) → Design (1 week) → Build → Feature freeze →
Beta (1–2 weeks) → Fix → Release → Measure (2 weeks) → next release
```

- Small bug-fix updates every 2 weeks between releases
- Every release has a short changelog in the app ("What's new")
- After each release: look at the numbers (section 6) and student feedback before choosing the next

---

## 6. What we measure

| Release | Key number |
|---|---|
| R1 My Class | **Daily active users / total users** (target > 40%), class groups created, reminders delivered |
| R2 Campus Voice | Issues per week, % with authority response, median time to solved |
| R3 Stay on Track | Deadlines added per group, attendance check-ins |
| R4 Accountability | Universities with an active authority, notices posted |
| Always | Day-7 and day-30 retention, crash-free sessions > 99.5%, app rating > 4.5 |

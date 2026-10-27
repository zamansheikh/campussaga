# Campus Saga — Project Plan

> The daily app for university students: your class routine and reminders
> every morning, and a safe, anonymous voice to get campus problems fixed.

| Document | What's in it |
|---|---|
| **This file** | Vision, users, principles, growth, risks |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Releases R0–R5, feature scope, definition of done, release rhythm |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Database choice, system design, data model, app structure |
| [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) | Colors, fonts, spacing, components, UX patterns |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Self-hosting Supabase on our VPS: security, backups, monitoring |

---

## 1. The problem

**Daily chaos.** Routines live in blurry photos and Messenger groups. Class
cancelled, room changed, makeup class on Saturday: students find out late
or miss it. Nobody reminds you that class starts in 10 minutes.

**Unheard problems.** Broken washrooms, Wi-Fi down, unfair grading, hostel
food, harassment. Students don't complain openly out of fear, complaints get
buried in Facebook groups, and nobody knows if anything was fixed.

**Campus Saga solves both:**
- **My Class** → routine, reminders and instant change alerts from the CR. *Reason to open the app every day.*
- **Campus Voice** → verified-but-anonymous issues, "me too" votes, tracked until solved. *Reason the app exists.*

---

## 2. Users and roles

| Role | Who | Can do |
|---|---|---|
| **Student** | Verified student (university email) | See routine, get reminders, join class groups, raise and vote on issues |
| **CR** (class representative) | Student who runs a class group | Create the routine, post changes and announcements, manage members |
| **Authority** | Verified university official | Reply officially to issues, change status, post notices. **Never sees student identities** |
| **Moderator** | Campus Saga team | Handle reports, remove abuse, verify authorities |
| **Super admin** | Owner | Everything, all actions logged |

---

## 3. Principles

1. **Finish before adding.** Small releases, each one complete and polished ([ROADMAP.md](docs/ROADMAP.md)).
2. **Useful every day.** If a feature doesn't make a student's day easier or their campus better, it waits.
3. **Anonymity is sacred.** The system knows who posted; no person does. Never break this.
4. **Fast on cheap phones.** Small app, offline first, works on slow internet.
5. **Bangla first-class.** Every screen in Bangla and English from day one.
6. **No ads in the student experience.**

---

## 4. Privacy and trust

- Only verified students can use the app. Fake complaints and spam drop sharply.
- Issue authorship is stored in a separate, unreachable part of the database ([ARCHITECTURE.md §3](docs/ARCHITECTURE.md)).
- **Class groups and issues never mix:** an anonymous issue never shows your department, batch or section, so it can't be narrowed down to you.
- Class group member lists are visible only to that group's CRs.
- We collect the minimum: no phone number, no birthday, no contacts. Photos have location data removed.
- Revealing a poster's identity requires a logged two-admin process, only for legal requests. The policy is public.

---

## 5. Getting students to use it

**CRs are the growth engine.** One CR who sets up a routine brings 40–60
classmates in one day.

1. **Pick 1–2 launch universities** where we have friends.
2. **Recruit CRs** before the semester starts: show them it's easier than Messenger + routine photo. Give them a "Founding CR" badge and certificate.
3. **Launch at a semester start**, when every section sets up its routine.
4. Once students use it daily, **launch Campus Voice (R2)** to a ready audience. Seed it with real issues collected beforehand, and get one authority on board to reply.
5. Share "Solved ✅" stories on Facebook, Instagram and TikTok. A solved issue is the best advert.
6. Expand university by university, through CR networks and student clubs.

---

## 6. Success numbers

- **Daily active / total users > 40%** (the routine makes this possible)
- 10% of students at launch university in the first semester
- Day-30 retention > 50%
- After R2: % of issues with an authority response, median time to "Solved"

Per-release targets are in [ROADMAP.md §6](docs/ROADMAP.md).

---

## 7. Risks

| Risk | Plan |
|---|---|
| CRs don't adopt it | Make routine setup < 10 minutes; personally onboard first CRs; import from a photo later |
| Reminders unreliable on some Android phones | Test on Xiaomi/Samsung/Realme; battery optimization guide in-app; rolling schedule |
| Students don't trust anonymity | Clear explanation, separated database design, never break it |
| Universities ignore issues | Public scorecards (R4), solved stories, one friendly authority first |
| Harassment / false accusations | No naming individuals, auto filters, fast moderation, takedown process |
| Server failure / data loss | Off-site encrypted backups, monthly restore test ([DEPLOYMENT.md](docs/DEPLOYMENT.md)) |
| Too much scope for a small team | Strict release scope; new ideas go to the backlog |

---

## 8. Next steps

1. Commit the cleanup and the docs (tag the old version first: `git tag v1-archive ac7e422`).
2. Talk to 5 CRs and 10 students: how is the routine shared today, how do they learn about changes, what do they miss?
3. Pick the launch university and recruit the first CRs for beta.
4. Start **R0 Foundation**: monorepo, design system, Supabase on the VPS, sign-in.

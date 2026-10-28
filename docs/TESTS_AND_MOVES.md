# Class moved to another day, and tests & deadlines

Two additions to R1 "My Class" (2026-10-28). Wire contract for the Go API
and the app.

## 1. Move a class to another day

A teacher moves Friday's class to Wednesday. The CR opens Friday's class →
**Change day, time or room** → picks Wednesday (and the time and room).
One change record, one push; Undo removes it.

### API

`routine_changes` gains `new_date date NULL` (migration 00480):
only for `kind = 'moved'`; NULL = same day (time/room change as before).

`POST /groups/{id}/changes` body gains `"newDate": "YYYY-MM-DD"` (optional,
`moved` only). The same date as `date`, or empty, means same day. Rules:
`newDate` from today to today + 180 days; `CHANGE_DATE_INVALID` otherwise.
`start`/`end`/`room` are the class on the new day.

`Change` JSON gains `"newDate": "YYYY-MM-DD" | null`.

`Group.changes` now holds changes whose `date` **or** `newDate` is
yesterday or later (a class moved later must still show on its new day).

Push (to members, as before): EN title `"<code> moved to Wed 30 Oct"`, body
`"10:00–11:30 · Room 402 (was Fri 1 Nov)"`; Bangla with Bangla digits.
`data: {type: "change", groupId}`.

### App

- `ClassChange.newDate`; `ChangeDraft.move(..., newDate)`.
- `classesOn(day)`:
  - on the original date, a moved-to-another-day class is listed with
    `movedTo = newDate` and treated like a cancelled one (no reminder, not the
    "next class"), shown struck through: "Moved to Wed 30 Oct";
  - on `newDate` the class is listed with the change's time and room and
    `movedFrom = date`: "Moved from Fri 1 Nov".
- Reminders follow the class to the new day.
- The change editor gets a **Day** field (default: the class's own date).

## 2. Tests and deadlines

Class tests, quizzes, assignments, lab reports, presentations, mid and final
exams, per class group. **Any member** can add one; the person who added it
and the CRs can edit or delete it.

### API

Table `assessments` (migration 00490): `id, group_id (cascade), kind,
course_code (1–20), course_title (≤100), date, starts_min, ends_min (NULL =
no time / due by end of day), room (≤30), topics (≤500), created_by (user,
SET NULL), created_at, updated_at`.

`kind`: `class_test | quiz | assignment | lab_report | presentation |
midterm | final | other`.

`Assessment` JSON:

```json
{
  "id": "uuid", "kind": "class_test",
  "courseCode": "CSE 101", "courseTitle": "Structured Programming",
  "date": "2026-10-30", "start": "10:00", "end": "10:30",
  "room": "402", "topics": "Chapters 1–3",
  "createdBy": {"id": "uuid", "name": "Rafi"},
  "canEdit": true,
  "updatedAt": "time"
}
```

`start`/`end` may be null; `end` needs `start` and is after it. For an
assignment, `start` is the due time. `createdBy` is null when that account
was deleted. `canEdit`: the caller added it or is a CR.

`Group.assessments`: date yesterday or later, earliest first (date, start).
Courses the caller hides are not filtered by the server (the app hides them).

| Method | Path | Who | Notes |
|---|---|---|---|
| POST | `/groups/{id}/assessments` | member | body `{kind, courseCode, courseTitle?, date, start?, end?, room?, topics?}` → 201 `Assessment` |
| PUT | `/groups/{id}/assessments/{a}` | author or CR | same body → `Assessment` |
| DELETE | `/groups/{id}/assessments/{a}` | author or CR | 204 |

Rules: `date` today … today + 180 days (`ASSESSMENT_DATE_INVALID`); at most
100 upcoming per group (`ASSESSMENT_LIMIT_REACHED`); 30 new per student per
day (rate limit). `ASSESSMENT_NOT_FOUND`, `NOT_ASSESSMENT_OWNER` (403: only
who added it or a CR).

Pushes to the other members, `data: {type: "assessment", groupId}`:
- added: EN `"<code>: Class test on Wed 30 Oct"`, body `"10:00 · Room 402 · Chapters 1–3"`;
- date or time changed: `"<code>: Class test moved to Thu 31 Oct"`;
- deleted (if it was still ahead): `"<code>: Class test cancelled"`.

### App

- `Assessment` model + `AssessmentKind`; `ClassGroup.assessments`
  (kept in the offline copy).
- **Today:** "Coming up" — tests and deadlines in the next 7 days, soonest
  first ("Today", "Tomorrow", "Wed 30 Oct"), course hidden = not shown.
- **Group page:** "Tests & deadlines" list with **Add** for every member;
  tap → details sheet (edit/delete when `canEdit`).
- **Class tile/sheet:** a "Class test" badge when that course has one that day.
- **Reminders** (with the reminders switch and muted courses): 8 PM the
  evening before, and 1 hour before `start` (9 AM that day when no time).
- Push `type: "assessment"` opens the group.
- English and Bangla.

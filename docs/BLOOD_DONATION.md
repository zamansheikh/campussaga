# Blood donation (R2.6): build spec

Students who need blood post a request; donors of that blood group at the
same university get a push and can say "I can donate" in one tap. This is
the contract for the Go API and the Flutter app.

Conventions are the existing ones: error envelope (ARCHITECTURE.md §2),
`httpx` typed handlers, sqlc per module, goose migrations, Bloc/go_router,
`campus_ui` components, EN + BN ARB.

---

## 1. Rules

- **Who**: signed-in students with a university. Posting a request needs a
  **verified** account (university email); others get `VERIFY_REQUIRED`
  (403) and the app sends them to verification. Anyone can become a donor
  and respond.
- **Scope**: requests, donors and pushes stay inside one university.
- **Matching**: a request notifies donors of the **same blood group** only
  (what students expect, and what hospitals cross-match). The request page
  also lists the compatible groups as information.
- **Eligible donor**: `available` is on, and `last_donated` is empty or
  **≥ 120 days** ago (Bangladesh: every 4 months). Not eligible → no push;
  they can still read and respond.
- **Push limits**: at most **300** donors per request; a donor gets at most
  **3** request pushes a day and never two for the same request; never the
  requester.
- **Privacy**:
  - Blood group is health data: shown only on the donor's own profile and,
    when they respond to a request, to that request's requester.
  - Nobody can browse or search donors. The only aggregate is a count
    ("14 A+ donors at JU"), shown on a request.
  - A donor's phone goes only to the requester, only when the donor taps
    "I can donate" (they confirm it).
  - The requester's contact name and phone are visible to students of the
    university (they are asking for help) and can be shared.
- **Lifecycle**: `open` → `fulfilled` (the requester got blood) or `closed`
  (cancelled). Open requests whose `neededBy` is more than 1 day past are
  shown as expired (status stays open in the DB; reads treat them as
  `expired` and they leave the open list).
- **Limits**: 3 requests a day per user, at most 3 open at once
  (`TOO_MANY_OPEN_REQUESTS` 409); 30 responses a day.

Blood groups (wire): `A+ A- B+ B- AB+ AB- O+ O-`.

Compatible donors (red cells) for each patient group:

| Patient | Can receive from |
|---|---|
| O- | O- |
| O+ | O+ O- |
| A- | A- O- |
| A+ | A+ A- O+ O- |
| B- | B- O- |
| B+ | B+ B- O+ O- |
| AB- | AB- A- B- O- |
| AB+ | everyone |

---

## 2. Data model: `00670_blood_donation.sql`

```sql
CREATE TABLE blood_donors (
  user_id      uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  blood_group  text NOT NULL CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  available    boolean NOT NULL DEFAULT true,
  phone        text NOT NULL DEFAULT '' CHECK (char_length(phone) <= 20),
  last_donated date,
  donations    int  NOT NULL DEFAULT 0 CHECK (donations >= 0),
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE blood_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL REFERENCES universities (id),
  requester_id  uuid REFERENCES users (id) ON DELETE SET NULL,
  blood_group   text NOT NULL CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  units         smallint NOT NULL DEFAULT 1 CHECK (units BETWEEN 1 AND 10),
  hospital      text NOT NULL CHECK (char_length(hospital) BETWEEN 2 AND 120),
  area          text NOT NULL DEFAULT '' CHECK (char_length(area) <= 80),
  needed_by     timestamptz NOT NULL,
  urgent        boolean NOT NULL DEFAULT false,
  contact_name  text NOT NULL CHECK (char_length(contact_name) BETWEEN 1 AND 80),
  contact_phone text NOT NULL CHECK (char_length(contact_phone) BETWEEN 6 AND 20),
  note          text NOT NULL DEFAULT '' CHECK (char_length(note) <= 500),
  status        text NOT NULL DEFAULT 'open' CHECK (status IN ('open','fulfilled','closed')),
  notified      int  NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  closed_at     timestamptz
);
CREATE INDEX blood_requests_open_idx ON blood_requests (university_id, status, needed_by);
CREATE INDEX blood_requests_requester_idx ON blood_requests (requester_id, created_at DESC);

CREATE TABLE blood_responses (
  request_id uuid NOT NULL REFERENCES blood_requests (id) ON DELETE CASCADE,
  donor_id   uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  phone      text NOT NULL CHECK (char_length(phone) BETWEEN 6 AND 20),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (request_id, donor_id)
);

-- Who was told about which request (no repeats; the daily cap).
CREATE TABLE blood_notices (
  request_id uuid NOT NULL REFERENCES blood_requests (id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  sent_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (request_id, user_id)
);
CREATE INDEX blood_notices_user_idx ON blood_notices (user_id, sent_at);

UPDATE app_config SET value = jsonb_set(value, '{bloodDonation}', 'true') WHERE key = 'features';
```

Down drops the tables and removes the `bloodDonation` key.

Phones are stored as typed after trimming and checked like the bus
driver's phone (Bangladeshi mobile, Bangla digits allowed; reuse the
transport module's `cleanPhone` rule: `01[3-9]` + 8 digits, optional
`+88`), stored as `01XXXXXXXXX`. Invalid → `VALIDATION_FAILED` on the field.

---

## 3. Wire contract (module `internal/modules/blood`)

All routes: signed-in student group (`r.Student()`), the caller's
university (`UNIVERSITY_REQUIRED` 409 without one). Other universities'
requests answer `BLOOD_REQUEST_NOT_FOUND` (404).

### 3.1 Shapes

```jsonc
// Donor (the caller's own profile)
{
  "bloodGroup": "A+",
  "available": true,
  "phone": "01712345678",
  "lastDonated": "2026-07-01" | null,      // date
  "donations": 3,
  "canDonateFrom": "2026-10-29" | null,    // lastDonated + 120 days; null = now
  "eligible": true                          // available && (no date || ≥ 120 days)
}

// BloodRequest
{
  "id": "uuid",
  "bloodGroup": "A+",
  "units": 2,
  "hospital": "Enam Medical College Hospital",
  "area": "Savar",
  "neededBy": "time",
  "urgent": true,
  "contactName": "Rafi",
  "contactPhone": "01712345678",
  "note": "Thalassemia patient, needs it every month",
  "status": "open" | "fulfilled" | "closed" | "expired",
  "createdAt": "time",
  "responseCount": 2,
  "notified": 14,                // donors told by push (shown to the requester)
  "matchingDonors": 21,          // donors of this group at the university (count only)
  "mine": false,                 // the caller posted it
  "responded": false,            // the caller said "I can donate"
  "responses": [                 // ONLY for the requester; [] for everyone else
    {"name": "Nusrat Jahan", "bloodGroup": "A+", "phone": "01812345678", "createdAt": "time"}
  ]
}
// Page: {"items": [...], "nextCursor": "opaque|null"}
```

### 3.2 Endpoints

| Method | Path | Body / query | Answer | Notes |
|---|---|---|---|---|
| GET | `/blood/me` | | `{"donor": Donor\|null}` | |
| PUT | `/blood/me` | `{bloodGroup, available, phone, lastDonated: "YYYY-MM-DD"\|null}` | Donor | creates or updates; `lastDonated` not in the future |
| DELETE | `/blood/me` | | 204 | stop being a donor (responses stay) |
| POST | `/blood/me/donated` | `{date: "YYYY-MM-DD"}` (default today, Bangladesh) | Donor | `lastDonated = date` (if later), `donations + 1`; `DONOR_REQUIRED` 409 when not a donor |
| GET | `/blood/requests` | `view=open\|mine`, `group` (optional filter, open view), `cursor` | Page of BloodRequest (20) | open: status open and not expired, the caller's university, **urgent first, then neededBy ascending**; mine: the caller's own, every status, newest first |
| POST | `/blood/requests` | `{bloodGroup, units, hospital, area, neededBy, urgent, contactName, contactPhone, note}` | 201 BloodRequest | verified only (`VERIFY_REQUIRED`); `neededBy` from now − 1 h to now + 30 days; 3/day; ≤ 3 open; pushes after commit (§3.3) |
| GET | `/blood/requests/{id}` | | BloodRequest | |
| POST | `/blood/requests/{id}/respond` | `{phone}` | BloodRequest | open, not mine (`CANNOT_RESPOND_OWN` 409), not expired (`REQUEST_CLOSED` 409); the caller must be a donor (`DONOR_REQUIRED` 409); idempotent; saves the phone to the donor profile when it had none; push to the requester |
| DELETE | `/blood/requests/{id}/respond` | | BloodRequest | withdraw |
| POST | `/blood/requests/{id}/close` | `{fulfilled: bool}` | BloodRequest | requester only (`BLOOD_REQUEST_NOT_FOUND` otherwise); open only |

Errors (new): `VERIFY_REQUIRED` 403, `TOO_MANY_OPEN_REQUESTS` 409,
`BLOOD_REQUEST_NOT_FOUND` 404, `REQUEST_CLOSED` 409, `CANNOT_RESPOND_OWN`
409, `DONOR_REQUIRED` 409; plus `VALIDATION_FAILED`, `TOO_MANY_REQUESTS`,
`UNIVERSITY_REQUIRED`.

### 3.3 Pushes (existing push module; `data: {type, requestId}`)

| Type | To | EN title / body | BN title / body |
|---|---|---|---|
| `blood_request` | eligible donors of the group (§1 limits) | "{group} blood needed{, urgent}" / "{hospital}{, area} · {when}" | "{group} রক্ত প্রয়োজন" / same |
| `blood_response` | the requester | "{name} can donate {group}" / "Tap to call" | "{name} রক্ত দিতে পারবেন" / "কল করতে চাপো" |

"{when}" is the needed-by time in Bangladesh time ("today 3:00 PM",
"tomorrow 10:00 AM", or "Nov 4, 10:00 AM"); BN uses Bangla digits.

---

## 4. App

- **Explore**: a "Blood donation" card (shown while `features.bloodDonation`).
- **Blood page** (`/blood`): the donor card on top (not a donor: "Become a
  donor" with one line of why; a donor: the big group badge, available
  switch, "You can donate now" / "You can donate again on …", donations
  count, "I donated today", edit); then **Requests** (open, urgent first;
  a filter chip "My group"); **My requests**. A "Request blood" button.
- **Request form** (`/blood/new`): blood group grid (8 chips), units
  stepper, hospital, area, when (Today / Tomorrow / pick date and time),
  urgent switch, contact name and phone (prefilled), note. Not verified:
  explain and offer Verify. After posting: "Sent to 14 A+ donors".
- **Request page** (`/blood/requests/:id`): big group badge, units,
  hospital and area, when (with "urgent"), note, contact with **Call** and
  **Copy**, **Share** (text for WhatsApp / Facebook groups: group, hospital,
  when, contact, app link), compatible groups line. Donors: "I can donate"
  → confirm sheet (your name and phone go to the requester) → "Thank you"
  + "Call the requester". The requester: responses with Call buttons,
  "Got blood" (fulfilled) and "Cancel request".
- **Today**: when the student is an eligible donor and an open request
  needs their group, a red card "A+ blood needed · Enam Medical · today
  3:00 PM" that opens it.
- **Pushes**: `blood_*` opens the request page.
- l10n EN + BN; blood groups are not translated.

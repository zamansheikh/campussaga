-- +goose Up
-- Blood donation (docs/BLOOD_DONATION.md): donors, requests, responses and
-- who was told about which request.
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

-- +goose Down
UPDATE app_config SET value = value - 'bloodDonation' WHERE key = 'features';
DROP TABLE blood_notices;
DROP TABLE blood_responses;
DROP TABLE blood_requests;
DROP TABLE blood_donors;

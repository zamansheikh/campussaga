-- +goose Up
-- A campaign's point values (docs/GROWTH.md §8): invites plus missions that
-- fill the app. Keys missing from a stored value take these defaults in the API.
ALTER TABLE campaigns ADD COLUMN scoring jsonb NOT NULL DEFAULT
    '{"invite": 10, "otherCampus": 5, "pioneer": 5, "friendSection": 3, "joinSection": 2, "bloodDonor": 3,
      "busShare": 2, "busShareDays": 10, "sectionSetup": 15, "sectionSetupMax": 2, "pioneerFirst": 20}';

-- +goose Down
ALTER TABLE campaigns DROP COLUMN scoring;

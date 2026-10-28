-- +goose Up
-- Photo check (an NSFW classifier on our own server, backend/nsfw): each
-- photo's score, and whether it was flagged for a moderator. NULL score =
-- not checked (development, or the checker was down: then flagged).
ALTER TABLE uploads ADD COLUMN nsfw_score real CHECK (nsfw_score BETWEEN 0 AND 1);
ALTER TABLE uploads ADD COLUMN flagged boolean NOT NULL DEFAULT false;
ALTER TABLE issue_images ADD COLUMN nsfw_score real CHECK (nsfw_score BETWEEN 0 AND 1);
ALTER TABLE issue_images ADD COLUMN flagged boolean NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE issue_images DROP COLUMN flagged;
ALTER TABLE issue_images DROP COLUMN nsfw_score;
ALTER TABLE uploads DROP COLUMN flagged;
ALTER TABLE uploads DROP COLUMN nsfw_score;

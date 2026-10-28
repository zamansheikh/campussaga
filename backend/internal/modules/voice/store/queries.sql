-- Campus Voice. The *_authors tables are read ONLY to answer questions about
-- the caller (user_id = the viewer), for push recipients and ban-author; their
-- user ids never appear in a selected column of a query that feeds a
-- response (docs/CAMPUS_VOICE.md §2.1).

-- name: CampusVoiceOn :one
SELECT coalesce((value->>'campusVoice')::bool, false)::bool AS enabled
FROM app_config WHERE key = 'features';

-- name: Staff :one
SELECT kind, university_id, title FROM staff WHERE user_id = @user_id;

-- name: ActiveBan :one
SELECT until FROM voice_bans WHERE user_id = @user_id AND (until IS NULL OR until > @now::timestamptz);

-- name: UpsertBan :exec
INSERT INTO voice_bans (user_id, until, reason) VALUES (@user_id, sqlc.narg(until), @reason)
ON CONFLICT (user_id) DO UPDATE SET until = EXCLUDED.until, reason = EXCLUDED.reason, created_at = now();

-- ---- issue cards ------------------------------------------------------------------
-- Every card query selects exactly these columns (the rows convert to one type).

-- name: GetIssue :one
SELECT i.id, i.university_id, i.category, i.private, i.title, i.body, i.status, i.visibility,
       i.me_too_count, i.comment_count, i.report_count, i.hold_reason, i.removed_reason,
       i.deleted_by_author, i.named, coalesce(u.display_name, '')::text AS author_name,
       (u.verified_at IS NOT NULL)::bool AS author_verified, (u.id IS NOT NULL)::bool AS author_exists,
       i.location_label, i.created_at, i.status_changed_at, i.solved_at, i.edited_at,
       (SELECT count(*) FROM issue_images im WHERE im.issue_id = i.id)::int AS image_count,
       coalesce((SELECT im.id::text FROM issue_images im WHERE im.issue_id = i.id ORDER BY im.position LIMIT 1), '')::text AS thumbnail,
       EXISTS (SELECT 1 FROM issue_votes v WHERE v.issue_id = i.id AND v.user_id = @viewer)::bool AS voted,
       EXISTS (SELECT 1 FROM issue_follows f WHERE f.issue_id = i.id AND f.user_id = @viewer)::bool AS following,
       EXISTS (SELECT 1 FROM issue_authors a WHERE a.issue_id = i.id AND a.user_id = @viewer)::bool AS mine
FROM issues i
LEFT JOIN users u ON u.id = i.named_author_id
WHERE i.id = @id;

-- name: FeedNew :many
SELECT i.id, i.university_id, i.category, i.private, i.title, i.body, i.status, i.visibility,
       i.me_too_count, i.comment_count, i.report_count, i.hold_reason, i.removed_reason,
       i.deleted_by_author, i.named, coalesce(u.display_name, '')::text AS author_name,
       (u.verified_at IS NOT NULL)::bool AS author_verified, (u.id IS NOT NULL)::bool AS author_exists,
       i.location_label, i.created_at, i.status_changed_at, i.solved_at, i.edited_at,
       (SELECT count(*) FROM issue_images im WHERE im.issue_id = i.id)::int AS image_count,
       coalesce((SELECT im.id::text FROM issue_images im WHERE im.issue_id = i.id ORDER BY im.position LIMIT 1), '')::text AS thumbnail,
       EXISTS (SELECT 1 FROM issue_votes v WHERE v.issue_id = i.id AND v.user_id = @viewer)::bool AS voted,
       EXISTS (SELECT 1 FROM issue_follows f WHERE f.issue_id = i.id AND f.user_id = @viewer)::bool AS following,
       EXISTS (SELECT 1 FROM issue_authors a WHERE a.issue_id = i.id AND a.user_id = @viewer)::bool AS mine
FROM issues i
LEFT JOIN users u ON u.id = i.named_author_id
WHERE i.university_id = @university_id AND i.visibility = 'visible' AND i.private = @private
  AND (@category::text = '' OR i.category = @category)
  AND (@q::text = '' OR i.title ILIKE @q_like OR i.body ILIKE @q_like)
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (i.created_at, i.id) < (sqlc.narg(before_at)::timestamptz, sqlc.narg(before_id)::uuid))
ORDER BY i.created_at DESC, i.id DESC
LIMIT @lim;

-- name: FeedSolved :many
SELECT i.id, i.university_id, i.category, i.private, i.title, i.body, i.status, i.visibility,
       i.me_too_count, i.comment_count, i.report_count, i.hold_reason, i.removed_reason,
       i.deleted_by_author, i.named, coalesce(u.display_name, '')::text AS author_name,
       (u.verified_at IS NOT NULL)::bool AS author_verified, (u.id IS NOT NULL)::bool AS author_exists,
       i.location_label, i.created_at, i.status_changed_at, i.solved_at, i.edited_at,
       (SELECT count(*) FROM issue_images im WHERE im.issue_id = i.id)::int AS image_count,
       coalesce((SELECT im.id::text FROM issue_images im WHERE im.issue_id = i.id ORDER BY im.position LIMIT 1), '')::text AS thumbnail,
       EXISTS (SELECT 1 FROM issue_votes v WHERE v.issue_id = i.id AND v.user_id = @viewer)::bool AS voted,
       EXISTS (SELECT 1 FROM issue_follows f WHERE f.issue_id = i.id AND f.user_id = @viewer)::bool AS following,
       EXISTS (SELECT 1 FROM issue_authors a WHERE a.issue_id = i.id AND a.user_id = @viewer)::bool AS mine
FROM issues i
LEFT JOIN users u ON u.id = i.named_author_id
WHERE i.university_id = @university_id AND i.visibility = 'visible' AND i.private = @private
  AND i.status = 'solved' AND i.solved_at IS NOT NULL
  AND (@category::text = '' OR i.category = @category)
  AND (@q::text = '' OR i.title ILIKE @q_like OR i.body ILIKE @q_like)
  AND (sqlc.narg(before_at)::timestamptz IS NULL OR (i.solved_at, i.id) < (sqlc.narg(before_at)::timestamptz, sqlc.narg(before_id)::uuid))
ORDER BY i.solved_at DESC, i.id DESC
LIMIT @lim;

-- Trending: (me too + 2 × comments + 1) / (hours since posted + 2)^1.5,
-- last 30 days, not solved or rejected. Offset pages.
-- name: FeedTrending :many
SELECT i.id, i.university_id, i.category, i.private, i.title, i.body, i.status, i.visibility,
       i.me_too_count, i.comment_count, i.report_count, i.hold_reason, i.removed_reason,
       i.deleted_by_author, i.named, coalesce(u.display_name, '')::text AS author_name,
       (u.verified_at IS NOT NULL)::bool AS author_verified, (u.id IS NOT NULL)::bool AS author_exists,
       i.location_label, i.created_at, i.status_changed_at, i.solved_at, i.edited_at,
       (SELECT count(*) FROM issue_images im WHERE im.issue_id = i.id)::int AS image_count,
       coalesce((SELECT im.id::text FROM issue_images im WHERE im.issue_id = i.id ORDER BY im.position LIMIT 1), '')::text AS thumbnail,
       EXISTS (SELECT 1 FROM issue_votes v WHERE v.issue_id = i.id AND v.user_id = @viewer)::bool AS voted,
       EXISTS (SELECT 1 FROM issue_follows f WHERE f.issue_id = i.id AND f.user_id = @viewer)::bool AS following,
       EXISTS (SELECT 1 FROM issue_authors a WHERE a.issue_id = i.id AND a.user_id = @viewer)::bool AS mine
FROM issues i
LEFT JOIN users u ON u.id = i.named_author_id
-- (sqlc can't rewrite a parameter inside ORDER BY: the score is computed here.)
CROSS JOIN LATERAL (
    SELECT (i.me_too_count + 2 * i.comment_count + 1)::float8
           / power(greatest(sqlc.arg(now_epoch)::float8 - date_part('epoch', i.created_at), 0) / 3600.0 + 2, 1.5) AS score
) t
WHERE i.university_id = @university_id AND i.visibility = 'visible' AND i.private = @private
  AND i.status NOT IN ('solved', 'rejected') AND i.created_at > @since
  AND (@category::text = '' OR i.category = @category)
  AND (@q::text = '' OR i.title ILIKE @q_like OR i.body ILIKE @q_like)
ORDER BY t.score DESC, i.created_at DESC, i.id DESC
LIMIT @lim OFFSET @off;

-- name: MyIssues :many
SELECT i.id, i.university_id, i.category, i.private, i.title, i.body, i.status, i.visibility,
       i.me_too_count, i.comment_count, i.report_count, i.hold_reason, i.removed_reason,
       i.deleted_by_author, i.named, coalesce(u.display_name, '')::text AS author_name,
       (u.verified_at IS NOT NULL)::bool AS author_verified, (u.id IS NOT NULL)::bool AS author_exists,
       i.location_label, i.created_at, i.status_changed_at, i.solved_at, i.edited_at,
       (SELECT count(*) FROM issue_images im WHERE im.issue_id = i.id)::int AS image_count,
       coalesce((SELECT im.id::text FROM issue_images im WHERE im.issue_id = i.id ORDER BY im.position LIMIT 1), '')::text AS thumbnail,
       EXISTS (SELECT 1 FROM issue_votes v WHERE v.issue_id = i.id AND v.user_id = @viewer)::bool AS voted,
       EXISTS (SELECT 1 FROM issue_follows f WHERE f.issue_id = i.id AND f.user_id = @viewer)::bool AS following,
       true::bool AS mine
FROM issues i
JOIN issue_authors a ON a.issue_id = i.id AND a.user_id = @viewer
LEFT JOIN users u ON u.id = i.named_author_id
WHERE (sqlc.narg(before_at)::timestamptz IS NULL OR (i.created_at, i.id) < (sqlc.narg(before_at)::timestamptz, sqlc.narg(before_id)::uuid))
ORDER BY i.created_at DESC, i.id DESC
LIMIT @lim;

-- name: SimilarIssues :many
SELECT i.id, i.university_id, i.category, i.private, i.title, i.body, i.status, i.visibility,
       i.me_too_count, i.comment_count, i.report_count, i.hold_reason, i.removed_reason,
       i.deleted_by_author, i.named, coalesce(u.display_name, '')::text AS author_name,
       (u.verified_at IS NOT NULL)::bool AS author_verified, (u.id IS NOT NULL)::bool AS author_exists,
       i.location_label, i.created_at, i.status_changed_at, i.solved_at, i.edited_at,
       (SELECT count(*) FROM issue_images im WHERE im.issue_id = i.id)::int AS image_count,
       coalesce((SELECT im.id::text FROM issue_images im WHERE im.issue_id = i.id ORDER BY im.position LIMIT 1), '')::text AS thumbnail,
       EXISTS (SELECT 1 FROM issue_votes v WHERE v.issue_id = i.id AND v.user_id = @viewer)::bool AS voted,
       EXISTS (SELECT 1 FROM issue_follows f WHERE f.issue_id = i.id AND f.user_id = @viewer)::bool AS following,
       EXISTS (SELECT 1 FROM issue_authors a WHERE a.issue_id = i.id AND a.user_id = @viewer)::bool AS mine
FROM issues i
LEFT JOIN users u ON u.id = i.named_author_id
WHERE i.university_id = @university_id AND i.visibility = 'visible' AND NOT i.private
  AND i.created_at > @since AND similarity(i.title, @q::text) > 0.3
ORDER BY similarity(i.title, @q::text) DESC, i.created_at DESC
LIMIT 5;

-- ---- issue details ------------------------------------------------------------------

-- name: IssueImages :many
SELECT id, width, height FROM issue_images WHERE issue_id = @issue_id ORDER BY position;

-- name: GetImage :one
SELECT im.issue_id, im.full_key, im.thumb_key FROM issue_images im WHERE im.id = @id;

-- name: Timeline :many
SELECT actor_kind, actor_title, from_status, to_status, note, created_at
FROM status_updates WHERE issue_id = @issue_id ORDER BY created_at, id;

-- name: LockIssue :one
SELECT * FROM issues WHERE id = @id FOR UPDATE;

-- name: IsIssueAuthor :one
SELECT EXISTS (SELECT 1 FROM issue_authors WHERE issue_id = @issue_id AND user_id = @viewer)::bool;

-- Server-side only (pushes, bans): never returned.
-- name: IssueAuthorID :one
SELECT user_id FROM issue_authors WHERE issue_id = @issue_id;

-- ---- issue writes ---------------------------------------------------------------------

-- name: CreateIssue :one
INSERT INTO issues (university_id, category, private, title, body, location_label, visibility,
                    hold_reason, named, named_author_id, created_at, status_changed_at)
VALUES (@university_id, @category, @private, @title, @body, @location_label, @visibility,
        @hold_reason, @named, sqlc.narg(named_author_id), @now, @now)
RETURNING id;

-- name: InsertIssueAuthor :exec
INSERT INTO issue_authors (issue_id, user_id) VALUES (@issue_id, @user_id);

-- name: UpdateIssueText :exec
UPDATE issues SET title = @title, body = @body, location_label = @location_label, edited_at = @now::timestamptz,
    visibility = @visibility, hold_reason = @hold_reason
WHERE id = @id;

-- name: SetIssueVisibility :exec
UPDATE issues SET visibility = @visibility, hold_reason = @hold_reason, removed_reason = @removed_reason,
    deleted_by_author = deleted_by_author OR @deleted_by_author::bool
WHERE id = @id;

-- name: SetIssueStatus :exec
UPDATE issues SET status = @status, status_changed_at = @now, solved_at = sqlc.narg(solved_at)
WHERE id = @id;

-- name: InsertStatusUpdate :exec
INSERT INTO status_updates (issue_id, actor_kind, actor_title, from_status, to_status, note, created_at)
VALUES (@issue_id, @actor_kind, @actor_title, @from_status, @to_status, @note, @now);

-- name: AdjustIssueCounts :one
UPDATE issues SET me_too_count = me_too_count + @me_too, comment_count = comment_count + @comments,
    report_count = greatest(report_count + @reports, 0)
WHERE id = @id
RETURNING me_too_count, comment_count, report_count;

-- name: ClearIssueReports :exec
UPDATE issues SET report_count = 0 WHERE id = @id;

-- name: Vote :execrows
INSERT INTO issue_votes (issue_id, user_id) VALUES (@issue_id, @user_id) ON CONFLICT DO NOTHING;

-- name: Unvote :execrows
DELETE FROM issue_votes WHERE issue_id = @issue_id AND user_id = @user_id;

-- name: Follow :exec
INSERT INTO issue_follows (issue_id, user_id) VALUES (@issue_id, @user_id) ON CONFLICT DO NOTHING;

-- name: Unfollow :exec
DELETE FROM issue_follows WHERE issue_id = @issue_id AND user_id = @user_id;

-- Server-side only: push recipients.
-- name: Followers :many
SELECT user_id FROM issue_follows WHERE issue_id = @issue_id;

-- ---- photos -----------------------------------------------------------------------------

-- name: InsertUpload :one
INSERT INTO uploads (user_id, full_key, thumb_key, width, height, created_at)
VALUES (@user_id, @full_key, @thumb_key, @width, @height, @now)
RETURNING id, width, height;

-- name: TakeUpload :one
SELECT * FROM uploads WHERE id = @id AND user_id = @user_id FOR UPDATE;

-- name: GetUpload :one
SELECT * FROM uploads WHERE id = @id AND user_id = @user_id;

-- name: DeleteUpload :exec
DELETE FROM uploads WHERE id = @id;

-- name: InsertIssueImage :exec
INSERT INTO issue_images (id, issue_id, position, full_key, thumb_key, width, height)
VALUES (@id, @issue_id, @position, @full_key, @thumb_key, @width, @height);

-- name: ExpiredUploads :many
SELECT id, full_key, thumb_key FROM uploads WHERE created_at < @before LIMIT 500;

-- ---- comments -------------------------------------------------------------------------------

-- name: ListComments :many
SELECT c.id, c.issue_id, c.kind, c.handle, c.official_title, c.named,
       coalesce(u.display_name, '')::text AS author_name, (u.verified_at IS NOT NULL)::bool AS author_verified,
       (u.id IS NOT NULL)::bool AS author_exists,
       c.body, c.visibility, c.hold_reason, c.removed_reason, c.deleted_by_author, c.report_count, c.created_at,
       EXISTS (SELECT 1 FROM comment_authors ca WHERE ca.comment_id = c.id AND ca.user_id = @viewer)::bool AS mine,
       (c.kind = 'student' AND EXISTS (
           SELECT 1 FROM comment_authors ca JOIN issue_authors ia ON ia.user_id = ca.user_id
           WHERE ca.comment_id = c.id AND ia.issue_id = c.issue_id))::bool AS is_issue_author
FROM comments c
LEFT JOIN users u ON u.id = c.named_author_id
WHERE c.issue_id = @issue_id
  AND (@show_all::bool OR c.visibility = 'visible'
       OR EXISTS (SELECT 1 FROM comment_authors ca WHERE ca.comment_id = c.id AND ca.user_id = @viewer))
  AND (sqlc.narg(after_at)::timestamptz IS NULL OR (c.created_at, c.id) > (sqlc.narg(after_at)::timestamptz, sqlc.narg(after_id)::uuid))
ORDER BY c.created_at, c.id
LIMIT @lim;

-- name: GetComment :one
SELECT c.id, c.issue_id, c.kind, c.handle, c.official_title, c.named,
       coalesce(u.display_name, '')::text AS author_name, (u.verified_at IS NOT NULL)::bool AS author_verified,
       (u.id IS NOT NULL)::bool AS author_exists,
       c.body, c.visibility, c.hold_reason, c.removed_reason, c.deleted_by_author, c.report_count, c.created_at,
       EXISTS (SELECT 1 FROM comment_authors ca WHERE ca.comment_id = c.id AND ca.user_id = @viewer)::bool AS mine,
       (c.kind = 'student' AND EXISTS (
           SELECT 1 FROM comment_authors ca JOIN issue_authors ia ON ia.user_id = ca.user_id
           WHERE ca.comment_id = c.id AND ia.issue_id = c.issue_id))::bool AS is_issue_author
FROM comments c
LEFT JOIN users u ON u.id = c.named_author_id
WHERE c.id = @id;

-- name: CreateComment :one
INSERT INTO comments (issue_id, kind, handle, official_title, named, named_author_id, body, visibility, hold_reason, created_at)
VALUES (@issue_id, @kind, @handle, @official_title, @named, sqlc.narg(named_author_id), @body, @visibility, @hold_reason, @now)
RETURNING id;

-- name: InsertCommentAuthor :exec
INSERT INTO comment_authors (comment_id, user_id) VALUES (@comment_id, @user_id);

-- name: LockComment :one
SELECT * FROM comments WHERE id = @id FOR UPDATE;

-- name: IsCommentAuthor :one
SELECT EXISTS (SELECT 1 FROM comment_authors WHERE comment_id = @comment_id AND user_id = @viewer)::bool;

-- Server-side only: ban-author.
-- name: CommentAuthorID :one
SELECT user_id FROM comment_authors WHERE comment_id = @comment_id;

-- name: SetCommentVisibility :exec
UPDATE comments SET visibility = @visibility, hold_reason = @hold_reason, removed_reason = @removed_reason,
    deleted_by_author = deleted_by_author OR @deleted_by_author::bool
WHERE id = @id;

-- name: AdjustCommentReports :one
UPDATE comments SET report_count = greatest(report_count + @delta, 0) WHERE id = @id RETURNING report_count;

-- name: ClearCommentReports :exec
UPDATE comments SET report_count = 0 WHERE id = @id;

-- ---- reports ----------------------------------------------------------------------------------

-- name: InsertReport :one
INSERT INTO reports (target_type, target_id, issue_id, reason, details, created_at)
VALUES (@target_type, @target_id, @issue_id, @reason, @details, @now)
RETURNING id;

-- name: InsertReportAuthor :exec
INSERT INTO report_authors (report_id, user_id, target_id) VALUES (@report_id, @user_id, @target_id);

-- name: OpenReasons :many
SELECT reason, count(*)::int AS n FROM reports
WHERE target_id = @target_id AND state = 'open' GROUP BY reason ORDER BY reason;

-- name: ResolveReports :execrows
UPDATE reports SET state = @state, resolved_at = @now::timestamptz WHERE target_id = @target_id AND state = 'open';

-- name: IssueReports :many
SELECT target_type, target_id, reason, details, state, created_at
FROM reports WHERE issue_id = @issue_id ORDER BY created_at DESC LIMIT 200;

-- ---- moderation queue -------------------------------------------------------------------------

-- name: Queue :many
SELECT q.target_type, q.issue_id, q.comment_id, q.university_id, q.hold_reason, q.created_at
FROM (
    SELECT 'issue'::text AS target_type, i.id AS issue_id, NULL::uuid AS comment_id, i.university_id,
           i.hold_reason, i.created_at
    FROM issues i
    WHERE (@kind::text = 'held' AND i.visibility = 'held')
       OR (@kind::text = 'hidden' AND i.visibility = 'hidden')
       OR (@kind::text = 'reported' AND i.report_count > 0 AND i.visibility <> 'removed')
       OR (@kind::text = 'private' AND i.private AND i.visibility <> 'removed')
    UNION ALL
    SELECT 'comment'::text, c.issue_id, c.id, i.university_id, c.hold_reason, c.created_at
    FROM comments c JOIN issues i ON i.id = c.issue_id
    WHERE (@kind::text = 'held' AND c.visibility = 'held')
       OR (@kind::text = 'hidden' AND c.visibility = 'hidden')
       OR (@kind::text = 'reported' AND c.report_count > 0 AND c.visibility <> 'removed')
) q
WHERE (sqlc.narg(university_id)::uuid IS NULL OR q.university_id = sqlc.narg(university_id)::uuid)
ORDER BY q.created_at DESC, q.issue_id
LIMIT @lim OFFSET @off;

-- name: UniversityRef :one
SELECT id, slug, name FROM universities WHERE id = @id;

-- name: InsertAudit :exec
INSERT INTO audit_log (actor_id, action, target_type, target_id, meta)
VALUES (@actor_id, @action, @target_type, @target_id, @meta);

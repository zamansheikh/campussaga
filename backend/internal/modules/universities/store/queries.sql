-- Demo universities (app-store reviewers) are never listed.
-- name: ListActive :many
SELECT u.id, u.slug, u.name, u.name_bn, u.city, u.timezone, u.week_start,
       coalesce(array_agg(d.domain ORDER BY d.domain) FILTER (WHERE d.domain IS NOT NULL), '{}')::text[] AS domains
FROM universities u
LEFT JOIN university_domains d ON d.university_id = u.id
WHERE u.is_active AND NOT u.is_demo
GROUP BY u.id
ORDER BY u.name;

-- The longest matching domain wins (cse.du.ac.bd before du.ac.bd).
-- @candidates is the email host and each of its parent domains.
-- name: MatchDomain :one
SELECT u.id, u.slug, u.name, u.name_bn, u.is_demo
FROM university_domains d
JOIN universities u ON u.id = d.university_id
WHERE d.domain = ANY(@candidates::text[]) AND u.is_active
ORDER BY length(d.domain) DESC
LIMIT 1;

-- name: GetUniversity :one
SELECT u.id, u.slug, u.name, u.name_bn, u.city, u.is_demo,
       coalesce((SELECT array_agg(d.domain ORDER BY d.domain) FROM university_domains d WHERE d.university_id = u.id), '{}')::text[] AS domains
FROM universities u WHERE u.id = @id;

-- ---- visit other campuses (docs/CAMPUS_VISITS.md §3.3) ---------------------------
-- Counts are plain subqueries; posts7d counts what a visitor could read.

-- name: VisitCampusOn :one
SELECT coalesce((value->>'visitCampus')::bool, false)::bool AS enabled
FROM app_config WHERE key = 'features';

-- Active, non-demo universities except the caller's own, most active first.
-- name: ListCampuses :many
SELECT u.id, u.slug, u.name, u.name_bn, u.city, u.kind, u.website,
       (SELECT count(*) FROM users x WHERE x.university_id = u.id)::int AS students,
       (SELECT count(*) FROM issues i
         WHERE i.university_id = u.id AND i.kind <> 'issue' AND i.visibility = 'visible'
           AND NOT i.private AND NOT i.campus_only AND i.created_at > @since)::int AS posts7d
FROM universities u
WHERE u.is_active AND NOT u.is_demo AND u.id <> @own
  AND (@q::text = '' OR u.name ILIKE @q_like OR u.name_bn ILIKE @q_like OR u.slug ILIKE @q_like OR u.city ILIKE @q_like)
ORDER BY posts7d DESC, students DESC, u.name, u.id
LIMIT @lim OFFSET @off;

-- name: GetCampus :one
SELECT u.id, u.slug, u.name, u.name_bn, u.city, u.kind, u.website,
       (SELECT count(*) FROM users x WHERE x.university_id = u.id)::int AS students,
       (SELECT count(*) FROM issues i
         WHERE i.university_id = u.id AND i.kind <> 'issue' AND i.visibility = 'visible'
           AND NOT i.private AND NOT i.campus_only AND i.created_at > @since)::int AS posts7d,
       (SELECT count(*) FROM class_groups g WHERE g.university_id = u.id)::int AS class_groups,
       (SELECT count(*) FROM bus_routes b WHERE b.university_id = u.id AND b.active)::int AS bus_routes
FROM universities u
WHERE u.slug = @slug AND u.is_active AND NOT u.is_demo;

-- name: ListActive :many
SELECT u.id, u.slug, u.name, u.name_bn, u.city, u.timezone, u.week_start,
       coalesce(array_agg(d.domain ORDER BY d.domain) FILTER (WHERE d.domain IS NOT NULL), '{}')::text[] AS domains
FROM universities u
LEFT JOIN university_domains d ON d.university_id = u.id
WHERE u.is_active
GROUP BY u.id
ORDER BY u.name;

-- The longest matching domain wins (cse.du.ac.bd before du.ac.bd).
-- @candidates is the email host and each of its parent domains.
-- name: MatchDomain :one
SELECT u.id, u.slug, u.name, u.name_bn
FROM university_domains d
JOIN universities u ON u.id = d.university_id
WHERE d.domain = ANY(@candidates::text[]) AND u.is_active
ORDER BY length(d.domain) DESC
LIMIT 1;

-- name: GetUniversity :one
SELECT u.id, u.slug, u.name, u.name_bn, u.city,
       coalesce((SELECT array_agg(d.domain ORDER BY d.domain) FROM university_domains d WHERE d.university_id = u.id), '{}')::text[] AS domains
FROM universities u WHERE u.id = @id;

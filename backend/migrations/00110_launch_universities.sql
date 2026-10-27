-- +goose Up
-- Launch universities. Add more with a new migration (never edit this one
-- once shipped). Domains cover every subdomain too (x@cse.diu.edu.bd).
INSERT INTO universities (slug, name, name_bn, city) VALUES
    ('diu', 'Daffodil International University', 'ড্যাফোডিল ইন্টারন্যাশনাল ইউনিভার্সিটি', 'Dhaka')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO university_domains (domain, university_id)
SELECT d.domain, u.id FROM (VALUES
    ('diu.edu.bd', 'diu')
) AS d(domain, slug) JOIN universities u ON u.slug = d.slug
ON CONFLICT (domain) DO NOTHING;

-- +goose Down
DELETE FROM university_domains WHERE domain IN ('diu.edu.bd');
DELETE FROM universities WHERE slug = 'diu';

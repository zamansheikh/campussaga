-- Development data only. Load with `make seed`. Never run in production.
-- Sign in locally with any address at these domains; the code arrives in
-- Mailpit (http://localhost:58025) and in the server log.
INSERT INTO universities (slug, name, name_bn, city) VALUES
    ('demo-university', 'Demo University', 'ডেমো বিশ্ববিদ্যালয়', 'Dhaka'),
    ('sample-institute', 'Sample Institute of Technology', 'স্যাম্পল ইনস্টিটিউট অব টেকনোলজি', 'Chattogram')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO university_domains (domain, university_id)
SELECT d.domain, u.id FROM (VALUES
    ('demo.ac.bd', 'demo-university'),
    ('sit.edu.bd', 'sample-institute')
) AS d(domain, slug) JOIN universities u ON u.slug = d.slug
ON CONFLICT (domain) DO NOTHING;

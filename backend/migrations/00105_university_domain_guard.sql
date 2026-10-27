-- +goose Up
-- A university domain must belong to ONE institution. Shared suffixes and
-- free mail providers would let anyone in (x@gmail.com, x@anything.ac.bd),
-- so the database refuses them, whoever adds the row.
ALTER TABLE university_domains ADD CONSTRAINT university_domains_not_shared CHECK (
    domain NOT IN (
        -- Bangladesh second-level suffixes
        'ac.bd', 'edu.bd', 'gov.bd', 'com.bd', 'org.bd', 'net.bd', 'mil.bd',
        'info.bd', 'co.bd', 'sw.bd', 'tv.bd',
        -- generic top-level domains
        'edu', 'com', 'org', 'net', 'ac', 'info', 'io', 'me', 'bd',
        -- free email providers
        'gmail.com', 'googlemail.com', 'yahoo.com', 'ymail.com', 'outlook.com',
        'hotmail.com', 'live.com', 'msn.com', 'icloud.com', 'me.com', 'aol.com',
        'proton.me', 'protonmail.com', 'zoho.com', 'gmx.com', 'mail.com',
        'yandex.com', 'rediffmail.com'
    )
    AND domain NOT LIKE 'yahoo.%' AND domain NOT LIKE 'hotmail.%' AND domain NOT LIKE 'outlook.%'
);

-- +goose Down
ALTER TABLE university_domains DROP CONSTRAINT university_domains_not_shared;

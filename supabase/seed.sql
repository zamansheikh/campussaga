-- Local development data only. Never runs in production.
-- Sign in locally with any address at one of these domains; read the OTP
-- code in Mailpit (http://127.0.0.1:54324).

insert into public.universities (slug, name, name_bn, email_domains, city) values
  ('demo-university', 'Demo University', 'ডেমো বিশ্ববিদ্যালয়', '{demo.ac.bd}', 'Dhaka'),
  ('sample-institute', 'Sample Institute of Technology', 'স্যাম্পল ইনস্টিটিউট অব টেকনোলজি', '{sit.edu.bd}', 'Chattogram');

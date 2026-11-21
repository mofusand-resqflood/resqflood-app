$seed = @'
-- ResQFlood demo data for RQF-299 (resident story 4).
-- Requires develop's 001_resident_schema.sql + 002_rls_policies.sql.
-- Idempotent: fixed UUIDs + ON CONFLICT, so supabase db reset and a manual
-- re-run both converge on the same rows. Assumes a clean database.
begin;

-- 1. Demo identities (blocked_roads.reporter_id is NOT NULL)
insert into auth.users (id, instance_id, aud, role, phone, phone_confirmed_at, created_at, updated_at)
values
('a0000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','+60123450001', now(), now(), now()),
('a0000000-0000-4000-8000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','+60123450002', now(), now(), now()),
('c0000000-0000-4000-8000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','+60123450003', now(), now(), now())
on conflict (id) do nothing;

insert into public.profiles (
id, role, full_name, phone, address, language_code,
adults, elderly, children, disabled, medical_notes, mobility_notes
)
values
(
'a0000000-0000-4000-8000-000000000001','resident','Nur Aisyah binti Rahman','+60123450001',
'No. 12, Jalan Seri Muda 3, Taman Sri Muda, 40400 Shah Alam, Selangor','ms',
2, 1, 1, 0,
'One elderly resident has hypertension and takes daily medication.',
'Grandmother uses a walking frame; needs ground-floor access.'
),
(
'a0000000-0000-4000-8000-000000000002','resident','Lim Wei Jie','+60123450002',
'No. 8, Jalan Bukit Kuda 2, 41300 Klang, Selangor','en',
1, 0, 0, 0, '', ''
),
(
'c0000000-0000-4000-8000-000000000001','first_responder','Siti Nurhaliza binti Osman','+60123450003',
'Balai Bomba dan Penyelamat Shah Alam, Seksyen 15, 40200 Shah Alam, Selangor','ms',
0, 0, 0, 0, '', ''
)
on conflict (id) do update set
role = excluded.role,
full_name = excluded.full_name,
phone = excluded.phone,
address = excluded.address,
language_code = excluded.language_code,
adults = excluded.adults,
elderly = excluded.elderly,
children = excluded.children,
disabled = excluded.disabled,
medical_notes = excluded.medical_notes,
mobility_notes = excluded.mobility_notes;

-- 2. Three sample shelters with capacity: one open, one full, one closed
insert into public.shelters (id, name, address, latitude, longitude, capacity, current_occupancy, status)
values
('5e1e0000-0000-4000-8000-000000000001','SMK Seksyen 7 Shah Alam',
'Jalan Platinum 7/1, Seksyen 7, 40000 Shah Alam, Selangor',
3.073800, 101.518300, 300, 150, 'open'),
('5e1e0000-0000-4000-8000-000000000002','Dewan Serbaguna Klang',
'Jalan Meru, 41050 Klang, Selangor',
3.044900, 101.445600, 200, 200, 'full'),
('5e1e0000-0000-4000-8000-000000000003','Dewan MBPJ Petaling Jaya',
'Jalan Yong Shook Lin, 46200 Petaling Jaya, Selangor',
3.107300, 101.606700, 100, 0, 'closed')
on conflict (id) do update set
name = excluded.name, address = excluded.address,
latitude = excluded.latitude, longitude = excluded.longitude,
capacity = excluded.capacity, current_occupancy = excluded.current_occupancy,
status = excluded.status;

-- 3. Two coordinator announcements (published, or RLS hides them)
insert into public.announcements (id, title, body, created_by, is_published, published_at, expires_at)
values
('a0a00000-0000-4000-8000-000000000001','Water levels rising in Taman Sri Muda',
'Residents of Taman Sri Muda are advised to move to SMK Seksyen 7 Shah Alam now. Avoid Jalan Kebun and Jalan Klang-Banting. Bring identification and medication.',
'c0000000-0000-4000-8000-000000000001', true,
now() - interval '45 minutes', now() + interval '3 days'),
('a0a00000-0000-4000-8000-000000000002','Supply drop at Dewan Serbaguna Klang, 3:00 PM',
'Food and drinking water will be distributed from 3:00 PM. Bring your household PPS QR pass so the shelter team can register you quickly.',
'c0000000-0000-4000-8000-000000000001', true,
now() - interval '2 hours', null)
on conflict (id) do update set
title = excluded.title, body = excluded.body, created_by = excluded.created_by,
is_published = excluded.is_published, published_at = excluded.published_at,
expires_at = excluded.expires_at;

-- 4. Three road closures, verified (status must be 'verified' to pass RLS)
insert into public.blocked_roads (
id, reporter_id, road_name, note, latitude, longitude, status, verified_by, verified_at
)
values
('b0b00000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000001',
'Jalan Kebun, Klang','Flash flood across both lanes, water about 1 m. Not passable by car.',
3.020000, 101.470000,'verified','c0000000-0000-4000-8000-000000000001', now() - interval '40 minutes'),
('b0b00000-0000-4000-8000-000000000002','a0000000-0000-4000-8000-000000000001',
'Jalan Klang-Banting','Fallen tree blocking both lanes near the bridge.',
2.989800, 101.430000,'verified','c0000000-0000-4000-8000-000000000001', now() - interval '90 minutes'),
('b0b00000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000002',
'Persiaran Kayangan, Shah Alam','Road surface collapse after the culvert overflow. One lane closed.',
3.045000, 101.450000,'verified','c0000000-0000-4000-8000-000000000001', now() - interval '3 hours')
on conflict (id) do update set
reporter_id = excluded.reporter_id, road_name = excluded.road_name, note = excluded.note,
latitude = excluded.latitude, longitude = excluded.longitude, status = excluded.status,
verified_by = excluded.verified_by, verified_at = excluded.verified_at;

commit;

select 'shelters' as table_name, count() as rows from public.shelters
union all select 'announcements (published)', count() from public.announcements where is_published
union all select 'blocked roads (verified)', count() from public.blocked_roads where status = 'verified'
union all select 'profiles', count() from public.profiles;
'@
[System.IO.File]::WriteAllText("$PWD\supabase\seed.sql", $seed, (New-Object System.Text.UTF8Encoding($false)))
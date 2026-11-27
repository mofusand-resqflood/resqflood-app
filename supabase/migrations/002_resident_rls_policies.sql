-- Remove broad client access before granting the operations needed by the app.
REVOKE ALL PRIVILEGES ON TABLE
  public.profiles,
  public.requests,
  public.announcements,
  public.blocked_roads,
  public.shelters
FROM PUBLIC, anon, authenticated;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_roads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shelters ENABLE ROW LEVEL SECURITY;


-- The timestamp trigger function is in a non-API schema.
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE
ON FUNCTION private.set_updated_at()
TO authenticated;


-- Profiles: authenticated users can read their own profile and edit
-- profile/household fields only. The role column is deliberately excluded
-- from both INSERT and UPDATE privileges.
GRANT SELECT ON public.profiles TO authenticated;

GRANT INSERT (
  id,
  full_name,
  phone,
  address,
  language_code,
  adults,
  elderly,
  children,
  disabled,
  medical_notes,
  mobility_notes
)
ON public.profiles TO authenticated;

GRANT UPDATE (
  full_name,
  phone,
  address,
  language_code,
  adults,
  elderly,
  children,
  disabled,
  medical_notes,
  mobility_notes
)
ON public.profiles TO authenticated;


-- Requests: residents may read their own requests, create their own pending
-- requests, and update only the status column to cancel an active request.
GRANT SELECT ON public.requests TO authenticated;

GRANT INSERT (
  resident_id,
  description,
  voice_transcript,
  help_type,
  victim_categories,
  people_count,
  latitude,
  longitude,
  location_accuracy_m,
  photo_path,
  water_depth_category,
  water_depth_min_m,
  water_depth_max_m
)
ON public.requests TO authenticated;

GRANT UPDATE (status)
ON public.requests TO authenticated;


-- Announcements: authenticated users may read published, non-expired notices.
GRANT SELECT ON public.announcements TO authenticated;


-- Blocked roads: residents may read verified reports and their own reports.
-- They may submit a report, but cannot set its status or edit/delete it.
GRANT SELECT ON public.blocked_roads TO authenticated;

GRANT INSERT (
  reporter_id,
  road_name,
  note,
  latitude,
  longitude,
  photo_path
)
ON public.blocked_roads TO authenticated;


-- Shelters: authenticated users may read shared shelter information.
GRANT SELECT ON public.shelters TO authenticated;


-- Remove any earlier versions of these named policies before creating them.
DROP POLICY IF EXISTS profiles_select_own
  ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_own_resident
  ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own
  ON public.profiles;

DROP POLICY IF EXISTS requests_select_own
  ON public.requests;
DROP POLICY IF EXISTS requests_insert_own_pending
  ON public.requests;
DROP POLICY IF EXISTS requests_cancel_own
  ON public.requests;

DROP POLICY IF EXISTS announcements_select_published
  ON public.announcements;

DROP POLICY IF EXISTS blocked_roads_select_verified_or_own
  ON public.blocked_roads;
DROP POLICY IF EXISTS blocked_roads_insert_own_pending
  ON public.blocked_roads;

DROP POLICY IF EXISTS shelters_select_authenticated
  ON public.shelters;


-- Profiles

CREATE POLICY profiles_select_own
ON public.profiles
FOR SELECT
TO authenticated
USING (id = (SELECT auth.uid()));

CREATE POLICY profiles_insert_own_resident
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (
  id = (SELECT auth.uid())
  AND role = 'resident'
);

CREATE POLICY profiles_update_own
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = (SELECT auth.uid()))
WITH CHECK (id = (SELECT auth.uid()));

-- There is intentionally no profile DELETE policy.


-- Requests

CREATE POLICY requests_select_own
ON public.requests
FOR SELECT
TO authenticated
USING (resident_id = (SELECT auth.uid()));

CREATE POLICY requests_insert_own_pending
ON public.requests
FOR INSERT
TO authenticated
WITH CHECK (
  resident_id = (SELECT auth.uid())
  AND status = 'pending'
);

CREATE POLICY requests_cancel_own
ON public.requests
FOR UPDATE
TO authenticated
USING (
  resident_id = (SELECT auth.uid())
  AND status NOT IN ('rescued', 'closed', 'cancelled')
)
WITH CHECK (
  resident_id = (SELECT auth.uid())
  AND status IN ('cancelled', 'closed')
);

-- There is intentionally no request DELETE policy.


-- Announcements

CREATE POLICY announcements_select_published
ON public.announcements
FOR SELECT
TO authenticated
USING (
  is_published = true
  AND (published_at IS NULL OR published_at <= now())
  AND (expires_at IS NULL OR expires_at > now())
);


-- Blocked-road reports

CREATE POLICY blocked_roads_select_verified_or_own
ON public.blocked_roads
FOR SELECT
TO authenticated
USING (
  status = 'verified'
  OR reporter_id = (SELECT auth.uid())
);

CREATE POLICY blocked_roads_insert_own_pending
ON public.blocked_roads
FOR INSERT
TO authenticated
WITH CHECK (
  reporter_id = (SELECT auth.uid())
  AND status = 'pending'
);

-- There are intentionally no blocked-road UPDATE or DELETE policies.


-- Shelters

CREATE POLICY shelters_select_authenticated
ON public.shelters
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) IS NOT NULL);

-- No resident write policies are provided for announcements or shelters.
-- Add First Responder and Shelter Manager policies in their own later
-- migrations; do not grant staff roles from the client app.
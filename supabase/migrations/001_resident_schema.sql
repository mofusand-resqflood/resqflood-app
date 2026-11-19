-- Shared ResQFlood schema.
-- All three application roles are represented in profiles.role.
-- This migration does not grant users the ability to assign themselves a role.

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  NEW.updated_at := pg_catalog.now();
  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.set_updated_at()
FROM PUBLIC, anon, authenticated;


-- One profile per Supabase Auth user.
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,

  role text NOT NULL DEFAULT 'resident'
    CHECK (role IN ('resident', 'first_responder', 'shelter_manager')),

  full_name text NOT NULL DEFAULT '',
  phone text,
  address text NOT NULL DEFAULT '',
  language_code text NOT NULL DEFAULT 'en'
    CHECK (language_code IN ('en', 'ms')),

  adults integer NOT NULL DEFAULT 0 CHECK (adults >= 0),
  elderly integer NOT NULL DEFAULT 0 CHECK (elderly >= 0),
  children integer NOT NULL DEFAULT 0 CHECK (children >= 0),
  disabled integer NOT NULL DEFAULT 0 CHECK (disabled >= 0),

  medical_notes text NOT NULL DEFAULT '',
  mobility_notes text NOT NULL DEFAULT '',

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


-- Resident distress/rescue requests. Future responder policies can add
-- controlled access to assigned requests without changing the table.
CREATE TABLE public.requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  resident_id uuid NOT NULL DEFAULT auth.uid()
    REFERENCES public.profiles (id) ON DELETE CASCADE,

  status text NOT NULL DEFAULT 'pending'
    CHECK (
      status IN (
        'pending',
        'acknowledged',
        'assigned',
        'on_the_way',
        'on_scene',
        'transporting',
        'rescued',
        'closed',
        'cancelled'
      )
    ),

  description text NOT NULL DEFAULT '',
  voice_transcript text,
  help_type text,
  victim_categories text[] NOT NULL DEFAULT ARRAY[]::text[],
  people_count integer NOT NULL DEFAULT 1 CHECK (people_count > 0),

  latitude double precision,
  longitude double precision,
  location_accuracy_m double precision
    CHECK (location_accuracy_m IS NULL OR location_accuracy_m >= 0),

  photo_path text,
  water_depth_category text,
  water_depth_min_m numeric(7, 3)
    CHECK (water_depth_min_m IS NULL OR water_depth_min_m >= 0),
  water_depth_max_m numeric(7, 3)
    CHECK (water_depth_max_m IS NULL OR water_depth_max_m >= 0),

  priority text
    CHECK (priority IS NULL OR priority IN ('critical', 'high', 'normal')),

  assigned_responder_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  last_known_eta_minutes integer
    CHECK (
      last_known_eta_minutes IS NULL OR last_known_eta_minutes >= 0
    ),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
  CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
  CHECK (
    water_depth_min_m IS NULL
    OR water_depth_max_m IS NULL
    OR water_depth_min_m <= water_depth_max_m
  )
);


-- Coordinator/official announcements shared with authenticated users.
CREATE TABLE public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  title text NOT NULL,
  body text NOT NULL,
  created_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,

  is_published boolean NOT NULL DEFAULT false,
  published_at timestamptz,
  expires_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CHECK (expires_at IS NULL OR published_at IS NULL OR expires_at > published_at)
);


-- Resident-submitted blocked-road reports.
CREATE TABLE public.blocked_roads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  reporter_id uuid NOT NULL DEFAULT auth.uid()
    REFERENCES public.profiles (id) ON DELETE CASCADE,

  road_name text NOT NULL,
  note text NOT NULL DEFAULT '',
  latitude double precision NOT NULL
    CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL
    CHECK (longitude BETWEEN -180 AND 180),
  photo_path text,

  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'verified', 'rejected')),

  verified_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  verified_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


-- Shared shelter information. Shelter Manager write policies can be
-- introduced later in a separate migration.
CREATE TABLE public.shelters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  name text NOT NULL,
  address text NOT NULL DEFAULT '',
  latitude double precision NOT NULL
    CHECK (latitude BETWEEN -90 AND 90),
  longitude double precision NOT NULL
    CHECK (longitude BETWEEN -180 AND 180),

  capacity integer NOT NULL DEFAULT 0 CHECK (capacity >= 0),
  current_occupancy integer NOT NULL DEFAULT 0
    CHECK (current_occupancy >= 0),

  status text NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'nearly_full', 'full', 'closed')),

  redirect_to uuid REFERENCES public.shelters (id) ON DELETE SET NULL,

  contact_phone text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


CREATE INDEX requests_resident_created_at_idx
  ON public.requests (resident_id, created_at DESC);

CREATE INDEX announcements_published_expires_idx
  ON public.announcements (is_published, published_at, expires_at);

CREATE INDEX blocked_roads_status_created_at_idx
  ON public.blocked_roads (status, created_at DESC);

CREATE INDEX shelters_status_idx
  ON public.shelters (status);


CREATE TRIGGER profiles_set_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER requests_set_updated_at
BEFORE UPDATE ON public.requests
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER announcements_set_updated_at
BEFORE UPDATE ON public.announcements
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER blocked_roads_set_updated_at
BEFORE UPDATE ON public.blocked_roads
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER shelters_set_updated_at
BEFORE UPDATE ON public.shelters
FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();
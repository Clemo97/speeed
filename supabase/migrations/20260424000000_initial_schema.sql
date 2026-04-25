-- Migration: 20260424000000_initial_schema.sql
-- Creates all Speeed tables.

-- ============================================================
-- profiles — extends auth.users
-- ============================================================
CREATE TABLE public.profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username      TEXT UNIQUE NOT NULL,
    display_name  TEXT,
    avatar_url    TEXT,
    bio           TEXT,
    is_public     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- runs
-- ============================================================
CREATE TABLE public.runs (
    id                           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title                        TEXT,
    status                       TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed')),
    start_time                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time                     TIMESTAMPTZ,
    distance_meters              DOUBLE PRECISION NOT NULL DEFAULT 0,
    duration_seconds             DOUBLE PRECISION NOT NULL DEFAULT 0,
    average_pace_seconds_per_km  DOUBLE PRECISION NOT NULL DEFAULT 0,
    is_public                    BOOLEAN NOT NULL DEFAULT TRUE,
    encoded_polyline             TEXT,
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_runs_user_id ON public.runs(user_id);
CREATE INDEX idx_runs_start_time ON public.runs(start_time DESC);

-- ============================================================
-- run_locations — GPS track points
-- ============================================================
CREATE TABLE public.run_locations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id      UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
    latitude    DOUBLE PRECISION NOT NULL,
    longitude   DOUBLE PRECISION NOT NULL,
    altitude    DOUBLE PRECISION NOT NULL DEFAULT 0,
    speed       DOUBLE PRECISION NOT NULL DEFAULT 0,
    sequence    INTEGER NOT NULL DEFAULT 0,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_run_locations_run_sequence ON public.run_locations(run_id, sequence);

-- ============================================================
-- follows
-- ============================================================
CREATE TABLE public.follows (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX idx_follows_follower ON public.follows(follower_id);
CREATE INDEX idx_follows_following ON public.follows(following_id);

-- ============================================================
-- kudos
-- ============================================================
CREATE TABLE public.kudos (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_id     UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (run_id, user_id)
);

CREATE INDEX idx_kudos_run_id ON public.kudos(run_id);

-- ============================================================
-- segments
-- ============================================================
CREATE TABLE public.segments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name             TEXT NOT NULL,
    encoded_polyline TEXT NOT NULL,
    distance_meters  DOUBLE PRECISION NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- segment_efforts
-- ============================================================
CREATE TABLE public.segment_efforts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    segment_id      UUID NOT NULL REFERENCES public.segments(id) ON DELETE CASCADE,
    run_id          UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    elapsed_seconds DOUBLE PRECISION NOT NULL,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_segment_efforts_segment ON public.segment_efforts(segment_id, elapsed_seconds);

-- ============================================================
-- notifications
-- ============================================================
CREATE TABLE public.notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    actor_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type       TEXT NOT NULL CHECK (type IN ('kudos', 'new_follower', 'segment_record')),
    entity_id  UUID NOT NULL,
    is_read    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_read ON public.notifications(user_id, is_read);

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.run_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.segment_efforts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

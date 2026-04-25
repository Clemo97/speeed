-- Migration: 20260424000002_triggers.sql
-- Triggers and functions for Speeed.
-- SECURITY DEFINER functions are placed in a private schema (not public)
-- to prevent them from being called via the Data API.

-- ============================================================
-- Private schema for security-definer functions
-- ============================================================
CREATE SCHEMA IF NOT EXISTS private;

-- ============================================================
-- Auto-create profile on user sign-up
-- ============================================================
-- Uses raw_user_meta_data for INITIAL population only (username/avatar from OAuth).
-- Never used for ongoing authorization logic.

CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'preferred_username',
            NEW.raw_user_meta_data->>'user_name',
            split_part(COALESCE(NEW.email, NEW.id::text), '@', 1)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name'
        ),
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION private.handle_new_user();

-- ============================================================
-- Auto-update profiles.updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION private.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION private.set_updated_at();

-- ============================================================
-- Notification trigger: kudos
-- ============================================================
CREATE OR REPLACE FUNCTION private.handle_new_kudos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    run_owner_id UUID;
BEGIN
    SELECT user_id INTO run_owner_id FROM public.runs WHERE id = NEW.run_id;

    -- Don't notify if user kudos their own run
    IF run_owner_id IS NOT NULL AND run_owner_id != NEW.user_id THEN
        INSERT INTO public.notifications (user_id, actor_id, type, entity_id)
        VALUES (run_owner_id, NEW.user_id, 'kudos', NEW.run_id);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_kudos_created
    AFTER INSERT ON public.kudos
    FOR EACH ROW
    EXECUTE FUNCTION private.handle_new_kudos();

-- ============================================================
-- Notification trigger: new follower
-- ============================================================
CREATE OR REPLACE FUNCTION private.handle_new_follow()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.notifications (user_id, actor_id, type, entity_id)
    VALUES (NEW.following_id, NEW.follower_id, 'new_follower', NEW.follower_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_follow_created
    AFTER INSERT ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION private.handle_new_follow();

-- ============================================================
-- Supabase publication for PowerSync replication
-- Run this AFTER all tables are created.
-- ============================================================
CREATE PUBLICATION powersync FOR TABLE
    public.profiles,
    public.runs,
    public.run_locations,
    public.follows,
    public.kudos,
    public.segments,
    public.segment_efforts,
    public.notifications;

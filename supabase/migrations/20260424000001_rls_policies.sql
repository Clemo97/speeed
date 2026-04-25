-- Migration: 20260424000001_rls_policies.sql
-- Row-Level Security policies for all tables.
-- Follows Supabase security best practices:
--   - Never use raw_user_meta_data in authorization logic
--   - UPDATE policies require a matching SELECT policy (otherwise silent 0-row failures)
--   - SECURITY DEFINER functions kept in a private schema

-- ============================================================
-- profiles
-- ============================================================

-- Own profile is always readable; public profiles readable by all authenticated users
CREATE POLICY "profiles_select"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id OR is_public = TRUE);

-- Only the owner can update their own profile
CREATE POLICY "profiles_update_select"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "profiles_update"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================================
-- runs
-- ============================================================

-- Own runs always readable; other users' runs only if public AND (followed OR public profile)
CREATE POLICY "runs_select"
    ON public.runs FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid()
        OR (
            is_public = TRUE
            AND status = 'completed'
            AND (
                EXISTS (
                    SELECT 1 FROM public.follows
                    WHERE follower_id = auth.uid() AND following_id = runs.user_id
                )
                OR EXISTS (
                    SELECT 1 FROM public.profiles
                    WHERE id = runs.user_id AND is_public = TRUE
                )
            )
        )
    );

CREATE POLICY "runs_insert"
    ON public.runs FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- UPDATE requires a SELECT policy (already defined above)
CREATE POLICY "runs_update"
    ON public.runs FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "runs_delete"
    ON public.runs FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- ============================================================
-- run_locations
-- ============================================================

-- Only the run owner can read or write their own locations
CREATE POLICY "run_locations_select"
    ON public.run_locations FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.runs
            WHERE runs.id = run_locations.run_id AND runs.user_id = auth.uid()
        )
    );

CREATE POLICY "run_locations_insert"
    ON public.run_locations FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.runs
            WHERE runs.id = run_id AND runs.user_id = auth.uid()
        )
    );

CREATE POLICY "run_locations_delete"
    ON public.run_locations FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.runs
            WHERE runs.id = run_id AND runs.user_id = auth.uid()
        )
    );

-- ============================================================
-- follows
-- ============================================================

-- Follows are publicly visible to all authenticated users
CREATE POLICY "follows_select"
    ON public.follows FOR SELECT
    TO authenticated
    USING (TRUE);

-- Only the follower can create a follow
CREATE POLICY "follows_insert"
    ON public.follows FOR INSERT
    TO authenticated
    WITH CHECK (follower_id = auth.uid());

-- Only the follower can delete their own follow
CREATE POLICY "follows_delete"
    ON public.follows FOR DELETE
    TO authenticated
    USING (follower_id = auth.uid());

-- ============================================================
-- kudos
-- ============================================================

-- Kudos on visible runs are readable
CREATE POLICY "kudos_select"
    ON public.kudos FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.runs
            WHERE runs.id = kudos.run_id
              AND (
                runs.user_id = auth.uid()
                OR (runs.is_public = TRUE AND runs.status = 'completed')
              )
        )
    );

CREATE POLICY "kudos_insert"
    ON public.kudos FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "kudos_delete"
    ON public.kudos FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- ============================================================
-- segments
-- ============================================================

-- All public segments are readable
CREATE POLICY "segments_select"
    ON public.segments FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "segments_insert"
    ON public.segments FOR INSERT
    TO authenticated
    WITH CHECK (creator_id = auth.uid());

CREATE POLICY "segments_update"
    ON public.segments FOR UPDATE
    TO authenticated
    USING (creator_id = auth.uid())
    WITH CHECK (creator_id = auth.uid());

CREATE POLICY "segments_delete"
    ON public.segments FOR DELETE
    TO authenticated
    USING (creator_id = auth.uid());

-- ============================================================
-- segment_efforts
-- ============================================================

CREATE POLICY "segment_efforts_select"
    ON public.segment_efforts FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "segment_efforts_insert"
    ON public.segment_efforts FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- ============================================================
-- notifications
-- ============================================================

-- Only the recipient can read their own notifications
CREATE POLICY "notifications_select"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Notifications are created server-side (Edge Functions / triggers) using service_role.
-- No INSERT policy for authenticated users — they cannot create their own notifications.

CREATE POLICY "notifications_update"
    ON public.notifications FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

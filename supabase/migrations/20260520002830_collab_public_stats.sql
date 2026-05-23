-- Public anon-callable stats for the deutschmark.online build-in-public dashboard.
-- Returns one number: 30-day active users. No PII path, no write surface.
-- Pattern verified in Pathos prod 2026-05-19 (get_landing_stats).

CREATE OR REPLACE FUNCTION public.get_collab_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'active_users_30d',
      COALESCE(
        (SELECT COUNT(*)::int
           FROM auth.users
          WHERE last_sign_in_at > NOW() - INTERVAL '30 days'),
        0
      )
  );
$$;

-- CREATE OR REPLACE on an existing function preserves grants, but on a NEW
-- function defaults to GRANT EXECUTE TO PUBLIC. Revoke and re-grant explicitly
-- so the surface is locked even on first deploy and on any future redefinition.
REVOKE EXECUTE ON FUNCTION public.get_collab_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_collab_stats() TO anon;
GRANT EXECUTE ON FUNCTION public.get_collab_stats() TO authenticated;

COMMENT ON FUNCTION public.get_collab_stats() IS
  'Public dashboard stats. active_users_30d sourced from auth.users.last_sign_in_at (last 30 days). Anon-callable on purpose; no per-user data is returned.';

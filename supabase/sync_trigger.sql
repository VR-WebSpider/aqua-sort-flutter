-- 🛡️ WEBSPIDER STUDIOS - CENTRALIZED SYNC TRIGGER
-- Paste this into your Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql/new)

-- 1. Create the function that calls our Edge Function
CREATE OR REPLACE FUNCTION public.sync_profile_to_resend()
RETURNS TRIGGER AS $$
BEGIN
  -- Perform an asynchronous HTTP POST to our Edge Function
  -- We use 'service_role' key so it bypasses RLS and triggers safely
  PERFORM net.http_post(
    url := 'https://zpwwjdiwcucwfuzunique.supabase.co/functions/v1/sync-user-to-resend',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object('record', row_to_json(NEW))
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create the Trigger
-- This fires every time a new row is added to the 'profiles' table
DROP TRIGGER IF EXISTS tr_sync_profile_to_resend ON public.profiles;
CREATE TRIGGER tr_sync_profile_to_resend
AFTER INSERT ON public.profiles
FOR EACH ROW EXECUTE PROCEDURE public.sync_profile_to_resend();

-- 3. Ensure 'pg_net' extension is enabled (required for net.http_post)
CREATE EXTENSION IF NOT EXISTS pg_net;

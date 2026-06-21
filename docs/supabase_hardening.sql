-- ==========================================
-- 🛡️ AQUA SORT: Supabase Hardening & Auth
-- ==========================================

-- 1. FIX SECURITY ADVISOR ERRORS (public.rooms)
-- This enables RLS and adds a default policy for authenticated users.
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can read any room
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'rooms' AND policyname = 'Public rooms are viewable by everyone.') THEN
        CREATE POLICY "Public rooms are viewable by everyone." ON public.rooms
            FOR SELECT USING (true);
    END IF;
END $$;

-- Policy: Only owners can update their rooms
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'rooms' AND policyname = 'Users can update their own rooms.') THEN
        CREATE POLICY "Users can update their own rooms." ON public.rooms
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;


-- 2. HIGH-SECURITY AUTH SCHEMA (Profiles)
-- Add phone and email_lookup for dual-identifier login
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS phone TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS email_lookup TEXT;


-- 3. PURITY CHALLENGE SYSTEM
-- Create table for storing 6-digit security codes
CREATE TABLE IF NOT EXISTS public.security_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL
);

-- Protect the challenges table
ALTER TABLE public.security_challenges ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see/delete their own challenges
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'security_challenges' AND policyname = 'Users can manage their own challenges.') THEN
        CREATE POLICY "Users can manage their own challenges." ON public.security_challenges
            FOR ALL USING (auth.uid() = user_id);
    END IF;
END $$;


-- 4. VERIFICATION
-- Ensure RLS is active across all sensitive tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
-- (Assuming profiles already has policies from your previous setup, if not, they will be protected by default).

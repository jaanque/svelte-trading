-- Fix foreign key on posts table to point to profiles instead of auth.users
-- This allows PostgREST to expand the user relation directly using user:profiles!user_id

-- 1. Drop the existing foreign key constraint if it exists
-- We assume the constraint name is 'posts_user_id_fkey' which is standard
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_user_id_fkey;

-- 2. Add the foreign key constraint referencing public.profiles
ALTER TABLE public.posts
    ADD CONSTRAINT posts_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(id)
    ON DELETE CASCADE;

-- 3. Ensure profiles are publicly viewable (just in case)
-- (Assuming profiles table has RLS enabled)
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING ( true );

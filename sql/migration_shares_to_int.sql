-- Migration script to convert shares columns to bigint
-- This script handles casting existing numeric data to bigint (rounding/truncating)

-- 1. Profiles Table
-- Alter columns to bigint. We use floor() to be safe, or direct cast if we trust data is clean.
-- Since we are enforcing integers now, truncation is expected.

ALTER TABLE public.profiles
ALTER COLUMN shares TYPE bigint USING floor(shares)::bigint,
ALTER COLUMN available_shares TYPE bigint USING floor(available_shares)::bigint;

-- 2. Investments Table
ALTER TABLE public.investments
ALTER COLUMN amount_shares TYPE bigint USING floor(amount_shares)::bigint;

-- 3. Re-create functions to ensure they use new types (already done in updated definition files, but good to have)
-- (The updated definition files sql/investments.sql and sql/sell_shares.sql should be run to apply function updates)

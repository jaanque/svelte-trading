-- Force migration of all relevant columns to BIGINT to prevent integer overflow
-- This fixes "integer out of range" errors when token or share counts exceed 2.1 billion

BEGIN;

-- 1. Profiles Table
ALTER TABLE public.profiles
ALTER COLUMN tokens TYPE bigint USING floor(tokens)::bigint,
ALTER COLUMN price TYPE bigint USING floor(price)::bigint,
ALTER COLUMN shares TYPE bigint USING floor(shares)::bigint,
ALTER COLUMN available_shares TYPE bigint USING floor(available_shares)::bigint;

-- 2. Investments Table
ALTER TABLE public.investments
ALTER COLUMN amount_tokens TYPE bigint USING floor(amount_tokens)::bigint,
ALTER COLUMN amount_shares TYPE bigint USING floor(amount_shares)::bigint;

COMMIT;

-- Migration script to convert tokens and price to bigint
-- This script truncates existing decimals.

-- 1. Profiles Table
ALTER TABLE public.profiles
ALTER COLUMN tokens TYPE bigint USING floor(tokens)::bigint,
ALTER COLUMN price TYPE bigint USING floor(price)::bigint;

-- 2. Investments Table
ALTER TABLE public.investments
ALTER COLUMN amount_tokens TYPE bigint USING floor(amount_tokens)::bigint;

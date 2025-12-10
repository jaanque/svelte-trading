-- Migration script to ensure price_history uses bigint
-- This aligns with the global shift to integer-only logic

ALTER TABLE public.price_history
ALTER COLUMN price TYPE bigint USING floor(price)::bigint;

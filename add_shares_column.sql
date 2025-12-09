-- Add shares column to profiles table with default 1 million
alter table public.profiles
add column shares bigint default 1000000;

-- Fix price columns to be numeric to support decimal increments
-- This is critical for the 0.5% price sensitivity feature.

-- 1. Alter profiles table
alter table public.profiles
alter column price type numeric;

-- 2. Alter price_history table
alter table public.price_history
alter column price type numeric;

-- 3. Update the trigger function to ensure it handles numeric correctly (PLPGSQL is dynamic but good to be safe)
create or replace function public.record_price_change()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Ensure comparison works for numeric
  if (TG_OP = 'INSERT') or (old.price is distinct from new.price) then
    insert into public.price_history (user_id, price)
    values (new.id, new.price);
  end if;
  return new;
end;
$$;

-- Function to get the latest price for a list of users before a specific time
-- Used for reconstructing portfolio value history

create or replace function public.get_snapshot_prices(
  p_user_ids uuid[],
  p_time timestamp with time zone
)
returns table (
  user_id uuid,
  price numeric
)
language plpgsql
security definer
as $$
begin
  return query
  select distinct on (ph.user_id)
    ph.user_id,
    ph.price::numeric
  from public.price_history ph
  where ph.user_id = any(p_user_ids)
    and ph.created_at < p_time
  order by ph.user_id, ph.created_at desc;
end;
$$;

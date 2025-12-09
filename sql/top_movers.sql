-- Function to get top movers (gainers and losers) based on 24h price change
-- Returns a list of profiles with their current price and percentage change
create or replace function public.get_top_movers(
  limit_count int default 5
)
returns table (
  id uuid,
  username text,
  full_name text,
  avatar_url text,
  current_price numeric,
  change_pct numeric
)
language plpgsql
security definer
as $$
begin
  return query
  with price_24h_ago as (
    -- Get the price closest to 24h ago for each user
    -- We use distinct on (user_id) to get the single closest record
    select distinct on (user_id)
      user_id,
      price as old_price
    from public.price_history
    where created_at >= now() - interval '24 hours'
    order by user_id, created_at asc
  ),
  current_prices as (
    select
      p.id,
      p.username,
      p.full_name,
      p.avatar_url,
      p.price
    from public.profiles p
  )
  select
    cp.id,
    cp.username,
    cp.full_name,
    cp.avatar_url,
    cp.price as current_price,
    case
      when ph.old_price is null or ph.old_price = 0 then 0
      else ((cp.price - ph.old_price) / ph.old_price) * 100
    end as change_pct
  from current_prices cp
  left join price_24h_ago ph on cp.id = ph.user_id
  -- Filter out users with 0 change if desired, or keep them.
  -- For movers, we usually want non-zero change, but if new users have 0 change they just won't be top/bottom
  where cp.price is not null
  order by change_pct desc;
end;
$$;

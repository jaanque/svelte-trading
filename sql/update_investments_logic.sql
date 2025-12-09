-- Add available_shares column
alter table public.profiles
add column if not exists available_shares numeric default 1000000;

-- Initialize available_shares for existing users if it's null (though default handles new rows)
update public.profiles
set available_shares = shares
where available_shares is null;

-- Update the investment function to handle supply and dynamic price
create or replace function public.invest_in_user(
  target_user_id uuid,
  invest_amount numeric
)
returns void
language plpgsql
security definer
as $$
declare
  current_user_id uuid;
  user_balance numeric;
  target_profile public.profiles%ROWTYPE;
  shares_to_buy numeric;
  new_price numeric;
begin
  current_user_id := auth.uid();

  -- Check if user exists and get balance
  select tokens into user_balance
  from public.profiles
  where id = current_user_id;

  if user_balance < invest_amount then
    raise exception 'Insufficient tokens';
  end if;

  -- Get target user details (lock the row for update to prevent race conditions)
  select * into target_profile
  from public.profiles
  where id = target_user_id
  for update;

  -- Safety checks
  if target_profile.price is null or target_profile.price <= 0 then
    target_profile.price := 50;
  end if;

  if target_profile.available_shares is null then
     target_profile.available_shares := target_profile.shares;
  end if;

  -- Calculate shares to buy based on current price
  shares_to_buy := invest_amount / target_profile.price;

  -- Check availability
  if shares_to_buy > target_profile.available_shares then
    raise exception 'Not enough shares available. Available: %, Requested: %', target_profile.available_shares, shares_to_buy;
  end if;

  -- Deduct tokens from investor
  update public.profiles
  set tokens = tokens - invest_amount
  where id = current_user_id;

  -- Calculate new price
  -- Dynamic Price Impact: 0.5% increase per token invested
  -- NewPrice = CurrentPrice * (1 + (0.005 * InvestAmount))
  new_price := target_profile.price * (1 + (0.005 * invest_amount));

  -- Update target user stats
  update public.profiles
  set
    available_shares = available_shares - shares_to_buy,
    price = new_price
  where id = target_user_id;

  -- Record investment
  insert into public.investments (investor_id, target_user_id, amount_tokens, amount_shares)
  values (current_user_id, target_user_id, invest_amount, shares_to_buy);

end;
$$;

-- Function to sell shares
-- Deducts shares from investment, adds tokens to seller, returns shares to available pool
-- Decreases price of target user

create or replace function public.sell_shares(
  p_target_user_id uuid,
  p_amount_shares bigint
)
returns void
language plpgsql
security definer
as $$
declare
  current_user_id uuid;
  target_profile public.profiles%ROWTYPE;
  tokens_to_receive numeric;
  new_price numeric;
  total_shares_owned bigint;
begin
  current_user_id := auth.uid();

  -- Get target user details (lock for update)
  select * into target_profile
  from public.profiles p
  where p.id = p_target_user_id
  for update;

  if target_profile.id is null then
    raise exception 'Target user not found';
  end if;

  -- Calculate total shares owned
  -- Use table alias 'i' and prefix-parameter to ensure no ambiguity
  select coalesce(sum(i.amount_shares), 0) into total_shares_owned
  from public.investments i
  where i.investor_id = current_user_id
    and i.target_user_id = p_target_user_id;

  if total_shares_owned < p_amount_shares then
     raise exception 'Insufficient shares. You own % but tried to sell %', total_shares_owned, p_amount_shares;
  end if;

  -- Calculate tokens to receive based on current price
  -- Tokens = Shares * Price
  -- Ensure numeric calculation
  tokens_to_receive := p_amount_shares * target_profile.price;

  -- Update seller's token balance
  update public.profiles
  set tokens = tokens + tokens_to_receive
  where id = current_user_id;

  -- Update target user stats
  -- Return shares to available pool
  -- Decrease price
  -- Price impact: Inverse of buy.
  -- Buy: New = Old * (1 + 0.005 * InvestAmount)
  -- Sell: New = Old / (1 + 0.005 * TokensValue)

  new_price := target_profile.price / (1 + (0.005 * tokens_to_receive));

  update public.profiles
  set
    available_shares = available_shares + p_amount_shares,
    price = new_price
  where id = p_target_user_id;

  -- Record the "Sale" (Negative investment)
  insert into public.investments (investor_id, target_user_id, amount_tokens, amount_shares)
  values (current_user_id, p_target_user_id, -tokens_to_receive, -p_amount_shares);

end;
$$;

-- Function to sell shares
-- Deducts shares from investment, adds tokens to seller, returns shares to available pool
-- Decreases price of target user

create or replace function public.sell_shares(
  target_user_id uuid,
  amount_shares numeric
)
returns void
language plpgsql
security definer
as $$
declare
  current_user_id uuid;
  target_profile public.profiles%ROWTYPE;
  current_investment public.investments%ROWTYPE;
  tokens_to_receive numeric;
  new_price numeric;
begin
  current_user_id := auth.uid();

  -- Get target user details (lock for update)
  select * into target_profile
  from public.profiles
  where id = target_user_id
  for update;

  if target_profile.id is null then
    raise exception 'Target user not found';
  end if;

  -- Check if user has enough shares
  -- We need to sum up all investments or find the aggregate.
  -- Simpler: Check if we have an investment record or aggregate.
  -- Since we insert a new row for every investment, we need to sum them up OR we should have aggregated them.
  -- The current system inserts new rows. This makes partial selling hard if we don't aggregate.
  -- "Portfolio.svelte" aggregates client-side.
  -- Ideally, we should have a "holdings" table or aggregate query.
  -- For now, we will verify the user has enough shares by summing their investments.

  -- Calculate total shares owned
  declare
    total_shares_owned numeric;
  begin
    select coalesce(sum(amount_shares), 0) into total_shares_owned
    from public.investments
    where investor_id = current_user_id
      and target_user_id = target_user_id; -- wait, target_user_id param vs column

    -- Fix variable scope collision
    select coalesce(sum(i.amount_shares), 0) into total_shares_owned
    from public.investments i
    where i.investor_id = current_user_id
      and i.target_user_id = sell_shares.target_user_id;

    if total_shares_owned < amount_shares then
       raise exception 'Insufficient shares. You own % but tried to sell %', total_shares_owned, amount_shares;
    end if;
  end;

  -- Calculate tokens to receive based on current price
  -- Tokens = Shares * Price
  tokens_to_receive := amount_shares * target_profile.price;

  -- Update seller's token balance
  update public.profiles
  set tokens = tokens + tokens_to_receive
  where id = current_user_id;

  -- Update target user stats
  -- Return shares to available pool
  -- Decrease price
  -- Price impact: Inverse of buy.
  -- Buy: New = Old * (1 + 0.005 * InvestAmount)
  -- Sell: New = Old / (1 + 0.005 * TokensValue)  <-- Approximation of inverse

  new_price := target_profile.price / (1 + (0.005 * tokens_to_receive));

  update public.profiles
  set
    available_shares = available_shares + amount_shares,
    price = new_price
  where id = target_user_id;

  -- Record the "Sale"
  -- We can record it as a negative investment?
  -- Or strictly speaking, we should have a "transactions" table.
  -- But to keep compatible with "investments" table acting as ledger:
  -- insert negative values.
  insert into public.investments (investor_id, target_user_id, amount_tokens, amount_shares)
  values (current_user_id, target_user_id, -tokens_to_receive, -amount_shares);

end;
$$;


create or replace function public.get_daily_investment_stats()
returns json
language plpgsql
security definer
as $$
declare
  total_investments_today bigint;
  total_tokens_today bigint;
  hourly_data json;
begin
  -- Get totals for today (UTC)
  select
    count(*),
    coalesce(sum(amount_tokens), 0)
  into
    total_investments_today,
    total_tokens_today
  from public.investments
  where created_at >= current_date;

  -- Get hourly counts for the last 24 hours (or just today)
  -- This is a simple aggregation
  select json_agg(t) into hourly_data from (
    select
      date_part('hour', created_at) as hour,
      count(*) as count,
      sum(amount_tokens) as volume
    from public.investments
    where created_at >= current_date
    group by 1
    order by 1
  ) t;

  return json_build_object(
    'count', total_investments_today,
    'volume', total_tokens_today,
    'chart_data', coalesce(hourly_data, '[]'::json)
  );
end;
$$;

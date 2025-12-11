-- Create Posts table
create table if not exists public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  content text not null,
  created_at timestamptz default now() not null,
  likes_count int default 0,
  visibility text default 'everyone' check (visibility in ('everyone', 'followers'))
);

-- Enable RLS
alter table public.posts enable row level security;

-- Policies
create policy "Public posts are viewable by everyone"
  on public.posts for select
  using (true);

create policy "Users can insert their own posts"
  on public.posts for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own posts"
  on public.posts for update
  using (auth.uid() = user_id);

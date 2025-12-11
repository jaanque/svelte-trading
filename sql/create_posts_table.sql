-- Create posts table if it doesn't exist
create table if not exists public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  likes_count integer default 0,
  visibility text default 'everyone' -- 'everyone' or 'followers'
);

-- Enable RLS
alter table public.posts enable row level security;

-- Policies
create policy "Public posts are viewable by everyone"
  on public.posts for select
  using ( true );

create policy "Users can insert their own posts"
  on public.posts for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own posts"
  on public.posts for update
  using ( auth.uid() = user_id );

-- Optional: Add real-time if needed (Supabase usually handles this via UI, but we can't do it via SQL easily for publication)

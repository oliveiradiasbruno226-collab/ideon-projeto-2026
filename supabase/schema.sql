-- IDEON database foundation for Supabase (PostgreSQL)
-- Run this file in Supabase SQL Editor. Safe to run once on a new project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text not null default 'Novo membro',
  bio text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_format check (username is null or username ~ '^[a-zA-Z0-9_.]{3,30}$')
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 140),
  body text not null default '' check (char_length(body) <= 30000),
  category text not null default 'Ideias' check (char_length(category) <= 40),
  cover_url text,
  visibility text not null default 'public' check (visibility in ('public','followers','private')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint no_self_follow check (follower_id <> following_id)
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 3000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 140),
  description text not null default '',
  status text not null default 'active' check (status in ('active','paused','completed','archived')),
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  completed boolean not null default false,
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  kind text not null check (kind in ('follow','like','comment')),
  post_id uuid references public.posts(id) on delete cascade,
  comment_id uuid references public.comments(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists posts_feed_idx on public.posts (visibility, created_at desc);
create index if not exists posts_author_idx on public.posts (author_id, created_at desc);
create index if not exists follows_following_idx on public.follows (following_id);
create index if not exists comments_post_idx on public.comments (post_id, created_at);
create index if not exists notifications_recipient_idx on public.notifications (recipient_id, created_at desc);
create index if not exists tasks_owner_idx on public.tasks (owner_id, completed, due_at);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists posts_updated_at on public.posts;
create trigger posts_updated_at before update on public.posts for each row execute function public.set_updated_at();
drop trigger if exists comments_updated_at on public.comments;
create trigger comments_updated_at before update on public.comments for each row execute function public.set_updated_at();
drop trigger if exists projects_updated_at on public.projects;
create trigger projects_updated_at before update on public.projects for each row execute function public.set_updated_at();
drop trigger if exists tasks_updated_at on public.tasks;
create trigger tasks_updated_at before update on public.tasks for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', 'Novo membro'),
    nullif(new.raw_user_meta_data->>'username', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.follows enable row level security;
alter table public.post_likes enable row level security;
alter table public.comments enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.notifications enable row level security;

-- Profiles: visible to signed-in users; each member edits only their own.
drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated" on public.profiles for select to authenticated using (true);
drop policy if exists "profile owner inserts" on public.profiles;
create policy "profile owner inserts" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "profile owner updates" on public.profiles;
create policy "profile owner updates" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Posts: public posts are readable by signed-in members; follower/private content is restricted.
drop policy if exists "read visible posts" on public.posts;
create policy "read visible posts" on public.posts for select to authenticated using (
  visibility = 'public'
  or author_id = auth.uid()
  or (visibility = 'followers' and exists (
    select 1 from public.follows f where f.follower_id = auth.uid() and f.following_id = author_id
  ))
);
drop policy if exists "authors create posts" on public.posts;
create policy "authors create posts" on public.posts for insert to authenticated with check (author_id = auth.uid());
drop policy if exists "authors update posts" on public.posts;
create policy "authors update posts" on public.posts for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());
drop policy if exists "authors delete posts" on public.posts;
create policy "authors delete posts" on public.posts for delete to authenticated using (author_id = auth.uid());

-- Follow graph.
drop policy if exists "members read follows" on public.follows;
create policy "members read follows" on public.follows for select to authenticated using (true);
drop policy if exists "members follow as themselves" on public.follows;
create policy "members follow as themselves" on public.follows for insert to authenticated with check (follower_id = auth.uid());
drop policy if exists "members unfollow themselves" on public.follows;
create policy "members unfollow themselves" on public.follows for delete to authenticated using (follower_id = auth.uid());

-- Likes.
drop policy if exists "members read likes" on public.post_likes;
create policy "members read likes" on public.post_likes for select to authenticated using (true);
drop policy if exists "members like as themselves" on public.post_likes;
create policy "members like as themselves" on public.post_likes for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "members remove own likes" on public.post_likes;
create policy "members remove own likes" on public.post_likes for delete to authenticated using (user_id = auth.uid());

-- Comments are readable only when their post is readable; author controls edits/deletion.
drop policy if exists "read comments on visible posts" on public.comments;
create policy "read comments on visible posts" on public.comments for select to authenticated using (
  exists (select 1 from public.posts p where p.id = post_id)
);
drop policy if exists "members comment as themselves" on public.comments;
create policy "members comment as themselves" on public.comments for insert to authenticated with check (
  author_id = auth.uid() and exists (select 1 from public.posts p where p.id = post_id)
);
drop policy if exists "authors update own comments" on public.comments;
create policy "authors update own comments" on public.comments for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());
drop policy if exists "authors delete own comments" on public.comments;
create policy "authors delete own comments" on public.comments for delete to authenticated using (author_id = auth.uid());

-- Private workspace: only the owner can access projects and tasks.
drop policy if exists "owners manage projects" on public.projects;
create policy "owners manage projects" on public.projects for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "owners manage tasks" on public.tasks;
create policy "owners manage tasks" on public.tasks for all to authenticated using (
  owner_id = auth.uid() and exists (select 1 from public.projects p where p.id = project_id and p.owner_id = auth.uid())
) with check (
  owner_id = auth.uid() and exists (select 1 from public.projects p where p.id = project_id and p.owner_id = auth.uid())
);

drop policy if exists "recipients read notifications" on public.notifications;
create policy "recipients read notifications" on public.notifications for select to authenticated using (recipient_id = auth.uid());
drop policy if exists "recipients update notifications" on public.notifications;
create policy "recipients update notifications" on public.notifications for update to authenticated using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

-- Storage bucket for post media. Upload policies restrict files to a user-owned folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ideon-media', 'ideon-media', true, 10485760, array['image/jpeg','image/png','image/webp','video/mp4'])
on conflict (id) do nothing;

drop policy if exists "public read IDEON media" on storage.objects;
create policy "public read IDEON media" on storage.objects for select using (bucket_id = 'ideon-media');
drop policy if exists "members upload own IDEON media" on storage.objects;
create policy "members upload own IDEON media" on storage.objects for insert to authenticated with check (
  bucket_id = 'ideon-media' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "members update own IDEON media" on storage.objects;
create policy "members update own IDEON media" on storage.objects for update to authenticated using (
  bucket_id = 'ideon-media' and (storage.foldername(name))[1] = auth.uid()::text
) with check (bucket_id = 'ideon-media' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "members delete own IDEON media" on storage.objects;
create policy "members delete own IDEON media" on storage.objects for delete to authenticated using (
  bucket_id = 'ideon-media' and (storage.foldername(name))[1] = auth.uid()::text
);

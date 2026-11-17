-- IDEON social network expansion
-- Apply AFTER ../schema.sql in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  is_private boolean not null default false,
  allow_messages text not null default 'followers' check (allow_messages in ('everyone','followers','nobody')),
  show_activity boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  media_url text not null,
  media_type text not null check (media_type in ('image','video')),
  caption text not null default '' check (char_length(caption) <= 500),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours')
);
create index if not exists stories_active_idx on public.stories (expires_at desc, created_at desc);

create table if not exists public.story_views (
  story_id uuid not null references public.stories(id) on delete cascade,
  viewer_id uuid not null references public.profiles(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (story_id, viewer_id)
);

create table if not exists public.saved_posts (
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);
create index if not exists saved_posts_user_idx on public.saved_posts (user_id, created_at desc);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  is_group boolean not null default false,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null default '' check (char_length(body) <= 5000),
  media_url text,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  constraint message_has_content check (char_length(trim(body)) > 0 or media_url is not null)
);
create index if not exists messages_conversation_idx on public.messages (conversation_id, created_at desc);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint no_block_self check (blocker_id <> blocked_id)
);

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  comment_id uuid references public.comments(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete cascade,
  reason text not null check (reason in ('spam','harassment','hate','nudity','violence','misinformation','other')),
  details text not null default '' check (char_length(details) <= 2000),
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  constraint report_has_target check (post_id is not null or comment_id is not null or reported_user_id is not null)
);

create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = p_conversation_id and cm.user_id = auth.uid()
  );
$$;
revoke all on function public.is_conversation_member(uuid) from public;
grant execute on function public.is_conversation_member(uuid) to authenticated;

create or replace function public.is_conversation_creator(p_conversation_id uuid)
returns boolean language sql stable security definer set search_path = public as $
  select exists (
    select 1 from public.conversations c
    where c.id = p_conversation_id and c.created_by = auth.uid()
  );
$;
revoke all on function public.is_conversation_creator(uuid) from public;
grant execute on function public.is_conversation_creator(uuid) to authenticated;

create or replace function public.is_blocked_between(user_a uuid, user_b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = user_a and b.blocked_id = user_b)
       or (b.blocker_id = user_b and b.blocked_id = user_a)
  );
$$;
revoke all on function public.is_blocked_between(uuid,uuid) from public;
grant execute on function public.is_blocked_between(uuid,uuid) to authenticated;

alter table public.user_settings enable row level security;
alter table public.stories enable row level security;
alter table public.story_views enable row level security;
alter table public.saved_posts enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.user_blocks enable row level security;
alter table public.content_reports enable row level security;

drop policy if exists "users manage own settings" on public.user_settings;
create policy "users manage own settings" on public.user_settings for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "read active stories" on public.stories;
create policy "read active stories" on public.stories for select to authenticated
using (
  expires_at > now()
  and not public.is_blocked_between(auth.uid(), author_id)
  and (
    author_id = auth.uid()
    or not coalesce((select s.is_private from public.user_settings s where s.user_id = author_id), false)
    or exists (select 1 from public.follows f where f.follower_id = auth.uid() and f.following_id = author_id)
  )
);
drop policy if exists "authors create stories" on public.stories;
create policy "authors create stories" on public.stories for insert to authenticated
with check (author_id = auth.uid());
drop policy if exists "authors delete stories" on public.stories;
create policy "authors delete stories" on public.stories for delete to authenticated
using (author_id = auth.uid());

drop policy if exists "story viewers insert own view" on public.story_views;
create policy "story viewers insert own view" on public.story_views for insert to authenticated
with check (viewer_id = auth.uid() and exists (select 1 from public.stories s where s.id = story_id));
drop policy if exists "story owner or viewer read views" on public.story_views;
create policy "story owner or viewer read views" on public.story_views for select to authenticated
using (viewer_id = auth.uid() or exists (select 1 from public.stories s where s.id = story_id and s.author_id = auth.uid()));

drop policy if exists "users manage own saved posts" on public.saved_posts;
create policy "users manage own saved posts" on public.saved_posts for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "conversation members read conversations" on public.conversations;
create policy "conversation members read conversations" on public.conversations for select to authenticated
using (public.is_conversation_member(id));
drop policy if exists "signed-in users create conversations" on public.conversations;
create policy "signed-in users create conversations" on public.conversations for insert to authenticated
with check (created_by = auth.uid());
drop policy if exists "conversation members update conversations" on public.conversations;
create policy "conversation members update conversations" on public.conversations for update to authenticated
using (public.is_conversation_member(id)) with check (public.is_conversation_member(id));

drop policy if exists "members read conversation membership" on public.conversation_members;
create policy "members read conversation membership" on public.conversation_members for select to authenticated
using (public.is_conversation_member(conversation_id) or user_id = auth.uid());
drop policy if exists "conversation creator adds members" on public.conversation_members;
create policy "conversation creator adds members" on public.conversation_members for insert to authenticated
with check (
  user_id = auth.uid()
  or public.is_conversation_creator(conversation_id)
);
drop policy if exists "members update own membership" on public.conversation_members;
create policy "members update own membership" on public.conversation_members for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "members leave conversations" on public.conversation_members;
create policy "members leave conversations" on public.conversation_members for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "members read messages" on public.messages;
create policy "members read messages" on public.messages for select to authenticated
using (public.is_conversation_member(conversation_id));
drop policy if exists "members send messages" on public.messages;
create policy "members send messages" on public.messages for insert to authenticated
with check (sender_id = auth.uid() and public.is_conversation_member(conversation_id));
drop policy if exists "senders edit own messages" on public.messages;
create policy "senders edit own messages" on public.messages for update to authenticated
using (sender_id = auth.uid() and public.is_conversation_member(conversation_id))
with check (sender_id = auth.uid() and public.is_conversation_member(conversation_id));
drop policy if exists "senders delete own messages" on public.messages;
create policy "senders delete own messages" on public.messages for delete to authenticated
using (sender_id = auth.uid() and public.is_conversation_member(conversation_id));

drop policy if exists "users read own blocks" on public.user_blocks;
create policy "users read own blocks" on public.user_blocks for select to authenticated
using (blocker_id = auth.uid());
drop policy if exists "users create own blocks" on public.user_blocks;
create policy "users create own blocks" on public.user_blocks for insert to authenticated
with check (blocker_id = auth.uid());
drop policy if exists "users remove own blocks" on public.user_blocks;
create policy "users remove own blocks" on public.user_blocks for delete to authenticated
using (blocker_id = auth.uid());

drop policy if exists "users submit reports" on public.content_reports;
create policy "users submit reports" on public.content_reports for insert to authenticated
with check (reporter_id = auth.uid());
drop policy if exists "users read own reports" on public.content_reports;
create policy "users read own reports" on public.content_reports for select to authenticated
using (reporter_id = auth.uid());

-- Enforce account privacy on public post reads as well as block relationships.
drop policy if exists "read visible posts" on public.posts;
create policy "read visible posts" on public.posts for select to authenticated using (
  not public.is_blocked_between(auth.uid(), author_id)
  and (
    author_id = auth.uid()
    or (
      visibility = 'public'
      and not coalesce((select s.is_private from public.user_settings s where s.user_id = author_id), false)
    )
    or (visibility = 'followers' and exists (
      select 1 from public.follows f where f.follower_id = auth.uid() and f.following_id = author_id
    ))
    or visibility = 'private' and author_id = auth.uid()
  )
);

-- Notify recipients about social interactions. Triggers run with definer rights.
create or replace function public.notify_social_event()
returns trigger language plpgsql security definer set search_path = public as $$
declare recipient uuid;
declare actor uuid;
declare target_post uuid;
declare event_kind text;
begin
  if tg_table_name = 'follows' then
    actor := new.follower_id;
    recipient := new.following_id;
    event_kind := 'follow';
    target_post := null;
  elsif tg_table_name = 'post_likes' then
    actor := new.user_id;
    target_post := new.post_id;
    select author_id into recipient from public.posts where id = new.post_id;
    event_kind := 'like';
  elsif tg_table_name = 'comments' then
    actor := new.author_id;
    target_post := new.post_id;
    select author_id into recipient from public.posts where id = new.post_id;
    event_kind := 'comment';
  end if;
  if recipient is not null and recipient <> actor then
    insert into public.notifications(recipient_id, actor_id, kind, post_id)
    values(recipient, actor, event_kind, target_post);
  end if;
  return new;
end;
$$;

drop trigger if exists notify_new_follow on public.follows;
create trigger notify_new_follow after insert on public.follows
for each row execute function public.notify_social_event();
drop trigger if exists notify_new_like on public.post_likes;
create trigger notify_new_like after insert on public.post_likes
for each row execute function public.notify_social_event();
drop trigger if exists notify_new_comment on public.comments;
create trigger notify_new_comment after insert on public.comments
for each row execute function public.notify_social_event();

-- Add high-value tables to Supabase Realtime where available.
do $$
begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null;
when undefined_object then raise notice 'Create supabase_realtime publication before enabling live updates.';
end $$;
do $$
begin
  alter publication supabase_realtime add table public.comments;
exception when duplicate_object then null;
when undefined_object then raise notice 'Realtime publication not available.';
end $$;
do $$
begin
  alter publication supabase_realtime add table public.post_likes;
exception when duplicate_object then null;
when undefined_object then raise notice 'Realtime publication not available.';
end $$;
do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
when undefined_object then raise notice 'Realtime publication not available.';
end $$;
do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null;
when undefined_object then raise notice 'Realtime publication not available.';
end $$;

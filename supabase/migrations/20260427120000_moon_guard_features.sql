-- Moon Guard — child profiles, location, chat, safety, routines (Supabase; mirrors SRS / Firebase use cases)
-- Run in Dashboard → SQL. Requires prior migration: 20260427000000_moon_guard_profiles.sql

-- ——— Child profiles (max 5 enforced in app) ———
create table if not exists public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  age int,
  device_label text,
  avatar_url text,
  child_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists child_profiles_parent_idx on public.child_profiles (parent_id);

-- ——— Live / history location (7-day cleanup: run periodically or use pg_cron) ———
create table if not exists public.location_points (
  id bigserial primary key,
  child_profile_id uuid not null references public.child_profiles (id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  accuracy_m double precision,
  recorded_at timestamptz not null default now()
);

create index if not exists location_points_child_time_idx
  on public.location_points (child_profile_id, recorded_at desc);

-- ——— Chat (30-day cleanup optional) ———
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  parent_user_id uuid not null references auth.users (id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles (id) on delete cascade,
  sender_user_id uuid not null,
  message_type text not null default 'text'
    check (message_type in ('text', 'image', 'video', 'emoji')),
  body text,
  storage_path text,
  created_at timestamptz not null default now()
);

create index if not exists chat_messages_thread_idx
  on public.chat_messages (child_profile_id, created_at desc);

-- ——— Parent-managed keyword & app rules (OS-wide filter needs native Android) ———
create table if not exists public.blocked_keywords (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id) on delete cascade,
  child_profile_id uuid references public.child_profiles (id) on delete cascade,
  keyword text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists blocked_keywords_parent_idx on public.blocked_keywords (parent_id);

create table if not exists public.filter_block_logs (
  id bigserial primary key,
  parent_id uuid not null references auth.users (id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles (id) on delete cascade,
  keyword text,
  app_context text,
  created_at timestamptz not null default now()
);

create table if not exists public.blocked_apps (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles (id) on delete cascade,
  package_name text not null,
  app_label text,
  manual_block boolean not null default true,
  blur_screen boolean not null default true,
  created_at timestamptz not null default now(),
  unique (child_profile_id, package_name)
);

-- ——— Routines (prayer, sleep, reminders — FCM can be added later) ———
create table if not exists public.routines (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles (id) on delete cascade,
  kind text not null check (kind in ('prayer', 'sleep', 'reminder', 'custom')),
  title text not null,
  time_of_day time,
  days_mask int not null default 127,
  is_enabled boolean not null default true,
  notes text,
  created_at timestamptz not null default now()
);

-- ——— RLS ———
alter table public.child_profiles enable row level security;
alter table public.location_points enable row level security;
alter table public.chat_messages enable row level security;
alter table public.blocked_keywords enable row level security;
alter table public.filter_block_logs enable row level security;
alter table public.blocked_apps enable row level security;
alter table public.routines enable row level security;

-- child_profiles: parent or linked child
drop policy if exists "child_select" on public.child_profiles;
create policy "child_select" on public.child_profiles for select to authenticated
  using (parent_id = auth.uid() or child_user_id = auth.uid());
drop policy if exists "child_insert" on public.child_profiles;
create policy "child_insert" on public.child_profiles for insert to authenticated
  with check (parent_id = auth.uid());
drop policy if exists "child_update" on public.child_profiles;
create policy "child_update" on public.child_profiles for update to authenticated
  using (parent_id = auth.uid());
drop policy if exists "child_delete" on public.child_profiles;
create policy "child_delete" on public.child_profiles for delete to authenticated
  using (parent_id = auth.uid());

-- location: parent of child, or child linked user inserts own device
create or replace function public.owns_child_profile(p_child uuid, p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select exists (
    select 1 from public.child_profiles c
    where c.id = p_child
      and (c.parent_id = p_user or c.child_user_id = p_user)
  );
$fn$;

drop policy if exists "loc_select" on public.location_points;
create policy "loc_select" on public.location_points for select to authenticated
  using (public.owns_child_profile(child_profile_id, auth.uid()));
drop policy if exists "loc_insert" on public.location_points;
create policy "loc_insert" on public.location_points for insert to authenticated
  with check (public.owns_child_profile(child_profile_id, auth.uid()));
drop policy if exists "loc_delete" on public.location_points;
create policy "loc_delete" on public.location_points for delete to authenticated
  using (public.owns_child_profile(child_profile_id, auth.uid()));

-- chat: parent (owner) or linked child
drop policy if exists "chat_select" on public.chat_messages;
create policy "chat_select" on public.chat_messages for select to authenticated
  using (parent_user_id = auth.uid() or public.owns_child_profile(child_profile_id, auth.uid()));
drop policy if exists "chat_insert" on public.chat_messages;
create policy "chat_insert" on public.chat_messages for insert to authenticated
  with check (
    exists (
      select 1 from public.child_profiles c
      where c.id = child_profile_id
        and parent_user_id = c.parent_id
        and (
          (c.parent_id = auth.uid() and sender_user_id = auth.uid())
          or
          (c.child_user_id is not null and c.child_user_id = auth.uid() and sender_user_id = auth.uid())
        )
    )
  );
drop policy if exists "chat_delete" on public.chat_messages;
create policy "chat_delete" on public.chat_messages for delete to authenticated
  using (parent_user_id = auth.uid());

-- keywords / logs / apps / routines: parent only (child reads blocked rules via app if needed)
drop policy if exists "bk_all" on public.blocked_keywords;
create policy "bk_all" on public.blocked_keywords for all to authenticated
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid());
drop policy if exists "fbl_select" on public.filter_block_logs;
drop policy if exists "fbl_insert" on public.filter_block_logs;
drop policy if exists "fbl_all" on public.filter_block_logs;
create policy "fbl_select" on public.filter_block_logs for select to authenticated
  using (parent_id = auth.uid());
create policy "fbl_insert" on public.filter_block_logs for insert to authenticated
  with check (parent_id = auth.uid() and public.owns_child_profile(child_profile_id, auth.uid()));
drop policy if exists "ba_all" on public.blocked_apps;
create policy "ba_all" on public.blocked_apps for all to authenticated
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid());
drop policy if exists "rt_all" on public.routines;
create policy "rt_all" on public.routines for all to authenticated
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid());

-- ——— Realtime (enable in UI if not auto) ———
-- alter publication supabase_realtime add table public.chat_messages;
-- alter publication supabase_realtime add table public.location_points;

-- ——— Retention (run weekly in SQL or Edge Function) ———
-- delete from public.location_points where recorded_at < now() - interval '7 days';
-- delete from public.chat_messages where created_at < now() - interval '30 days';

-- ——— Storage: chat media ———
insert into storage.buckets (id, name, public) values ('chat-media', 'chat-media', false)
  on conflict (id) do nothing;

drop policy if exists "chat media read" on storage.objects;
drop policy if exists "chat media insert" on storage.objects;
drop policy if exists "chat media delete" on storage.objects;

create policy "chat media read" on storage.objects for select to authenticated
  using (bucket_id = 'chat-media' and (name like auth.uid()::text || '/%'));
create policy "chat media insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-media' and (name like auth.uid()::text || '/%'));
create policy "chat media delete" on storage.objects for delete to authenticated
  using (bucket_id = 'chat-media' and (name like auth.uid()::text || '/%'));

comment on table public.child_profiles is 'Up to 5 per parent; delete cascades feature data.';

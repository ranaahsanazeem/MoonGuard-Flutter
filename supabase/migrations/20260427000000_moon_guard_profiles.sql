-- Moon Guard — core Supabase schema (run in: Dashboard → SQL → New query)
-- Matches: lib/data/profile_model.dart + lib/data/profile_repo.dart

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'parent' check (role in ('parent', 'child')),
  name text,
  phone text,
  country_code text,
  image_url text,
  salary text,
  location text,
  address text,
  father_name text,
  mother_name text,
  emergency_contact text,
  interests text[] default '{}',
  education jsonb default '{}',
  age int,
  gender text,
  languages text[] default '{}',
  schedule jsonb default '{}',
  parent_key text unique,
  parent_id uuid references public.profiles (id) on delete set null,
  profile_completed boolean not null default false,
  onboarding_step int not null default 1,
  location_tracking boolean not null default true,
  activity_alerts boolean not null default true,
  study_alerts boolean not null default true,
  sleep_alerts boolean not null default true,
  location_sharing boolean not null default true,
  learning_reminders boolean not null default true,
  parent_monitoring_alerts boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_parent_key_idx
  on public.profiles (parent_key)
  where parent_key is not null;

create index if not exists profiles_parent_id_idx
  on public.profiles (parent_id)
  where parent_id is not null;

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $fn$
begin
  new.updated_at = now();
  return new;
end;
$fn$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_profiles_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Resolve parent by link code (child onboarding) without exposing all parents via RLS
create or replace function public.get_parent_id_by_key(pkey text)
returns uuid
language sql
security definer
set search_path = public
stable
as $fn$
  select p.id
  from public.profiles p
  where p.role = 'parent'
    and p.parent_key is not null
    and upper(trim(p.parent_key)) = upper(trim(pkey))
  limit 1;
$fn$;

revoke all on function public.get_parent_id_by_key(text) from public;
grant execute on function public.get_parent_id_by_key(text) to anon, authenticated;

-- Optional: own row changes via Realtime (enable table in Dashboard → Realtime if needed)

comment on table public.profiles is 'Moon Guard: one row per user; app upserts after sign-in.';

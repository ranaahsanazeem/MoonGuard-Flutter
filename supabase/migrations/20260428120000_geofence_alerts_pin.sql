-- Geofence on child_profiles, parent alerts, strict app lock flag
-- Run in Supabase SQL after 20260427120000_moon_guard_features.sql

alter table public.child_profiles
  add column if not exists geofence_lat double precision,
  add column if not exists geofence_lng double precision,
  add column if not exists geofence_radius_m double precision,
  add column if not exists geofence_enabled boolean not null default false;

comment on column public.child_profiles.geofence_radius_m is 'Meters; null or 0 = no safe zone.';

alter table public.blocked_apps
  add column if not exists strict_pin boolean not null default true;

comment on column public.blocked_apps.strict_pin is 'If true, device agent should treat as hard block (parent PIN to override).';

create table if not exists public.parent_alerts (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles (id) on delete cascade,
  kind text not null,
  body text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists parent_alerts_parent_unread_idx
  on public.parent_alerts (parent_id, read, created_at desc);

alter table public.parent_alerts enable row level security;

drop policy if exists "alerts_all" on public.parent_alerts;
create policy "alerts_all" on public.parent_alerts for all to authenticated
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid());

comment on table public.parent_alerts is 'In-app + optional push: e.g. child left geofence.';

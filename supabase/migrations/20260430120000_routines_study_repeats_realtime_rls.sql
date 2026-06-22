-- Routines: study kind, child read, daily repeat flag, Realtime
-- Run after 20260427120000_moon_guard_features.sql

-- Allow 'study' in kind
alter table public.routines drop constraint if exists routines_kind_check;
alter table public.routines add constraint routines_kind_check
  check (kind in ('prayer', 'sleep', 'study', 'reminder', 'custom'));

-- Repeat daily flag (app maps to zoned local notifications; offline alarms)
alter table public.routines add column if not exists repeats_daily boolean not null default true;

-- Replace all-or-nothing: parent can manage; linked child can read
drop policy if exists "rt_all" on public.routines;
create policy "rt_parent_routines" on public.routines
  for all to authenticated
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid());

create policy "rt_child_select" on public.routines
  for select to authenticated
  using (public.owns_child_profile(child_profile_id, auth.uid()));

-- Realtime (run once; if "already member of publication", skip)
alter publication supabase_realtime add table public.routines;

comment on column public.routines.repeats_daily is 'When true, schedule daily local notification at time_of_day; when false, next occurrence only.';

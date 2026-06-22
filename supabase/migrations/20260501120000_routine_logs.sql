-- Completion / notification tracking for routines (FYP analytics)
create table if not exists public.routine_logs (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines (id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles (id) on delete cascade,
  log_date date not null default ((now() at time zone 'utc')::date),
  status text not null check (status in ('done', 'missed', 'notified', 'opened')),
  created_at timestamptz not null default now()
);

create index if not exists routine_logs_child_date_idx on public.routine_logs (child_profile_id, log_date desc);

alter table public.routine_logs enable row level security;

drop policy if exists "rlog_parent" on public.routine_logs;
create policy "rlog_parent" on public.routine_logs
  for all to authenticated
  using (
    exists (
      select 1 from public.child_profiles c
      where c.id = routine_logs.child_profile_id
        and c.parent_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.child_profiles c
      where c.id = routine_logs.child_profile_id
        and c.parent_id = auth.uid()
    )
  );

drop policy if exists "rlog_child" on public.routine_logs;
create policy "rlog_child" on public.routine_logs
  for select to authenticated
  using (public.owns_child_profile(child_profile_id, auth.uid()));

drop policy if exists "rlog_child_insert" on public.routine_logs;
create policy "rlog_child_insert" on public.routine_logs
  for insert to authenticated
  with check (public.owns_child_profile(child_profile_id, auth.uid()));

comment on table public.routine_logs is 'Optional log when user opens a routine notification (notified) or marks done/missed.';

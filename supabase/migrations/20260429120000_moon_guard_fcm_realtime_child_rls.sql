-- FCM device token, Realtime for location/chat/alerts, child policies for parent_alerts + blocked_apps
-- Real geofence enforcement & push delivery require: native Android (Play Geofence, FCM) + Edge Function.

-- ——— FCM: store device token on profile (used by future Edge → FCM pipeline) ———
alter table public.profiles
  add column if not exists fcm_token text;
comment on column public.profiles.fcm_token is 'FCM device token; Supabase does not push by itself—Edge Function or backend must send.';

-- ——— Realtime (idempotent: ignore if already added) ———
alter publication supabase_realtime add table public.location_points;
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.parent_alerts;

-- ——— Linked child: insert geofence alerts (Flutter evaluates fence; see app GeofenceAlertService) ———
drop policy if exists "alerts_insert_linked_child" on public.parent_alerts;
create policy "alerts_insert_linked_child" on public.parent_alerts
  for insert to authenticated
  with check (
    exists (
      select 1 from public.child_profiles c
      where c.id = child_profile_id
        and c.parent_id = parent_id
        and c.child_user_id = auth.uid()
    )
  );

-- ——— Linked child: read blocked apps for this device (native Accessibility would enforce) ———
drop policy if exists "ba_select_linked_child" on public.blocked_apps;
create policy "ba_select_linked_child" on public.blocked_apps
  for select to authenticated
  using (public.owns_child_profile(child_profile_id, auth.uid()));

-- ——— Linked child: read keywords for in-app send filtering (same as parent scoping) ———
drop policy if exists "bk_read_linked_child" on public.blocked_keywords;
create policy "bk_read_linked_child" on public.blocked_keywords
  for select to authenticated
  using (
    exists (
      select 1 from public.child_profiles c
      where c.parent_id = blocked_keywords.parent_id
        and c.child_user_id = auth.uid()
        and (blocked_keywords.child_profile_id is null or blocked_keywords.child_profile_id = c.id)
    )
  );

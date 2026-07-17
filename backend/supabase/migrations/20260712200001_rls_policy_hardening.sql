create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using ((select auth.uid()) = user_id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check ((select auth.uid()) = user_id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using ((select auth.uid()) = user_id);

drop policy if exists "body_metrics_select_own" on public.body_metrics;
create policy "body_metrics_select_own" on public.body_metrics
  for select using ((select auth.uid()) = user_id);

drop policy if exists "body_metrics_insert_own" on public.body_metrics;
create policy "body_metrics_insert_own" on public.body_metrics
  for insert with check ((select auth.uid()) = user_id);

drop policy if exists "body_metrics_update_own" on public.body_metrics;
create policy "body_metrics_update_own" on public.body_metrics
  for update using ((select auth.uid()) = user_id);

drop policy if exists "body_metrics_delete_own" on public.body_metrics;
create policy "body_metrics_delete_own" on public.body_metrics
  for delete using ((select auth.uid()) = user_id);

drop policy if exists "meal_photos_select_own" on public.meal_photos;
create policy "meal_photos_select_own" on public.meal_photos
  for select using ((select auth.uid()) = user_id);

drop policy if exists "meal_photos_insert_own" on public.meal_photos;
create policy "meal_photos_insert_own" on public.meal_photos
  for insert with check ((select auth.uid()) = user_id);

drop policy if exists "meal_photos_update_own" on public.meal_photos;
create policy "meal_photos_update_own" on public.meal_photos
  for update using ((select auth.uid()) = user_id);

drop policy if exists "meal_photos_delete_own" on public.meal_photos;
create policy "meal_photos_delete_own" on public.meal_photos
  for delete using ((select auth.uid()) = user_id);

drop policy if exists "meal_entries_select_own" on public.meal_entries;
create policy "meal_entries_select_own" on public.meal_entries
  for select using ((select auth.uid()) = user_id);

drop policy if exists "meal_entries_insert_own" on public.meal_entries;
create policy "meal_entries_insert_own" on public.meal_entries
  for insert with check ((select auth.uid()) = user_id);

drop policy if exists "meal_entries_update_own" on public.meal_entries;
create policy "meal_entries_update_own" on public.meal_entries
  for update using ((select auth.uid()) = user_id);

drop policy if exists "meal_entries_delete_own" on public.meal_entries;
create policy "meal_entries_delete_own" on public.meal_entries
  for delete using ((select auth.uid()) = user_id);

drop policy if exists "workout_sessions_select_own" on public.workout_sessions;
create policy "workout_sessions_select_own" on public.workout_sessions
  for select using ((select auth.uid()) = user_id);

drop policy if exists "workout_sessions_insert_own" on public.workout_sessions;
create policy "workout_sessions_insert_own" on public.workout_sessions
  for insert with check ((select auth.uid()) = user_id);

drop policy if exists "workout_sessions_update_own" on public.workout_sessions;
create policy "workout_sessions_update_own" on public.workout_sessions
  for update using ((select auth.uid()) = user_id);

drop policy if exists "workout_sessions_delete_own" on public.workout_sessions;
create policy "workout_sessions_delete_own" on public.workout_sessions
  for delete using ((select auth.uid()) = user_id);

drop policy if exists "daily_energy_summary_select_own" on public.daily_energy_summary;
create policy "daily_energy_summary_select_own" on public.daily_energy_summary
  for select using ((select auth.uid()) = user_id);

drop policy if exists "daily_energy_summary_insert_own" on public.daily_energy_summary;
create policy "daily_energy_summary_insert_own" on public.daily_energy_summary
  for insert with check ((select auth.uid()) = user_id);

drop policy if exists "daily_energy_summary_update_own" on public.daily_energy_summary;
create policy "daily_energy_summary_update_own" on public.daily_energy_summary
  for update using ((select auth.uid()) = user_id);

drop policy if exists "daily_energy_summary_delete_own" on public.daily_energy_summary;
create policy "daily_energy_summary_delete_own" on public.daily_energy_summary
  for delete using ((select auth.uid()) = user_id);

drop policy if exists "supplement_recommendations_select_own" on public.supplement_recommendations;
create policy "supplement_recommendations_select_own" on public.supplement_recommendations
  for select using ((select auth.uid()) = user_id);

drop policy if exists "supplement_recommendations_insert_own" on public.supplement_recommendations;
create policy "supplement_recommendations_insert_own" on public.supplement_recommendations
  for insert with check ((select auth.uid()) = user_id);

drop policy if exists "supplement_recommendations_update_own" on public.supplement_recommendations;
create policy "supplement_recommendations_update_own" on public.supplement_recommendations
  for update using ((select auth.uid()) = user_id);

drop policy if exists "supplement_recommendations_delete_own" on public.supplement_recommendations;
create policy "supplement_recommendations_delete_own" on public.supplement_recommendations
  for delete using ((select auth.uid()) = user_id);

drop policy if exists "gym_sets_select_own" on public.gym_sets;
create policy "gym_sets_select_own" on public.gym_sets
  for select using (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
        and ws.user_id = (select auth.uid())
    )
  );

drop policy if exists "gym_sets_insert_own" on public.gym_sets;
create policy "gym_sets_insert_own" on public.gym_sets
  for insert with check (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
        and ws.user_id = (select auth.uid())
    )
  );

drop policy if exists "gym_sets_update_own" on public.gym_sets;
create policy "gym_sets_update_own" on public.gym_sets
  for update using (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
        and ws.user_id = (select auth.uid())
    )
  );

drop policy if exists "gym_sets_delete_own" on public.gym_sets;
create policy "gym_sets_delete_own" on public.gym_sets
  for delete using (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
        and ws.user_id = (select auth.uid())
    )
  );

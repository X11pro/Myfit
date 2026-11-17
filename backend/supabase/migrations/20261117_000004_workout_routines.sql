create table if not exists public.workout_routines (
  user_id uuid primary key references auth.users(id) on delete cascade,
  library jsonb not null default '{"routines": [], "activeRoutineId": null}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.workout_routines enable row level security;

create policy "workout_routines_select_own" on public.workout_routines
  for select using (auth.uid() = user_id);
create policy "workout_routines_insert_own" on public.workout_routines
  for insert with check (auth.uid() = user_id);
create policy "workout_routines_update_own" on public.workout_routines
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create policy "workout_routines_delete_own" on public.workout_routines
  for delete using (auth.uid() = user_id);

create trigger workout_routines_set_updated_at
before update on public.workout_routines
for each row execute function public.set_updated_at();

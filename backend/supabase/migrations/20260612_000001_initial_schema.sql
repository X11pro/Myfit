create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text,
  date_of_birth date,
  height_cm numeric,
  sex text,
  activity_level text,
  job_activity_level text,
  goal text,
  target_weight_kg numeric,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id)
);

create table if not exists public.body_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  weight_kg numeric,
  body_fat_percent numeric,
  source text not null default 'manual',
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.food_items (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  source_id text,
  name text not null,
  brand text,
  calories_per_100g numeric,
  protein_per_100g numeric,
  carbs_per_100g numeric,
  fat_per_100g numeric,
  sugar_per_100g numeric,
  fiber_per_100g numeric,
  confidence numeric,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.meal_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  analysis_json jsonb,
  confidence numeric,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.meal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_date date not null,
  meal_type text,
  food_item_id uuid references public.food_items(id) on delete set null,
  name text not null,
  quantity numeric,
  unit text,
  estimated_grams numeric,
  calories numeric not null default 0,
  protein_g numeric not null default 0,
  carbs_g numeric not null default 0,
  fat_g numeric not null default 0,
  sugar_g numeric not null default 0,
  fiber_g numeric,
  source text not null,
  confidence numeric,
  photo_id uuid references public.meal_photos(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null,
  external_id text,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  activity_type text not null,
  duration_minutes numeric,
  active_calories numeric,
  total_calories numeric,
  distance_m numeric,
  avg_heart_rate numeric,
  notes text,
  ai_allowed boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.gym_sets (
  id uuid primary key default gen_random_uuid(),
  workout_session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_name text not null,
  muscle_group text,
  set_number integer not null,
  reps integer,
  weight_kg numeric,
  rpe numeric,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.daily_energy_summary (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  bmr numeric,
  life_activity_calories numeric,
  job_calories numeric,
  exercise_calories numeric,
  calories_in numeric,
  protein_g numeric,
  sugar_g numeric,
  estimated_balance numeric,
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, date)
);

create table if not exists public.supplement_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  recommendation_type text not null,
  reason text not null,
  safety_warning text,
  evidence_level text,
  accepted_by_user boolean,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.profiles enable row level security;
alter table public.body_metrics enable row level security;
alter table public.meal_photos enable row level security;
alter table public.meal_entries enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.gym_sets enable row level security;
alter table public.daily_energy_summary enable row level security;
alter table public.supplement_recommendations enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = user_id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = user_id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = user_id);

create policy "body_metrics_select_own" on public.body_metrics
  for select using (auth.uid() = user_id);
create policy "body_metrics_insert_own" on public.body_metrics
  for insert with check (auth.uid() = user_id);
create policy "body_metrics_update_own" on public.body_metrics
  for update using (auth.uid() = user_id);
create policy "body_metrics_delete_own" on public.body_metrics
  for delete using (auth.uid() = user_id);

create policy "meal_photos_select_own" on public.meal_photos
  for select using (auth.uid() = user_id);
create policy "meal_photos_insert_own" on public.meal_photos
  for insert with check (auth.uid() = user_id);
create policy "meal_photos_update_own" on public.meal_photos
  for update using (auth.uid() = user_id);
create policy "meal_photos_delete_own" on public.meal_photos
  for delete using (auth.uid() = user_id);

create policy "meal_entries_select_own" on public.meal_entries
  for select using (auth.uid() = user_id);
create policy "meal_entries_insert_own" on public.meal_entries
  for insert with check (auth.uid() = user_id);
create policy "meal_entries_update_own" on public.meal_entries
  for update using (auth.uid() = user_id);
create policy "meal_entries_delete_own" on public.meal_entries
  for delete using (auth.uid() = user_id);

create policy "workout_sessions_select_own" on public.workout_sessions
  for select using (auth.uid() = user_id);
create policy "workout_sessions_insert_own" on public.workout_sessions
  for insert with check (auth.uid() = user_id);
create policy "workout_sessions_update_own" on public.workout_sessions
  for update using (auth.uid() = user_id);
create policy "workout_sessions_delete_own" on public.workout_sessions
  for delete using (auth.uid() = user_id);

create policy "gym_sets_select_own" on public.gym_sets
  for select using (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
      and ws.user_id = auth.uid()
    )
  );
create policy "gym_sets_insert_own" on public.gym_sets
  for insert with check (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
      and ws.user_id = auth.uid()
    )
  );
create policy "gym_sets_update_own" on public.gym_sets
  for update using (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
      and ws.user_id = auth.uid()
    )
  );
create policy "gym_sets_delete_own" on public.gym_sets
  for delete using (
    exists (
      select 1
      from public.workout_sessions ws
      where ws.id = workout_session_id
      and ws.user_id = auth.uid()
    )
  );

create policy "daily_energy_summary_select_own" on public.daily_energy_summary
  for select using (auth.uid() = user_id);
create policy "daily_energy_summary_insert_own" on public.daily_energy_summary
  for insert with check (auth.uid() = user_id);
create policy "daily_energy_summary_update_own" on public.daily_energy_summary
  for update using (auth.uid() = user_id);
create policy "daily_energy_summary_delete_own" on public.daily_energy_summary
  for delete using (auth.uid() = user_id);

create policy "supplement_recommendations_select_own" on public.supplement_recommendations
  for select using (auth.uid() = user_id);
create policy "supplement_recommendations_insert_own" on public.supplement_recommendations
  for insert with check (auth.uid() = user_id);
create policy "supplement_recommendations_update_own" on public.supplement_recommendations
  for update using (auth.uid() = user_id);
create policy "supplement_recommendations_delete_own" on public.supplement_recommendations
  for delete using (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

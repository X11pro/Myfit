alter table public.workout_sessions
  add column if not exists title text,
  add column if not exists total_duration_seconds integer,
  add column if not exists active_duration_seconds integer,
  add column if not exists rest_duration_seconds integer;

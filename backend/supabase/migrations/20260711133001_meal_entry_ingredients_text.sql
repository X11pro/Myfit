alter table public.meal_entries
  add column if not exists ingredients_text text;

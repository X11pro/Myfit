create unique index if not exists food_items_source_source_id_unique
on public.food_items (source, source_id)
where source_id is not null;

alter table public.food_items
  add column if not exists nutrition_quality_score numeric,
  add column if not exists nutrition_quality_reason text;

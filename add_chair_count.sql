-- Run once in Supabase SQL editor.
alter table public.shop_settings add column if not exists chair_count integer not null default 3;
alter table public.shop_settings drop constraint if exists shop_settings_chair_count_valid;
alter table public.shop_settings add constraint shop_settings_chair_count_valid check (chair_count between 1 and 20);

alter table public.reports
  alter column business_id drop not null;

alter table public.reports
  add column if not exists is_batch boolean not null default false,
  add column if not exists batch_key text,
  add column if not exists business_names text,
  add column if not exists business_ids text;

create unique index if not exists reports_batch_key_key
  on public.reports (batch_key)
  where batch_key is not null;

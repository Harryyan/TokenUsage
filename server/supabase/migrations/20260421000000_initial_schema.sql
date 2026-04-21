-- ============================================================
-- TokenUsage Multi-Device Sync Backend — Initial Schema
-- ============================================================

-- 1. accounts
create table public.accounts (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text not null,
  display_name text,
  timezone   text not null default 'Pacific/Auckland',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.accounts enable row level security;

create policy "users_own_account" on public.accounts
  for all using (id = auth.uid());

-- 2. devices
create table public.devices (
  id         uuid primary key,
  account_id uuid not null references public.accounts(id) on delete cascade,
  device_name text not null,
  machine_id  text not null,
  os_version  text,
  app_version text,
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now()
);

create index idx_devices_account on public.devices(account_id);
create unique index idx_devices_machine on public.devices(account_id, machine_id);

alter table public.devices enable row level security;

create policy "users_own_devices" on public.devices
  for all using (account_id = auth.uid());

-- 3. device_summaries (one row per device, upsert on each sync)
create table public.device_summaries (
  device_id  uuid primary key references public.devices(id) on delete cascade,
  account_id uuid not null references public.accounts(id) on delete cascade,
  synced_at  timestamptz not null,
  today_tokens  bigint not null default 0,
  today_cost    numeric(12,4) not null default 0,
  week_tokens   bigint not null default 0,
  week_cost     numeric(12,4) not null default 0,
  month_tokens  bigint not null default 0,
  month_cost    numeric(12,4) not null default 0,
  total_tokens  bigint not null default 0,
  total_cost    numeric(12,4) not null default 0,
  schema_version int not null default 1,
  updated_at timestamptz not null default now()
);

create index idx_summaries_account on public.device_summaries(account_id);

alter table public.device_summaries enable row level security;

create policy "users_own_summaries" on public.device_summaries
  for all using (account_id = auth.uid());

-- 4. account_rollups (one row per account, recomputed on each sync)
create table public.account_rollups (
  account_id uuid primary key references public.accounts(id) on delete cascade,
  today_tokens  bigint not null default 0,
  today_cost    numeric(12,4) not null default 0,
  week_tokens   bigint not null default 0,
  week_cost     numeric(12,4) not null default 0,
  month_tokens  bigint not null default 0,
  month_cost    numeric(12,4) not null default 0,
  total_tokens  bigint not null default 0,
  total_cost    numeric(12,4) not null default 0,
  device_count  int not null default 0,
  freshest_sync_at timestamptz,
  aggregated_at    timestamptz not null default now()
);

alter table public.account_rollups enable row level security;

create policy "users_own_rollups" on public.account_rollups
  for all using (account_id = auth.uid());

-- 5. Postgres function: compute rollup from device summaries
create or replace function public.compute_account_rollup(p_account_id uuid)
returns jsonb
language sql
stable
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'today_tokens',  coalesce(sum(today_tokens), 0),
        'today_cost',    coalesce(sum(today_cost), 0),
        'week_tokens',   coalesce(sum(week_tokens), 0),
        'week_cost',     coalesce(sum(week_cost), 0),
        'month_tokens',  coalesce(sum(month_tokens), 0),
        'month_cost',    coalesce(sum(month_cost), 0),
        'total_tokens',  coalesce(sum(total_tokens), 0),
        'total_cost',    coalesce(sum(total_cost), 0),
        'device_count',  count(*)::int,
        'freshest_sync_at', max(synced_at)
      )
      from public.device_summaries
      where account_id = p_account_id
    ),
    '{}'::jsonb
  );
$$;

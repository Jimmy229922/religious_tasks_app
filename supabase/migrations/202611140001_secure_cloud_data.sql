-- REVIEW BEFORE APPLYING TO PRODUCTION.
-- This migration intentionally revokes legacy public access before it grants
-- authenticated, owner-scoped access. It preserves all existing backup rows.

begin;

-- Phase 1: containment. This transaction commits independently so a later
-- ownership-migration failure cannot restore legacy public access.
alter table public.app_backups enable row level security;
alter table public.app_backups force row level security;
revoke all on table public.app_backups from public, anon, authenticated;

do $drop_backup_policies$
declare
  existing_policy record;
begin
  for existing_policy in
    select policyname
    from pg_policies
    where schemaname = 'public' and tablename = 'app_backups'
  loop
    execute format(
      'drop policy if exists %I on public.app_backups',
      existing_policy.policyname
    );
  end loop;
end;
$drop_backup_policies$;

alter table public.global_challenges enable row level security;
alter table public.global_challenges force row level security;
revoke all on table public.global_challenges from public, anon, authenticated;

do $drop_challenge_policies$
declare
  existing_policy record;
begin
  for existing_policy in
    select policyname
    from pg_policies
    where schemaname = 'public' and tablename = 'global_challenges'
  loop
    execute format(
      'drop policy if exists %I on public.global_challenges',
      existing_policy.policyname
    );
  end loop;
end;
$drop_challenge_policies$;

grant select on table public.global_challenges to anon, authenticated;

create policy global_challenges_public_read
  on public.global_challenges
  for select
  to anon, authenticated
  using (id = 'tasbih_challenge');

commit;

-- Phase 2: authenticated ownership and bounded write paths.
begin;

alter table public.app_backups
  add column if not exists owner_id uuid references auth.users(id) on delete cascade;

alter table public.app_backups
  drop constraint if exists app_backups_pkey;

alter table public.app_backups
  alter column user_email drop not null;

create unique index if not exists app_backups_owner_id_key
  on public.app_backups (owner_id);

grant select, insert, update, delete
  on table public.app_backups to authenticated;

create policy app_backups_select_own
  on public.app_backups
  for select
  to authenticated
  using (owner_id = (select auth.uid()));

create policy app_backups_insert_own
  on public.app_backups
  for insert
  to authenticated
  with check (owner_id = (select auth.uid()));

create policy app_backups_update_own
  on public.app_backups
  for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy app_backups_delete_own
  on public.app_backups
  for delete
  to authenticated
  using (owner_id = (select auth.uid()));

create or replace function public.claim_legacy_app_backup()
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  verified_email text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required'
      using errcode = '42501';
  end if;

  select lower(users.email)
  into verified_email
  from auth.users as users
  where users.id = auth.uid()
    and users.email_confirmed_at is not null
    and exists (
      select 1
      from auth.identities as identities
      where identities.user_id = users.id
        and identities.provider = 'google'
    );

  if verified_email is null then
    raise exception 'A verified Google identity is required'
      using errcode = '42501';
  end if;

  -- If this identity already owns a row, retain it and remove the legacy email.
  update public.app_backups
  set user_email = null
  where owner_id = auth.uid();

  if found then
    return true;
  end if;

  -- Claim at most the newest matching legacy row. Duplicate legacy rows remain
  -- untouched for an owner-reviewed migration instead of causing a unique-key
  -- failure or deleting historical data automatically.
  with legacy_candidate as (
    select backups.ctid
    from public.app_backups as backups
    where backups.owner_id is null
      and lower(backups.user_email) = verified_email
    order by backups.updated_at desc nulls last, backups.ctid
    limit 1
    for update
  )
  update public.app_backups as backups
  set owner_id = auth.uid(), user_email = null
  where backups.ctid in (
    select candidate.ctid
    from legacy_candidate as candidate
  );

  return exists (
    select 1
    from public.app_backups
    where owner_id = auth.uid()
  );
end;
$function$;

revoke all on function public.claim_legacy_app_backup() from public, anon;
grant execute on function public.claim_legacy_app_backup() to authenticated;

create table if not exists public.global_challenge_rate_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null default now(),
  window_amount integer not null default 0 check (window_amount >= 0)
);

alter table public.global_challenge_rate_limits enable row level security;
alter table public.global_challenge_rate_limits force row level security;
revoke all on table public.global_challenge_rate_limits from public, anon, authenticated;

drop function if exists public.increment_challenge(integer);

create function public.increment_challenge(amount integer)
returns bigint
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  rate_window public.global_challenge_rate_limits%rowtype;
  updated_count bigint;
begin
  if current_user_id is null then
    raise exception 'Authentication is required'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from auth.users as users
    where users.id = current_user_id
      and users.email_confirmed_at is not null
      and exists (
        select 1
        from auth.identities as identities
        where identities.user_id = current_user_id
          and identities.provider = 'google'
      )
  ) then
    raise exception 'A verified Google identity is required'
      using errcode = '42501';
  end if;

  if amount is null or amount < 1 or amount > 100 then
    raise exception 'Increment must be between 1 and 100'
      using errcode = '22023';
  end if;

  insert into public.global_challenge_rate_limits (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  select *
  into rate_window
  from public.global_challenge_rate_limits
  where user_id = current_user_id
  for update;

  if rate_window.window_started_at < now() - interval '1 minute' then
    update public.global_challenge_rate_limits
    set window_started_at = now(), window_amount = amount
    where user_id = current_user_id;
  elsif rate_window.window_amount + amount <= 300 then
    update public.global_challenge_rate_limits
    set window_amount = window_amount + amount
    where user_id = current_user_id;
  else
    raise exception 'Challenge increment rate exceeded'
      using errcode = '22023';
  end if;

  update public.global_challenges
  set count = count + amount
  where id = 'tasbih_challenge'
  returning count into updated_count;

  if updated_count is null then
    raise exception 'Challenge record is missing';
  end if;

  return updated_count;
end;
$function$;

revoke all on function public.increment_challenge(integer) from public, anon;
grant execute on function public.increment_challenge(integer) to authenticated;

create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Authentication is required'
      using errcode = '42501';
  end if;

  delete from auth.users where id = auth.uid();
end;
$function$;

revoke all on function public.delete_user_account() from public, anon;
grant execute on function public.delete_user_account() to authenticated;

commit;

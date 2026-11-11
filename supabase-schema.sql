-- PROJECT 100M V2 · Supabase SQL Editor setup
-- Run this once in your own Supabase project before enabling cloud credentials.
-- The table belongs to each auth.uid() and is never public to anonymous users.
create table if not exists public.training_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 0,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.training_states enable row level security;
revoke all on public.training_states from anon;
grant select, insert, update on public.training_states to authenticated;

drop policy if exists "training_states_select_own" on public.training_states;
create policy "training_states_select_own"
  on public.training_states for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "training_states_insert_own" on public.training_states;
create policy "training_states_insert_own"
  on public.training_states for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "training_states_update_own" on public.training_states;
create policy "training_states_update_own"
  on public.training_states for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Atomic optimistic locking: a stale device cannot silently overwrite a newer revision.
create or replace function public.save_training_state(
  p_expected_revision bigint,
  p_payload jsonb
) returns bigint
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_revision bigint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if jsonb_typeof(p_payload) <> 'object' or p_payload->>'version' <> '2' then
    raise exception 'Invalid training state';
  end if;
  insert into public.training_states (user_id, revision, payload)
    values (auth.uid(), 1, p_payload)
  on conflict (user_id) do update
    set revision = public.training_states.revision + 1,
        payload = excluded.payload,
        updated_at = now()
    where public.training_states.revision = p_expected_revision
  returning revision into v_revision;
  -- NULL indicates an out-of-date revision; client should download and resolve conflict.
  return v_revision;
end;
$$;

revoke all on function public.save_training_state(bigint,jsonb) from public, anon;
grant execute on function public.save_training_state(bigint,jsonb) to authenticated;

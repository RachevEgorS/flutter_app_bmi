-- Run in the SQL Editor of the existing Supabase project if access is not set up.
-- No table or data is created/deleted. Owner checks also constrain existing
-- permissive policies for the authenticated role.
begin;

alter table public.body_mass_index_calculations enable row level security;
revoke select, insert, update, delete
  on public.body_mass_index_calculations from anon;
grant select, insert on public.body_mass_index_calculations to authenticated;

drop policy if exists bmi_anon_guard on public.body_mass_index_calculations;
create policy bmi_anon_guard
  on public.body_mass_index_calculations as restrictive
  for all to anon
  using (false)
  with check (false);

drop policy if exists bmi_owner_guard on public.body_mass_index_calculations;
create policy bmi_owner_guard
  on public.body_mass_index_calculations as restrictive
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists bmi_select_own on public.body_mass_index_calculations;
create policy bmi_select_own
  on public.body_mass_index_calculations
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists bmi_insert_own on public.body_mass_index_calculations;
create policy bmi_insert_own
  on public.body_mass_index_calculations
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

commit;

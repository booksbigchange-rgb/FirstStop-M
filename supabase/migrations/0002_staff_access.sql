-- Additive hardening of the existing foundation. No operational data is deleted.
alter table public.profiles add column active boolean not null default true;

create or replace function public.my_business_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select business_id from public.profiles where user_id = (select auth.uid()) and active
$$;
create or replace function public.my_role()
returns text language sql stable security definer set search_path = '' as $$
  select role from public.profiles where user_id = (select auth.uid()) and active
$$;

revoke all on public.businesses, public.profiles, public.wash_services,
  public.wash_jobs, public.cafe_products, public.cafe_orders, public.cafe_order_items
  from anon, authenticated;
grant select on public.businesses, public.profiles, public.wash_services,
  public.wash_jobs, public.cafe_products, public.cafe_orders, public.cafe_order_items
  to authenticated;

drop policy profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using (
  business_id = (select public.my_business_id()) and
  (user_id = (select auth.uid()) or (select public.my_role()) in ('owner','manager'))
);
drop policy wash_services_read on public.wash_services;
create policy wash_services_read on public.wash_services for select to authenticated using (
  business_id = (select public.my_business_id()) and
  (select public.my_role()) in ('owner','manager','cashier','washer')
);
drop policy wash_jobs_read on public.wash_jobs;
create policy wash_jobs_read on public.wash_jobs for select to authenticated using (
  business_id = (select public.my_business_id()) and
  (select public.my_role()) in ('owner','manager','cashier','washer')
);
drop policy cafe_products_read on public.cafe_products;
create policy cafe_products_read on public.cafe_products for select to authenticated using (
  business_id = (select public.my_business_id()) and
  (select public.my_role()) in ('owner','manager','cashier','barista')
);
drop policy cafe_orders_read on public.cafe_orders;
create policy cafe_orders_read on public.cafe_orders for select to authenticated using (
  business_id = (select public.my_business_id()) and
  (select public.my_role()) in ('owner','manager','cashier','barista')
);

-- Protect relationships against accidentally linking records across businesses.
alter table public.wash_services add constraint wash_services_business_id_id_key unique(business_id,id);
alter table public.wash_jobs add constraint wash_jobs_same_business_service
  foreign key (business_id,service_id) references public.wash_services(business_id,id);
alter table public.cafe_products add constraint cafe_products_business_id_id_key unique(business_id,id);
alter table public.cafe_orders add constraint cafe_orders_business_id_id_key unique(business_id,id);
alter table public.cafe_order_items add column business_id uuid;
update public.cafe_order_items i set business_id=o.business_id from public.cafe_orders o where o.id=i.order_id;
alter table public.cafe_order_items alter column business_id set not null;
alter table public.cafe_order_items add constraint cafe_items_same_business_order
  foreign key(business_id,order_id) references public.cafe_orders(business_id,id);
alter table public.cafe_order_items add constraint cafe_items_same_business_product
  foreign key(business_id,product_id) references public.cafe_products(business_id,id);
create index wash_jobs_business_idx on public.wash_jobs(business_id);
create index cafe_orders_business_idx on public.cafe_orders(business_id);
create index cafe_order_items_order_idx on public.cafe_order_items(order_id);

create table public.staff_audit (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  actor_id uuid not null references auth.users(id),
  target_id uuid not null references auth.users(id),
  action text not null,
  created_at timestamptz not null default now()
);
alter table public.staff_audit enable row level security;
revoke all on public.staff_audit from anon, authenticated;
grant select on public.staff_audit to authenticated;
create policy staff_audit_owner_read on public.staff_audit for select to authenticated
using (business_id=(select public.my_business_id()) and (select public.my_role())='owner');
create index staff_audit_business_idx on public.staff_audit(business_id);

-- Only the owner can attach an existing confirmed Auth account to this business.
-- The routine cannot create owners, alter owners, or claim another business's user.
create function public.set_staff_access(staff_email text, staff_role text, staff_name text, enabled boolean default true)
returns void language plpgsql security definer set search_path = '' as $$
declare target uuid; tenant uuid; existing public.profiles;
begin
  tenant := public.my_business_id();
  if public.my_role() is distinct from 'owner' or tenant is null then
    raise exception 'Owner access required' using errcode='42501';
  end if;
  if staff_role is null or staff_role not in ('manager','cashier','washer','barista')
    or staff_name is null or length(trim(staff_name)) not between 1 and 120 or enabled is null then
    raise exception 'Invalid staff details' using errcode='22023';
  end if;
  select id into target from auth.users where lower(email)=lower(trim(staff_email))
    and email_confirmed_at is not null and deleted_at is null;
  if target is null then raise exception 'A confirmed account is required' using errcode='22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(target::text,0));
  select * into existing from public.profiles where user_id=target for update;
  if found and (existing.business_id<>tenant or existing.role='owner') then
    raise exception 'This account cannot be changed' using errcode='42501';
  end if;
  insert into public.profiles(user_id,business_id,display_name,role,active)
  values(target,tenant,trim(staff_name),staff_role,enabled)
  on conflict(user_id) do update set display_name=excluded.display_name,role=excluded.role,active=excluded.active;
  insert into public.staff_audit(business_id,actor_id,target_id,action)
    values(tenant,auth.uid(),target,'staff_access:' || staff_role || ':' || enabled::text);
end $$;
revoke all on function public.set_staff_access(text,text,text,boolean) from public, anon;
grant execute on function public.set_staff_access(text,text,text,boolean) to authenticated;

create function public.set_preferred_language(language_code text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if public.my_business_id() is null then raise exception 'Active account required' using errcode='42501'; end if;
  if language_code is null or language_code not in ('en','am') then
    raise exception 'Unsupported language' using errcode='22023';
  end if;
  update public.profiles set preferred_language=language_code where user_id=auth.uid();
end $$;
revoke all on function public.set_preferred_language(text) from public, anon;
grant execute on function public.set_preferred_language(text) to authenticated;

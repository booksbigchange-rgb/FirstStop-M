-- FirstStop-M initial schema. Apply to a NEW Supabase project with SQL Editor.
-- Security: no public table grants or permissive cross-business policies.
create extension if not exists pgcrypto;

create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  created_at timestamptz not null default now()
);
create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  business_id uuid not null references public.businesses(id),
  display_name text not null default '',
  role text not null check (role in ('owner','manager','cashier','washer','barista')),
  preferred_language text not null default 'en' check (preferred_language in ('en','am')),
  created_at timestamptz not null default now()
);
create index profiles_business_idx on public.profiles(business_id);

-- SECURITY DEFINER functions do not recursively query an RLS-protected profile policy.
create or replace function public.my_business_id()
returns uuid language sql stable security definer
set search_path = '' as $$
  select p.business_id from public.profiles p where p.user_id = (select auth.uid())
$$;
create or replace function public.my_role()
returns text language sql stable security definer
set search_path = '' as $$
  select p.role from public.profiles p where p.user_id = (select auth.uid())
$$;
revoke all on function public.my_business_id() from public;
revoke all on function public.my_role() from public;
grant execute on function public.my_business_id() to authenticated;
grant execute on function public.my_role() to authenticated;

create table public.wash_services (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name_en text not null,
  name_am text not null,
  price_etb numeric(12,2) not null check (price_etb >= 0),
  active boolean not null default true
);
create table public.wash_jobs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  service_id uuid not null references public.wash_services(id),
  plate_number text not null,
  status text not null default 'waiting'
    check (status in ('waiting','washing','ready','completed','cancelled')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create table public.cafe_products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  name_en text not null,
  name_am text not null,
  price_etb numeric(12,2) not null check (price_etb >= 0),
  active boolean not null default true
);
create table public.cafe_orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  status text not null default 'new'
    check (status in ('new','preparing','ready','served','cancelled')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create table public.cafe_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.cafe_orders(id),
  product_id uuid not null references public.cafe_products(id),
  quantity integer not null check (quantity > 0)
);
-- Monetary settlement intentionally excluded: payment totals must be calculated
-- server-side at checkout against validated service/product prices.

alter table public.businesses enable row level security;
alter table public.profiles enable row level security;
alter table public.wash_services enable row level security;
alter table public.wash_jobs enable row level security;
alter table public.cafe_products enable row level security;
alter table public.cafe_orders enable row level security;
alter table public.cafe_order_items enable row level security;

create policy businesses_read on public.businesses for select to authenticated
  using (id = (select public.my_business_id()));
create policy profiles_read on public.profiles for select to authenticated
  using (business_id = (select public.my_business_id()));
create policy wash_services_read on public.wash_services for select to authenticated
  using (business_id = (select public.my_business_id()));
create policy cafe_products_read on public.cafe_products for select to authenticated
  using (business_id = (select public.my_business_id()));
create policy wash_jobs_read on public.wash_jobs for select to authenticated
  using (business_id = (select public.my_business_id()));
create policy cafe_orders_read on public.cafe_orders for select to authenticated
  using (business_id = (select public.my_business_id()));
create policy cafe_order_items_read on public.cafe_order_items for select to authenticated
  using (exists (
    select 1 from public.cafe_orders o
    where o.id = order_id and o.business_id = (select public.my_business_id())
  ));

-- No direct INSERT/UPDATE/DELETE policies yet.
-- Use controlled server-side checkout and staff-management RPCs in the next milestone.
-- Provision first business and owner profile using an administrator, never the mobile app.

-- Run as database administrator. Every fixture and change is rolled back.
begin;
do $$
declare
  a uuid := gen_random_uuid(); b uuid := gen_random_uuid();
  owner_a uuid := gen_random_uuid(); owner_b uuid := gen_random_uuid();
  staff uuid := gen_random_uuid(); unassigned uuid := gen_random_uuid();
  svc uuid := gen_random_uuid(); other_svc uuid := gen_random_uuid();
  product uuid := gen_random_uuid(); other_product uuid := gen_random_uuid();
  ord uuid := gen_random_uuid(); r text; n integer; denied boolean;
begin
  insert into auth.users(id,email,email_confirmed_at) values
    (owner_a,owner_a||'@example.invalid',now()),(owner_b,owner_b||'@example.invalid',now()),
    (staff,staff||'@example.invalid',now()),(unassigned,unassigned||'@example.invalid',now());
  insert into public.businesses(id,name) values(a,'Permission test A'),(b,'Permission test B');
  insert into public.profiles(user_id,business_id,role) values(owner_a,a,'owner'),(owner_b,b,'owner'),(staff,a,'cashier');
  insert into public.wash_services(id,business_id,name_en,name_am,price_etb) values(svc,a,'Test','ሙከራ',1),(other_svc,b,'Test','ሙከራ',1);
  insert into public.cafe_products(id,business_id,name_en,name_am,price_etb) values(product,a,'Test','ሙከራ',1),(other_product,b,'Test','ሙከራ',1);
  insert into public.wash_jobs(business_id,service_id,plate_number,created_by) values(a,svc,'TEST',owner_a),(b,other_svc,'TEST',owner_b);
  insert into public.cafe_orders(id,business_id,created_by) values(ord,a,owner_a),(gen_random_uuid(),b,owner_b);
  insert into public.cafe_order_items(business_id,order_id,product_id,quantity) values(a,ord,product,1);

  denied:=false;
  begin insert into public.wash_jobs(business_id,service_id,plate_number,created_by) values(a,other_svc,'TEST',owner_a);
  exception when foreign_key_violation then denied:=true; end;
  if not denied then raise exception 'Cross-business service reference allowed'; end if;
  denied:=false;
  begin insert into public.cafe_order_items(business_id,order_id,product_id,quantity) values(a,ord,other_product,1);
  exception when foreign_key_violation then denied:=true; end;
  if not denied then raise exception 'Cross-business product reference allowed'; end if;

  perform set_config('request.jwt.claim.sub',staff::text,true);
  foreach r in array array['owner','manager','cashier','washer','barista'] loop
    update public.profiles set role=r where user_id=staff;
    execute 'set local role authenticated';
    select count(*) into n from public.businesses;
    if n<>1 then raise exception 'Business isolation failed: %',r; end if;
    select count(*) into n from public.profiles;
    if n<>(case when r in ('owner','manager') then 2 else 1 end) then raise exception 'Profile visibility failed: %',r; end if;
    select count(*) into n from public.wash_jobs;
    if n<>(case when r='barista' then 0 else 1 end) then raise exception 'Wash access failed: %',r; end if;
    select count(*) into n from public.cafe_orders;
    if n<>(case when r='washer' then 0 else 1 end) then raise exception 'Cafe access failed: %',r; end if;
    select count(*) into n from public.cafe_order_items;
    if n<>(case when r='washer' then 0 else 1 end) then raise exception 'Cafe item access failed: %',r; end if;
    denied:=false;
    begin update public.profiles set role='owner' where user_id=staff;
    exception when insufficient_privilege then denied:=true; end;
    if not denied then raise exception 'Direct role escalation allowed'; end if;
    denied:=false;
    begin insert into public.wash_jobs(business_id,service_id,plate_number,created_by) values(a,svc,'TEST',staff);
    exception when insufficient_privilege then denied:=true; end;
    if not denied then raise exception 'Unreviewed direct transaction write allowed'; end if;
    perform public.set_preferred_language('am');
    if r<>'owner' then
      denied:=false;
      begin perform public.set_staff_access(unassigned||'@example.invalid','manager','Test',true);
      exception when insufficient_privilege then denied:=true; end;
      if not denied then raise exception 'Staff management allowed to %',r; end if;
    end if;
    execute 'reset role';
  end loop;

  perform set_config('request.jwt.claim.sub',owner_a::text,true);
  execute 'set local role authenticated';
  perform public.set_staff_access(unassigned||'@example.invalid','barista','Test',true);
  denied:=false;
  begin perform public.set_staff_access(owner_b||'@example.invalid','cashier','Test',true);
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Owner claimed other business user'; end if;
  denied:=false;
  begin perform public.set_staff_access(owner_a||'@example.invalid','cashier','Test',true);
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Owner role overwritten'; end if;
  denied:=false;
  begin perform public.set_staff_access(unassigned||'@example.invalid','owner','Test',true);
  exception when invalid_parameter_value then denied:=true; end;
  if not denied then raise exception 'Owner created through staff RPC'; end if;
  perform public.set_staff_access(unassigned||'@example.invalid','barista','Test',false);
  execute 'reset role';
  perform set_config('request.jwt.claim.sub',unassigned::text,true);
  execute 'set local role authenticated';
  if public.my_business_id() is not null then raise exception 'Disabled account has business access'; end if;
  select count(*) into n from public.cafe_products;
  if n<>0 then raise exception 'Disabled account reads products'; end if;
  execute 'reset role';

  if (select preferred_language from public.profiles where user_id=staff)<>'am' then raise exception 'Language preference not saved'; end if;
  if (select count(*) from public.staff_audit where business_id=a)<>2 then raise exception 'Staff audit missing'; end if;
  if exists(select 1 from information_schema.role_table_grants where table_schema='public' and grantee in ('anon','authenticated') and privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE')) then raise exception 'Unexpected direct write grant'; end if;

  perform set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  execute 'set local role authenticated';
  select count(*) into n from public.businesses;
  if n<>0 then raise exception 'Unassigned account reads business'; end if;
  execute 'reset role';
  execute 'set local role anon';
  denied:=false;
  begin perform * from public.businesses;
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Anonymous business access'; end if;
  denied:=false;
  begin perform public.my_business_id();
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Anonymous helper function access'; end if;
  execute 'reset role';
end $$;
select 'PASS: five roles, tenant isolation, escalation, staff management, revocation, bilingual preference and foreign keys' as result;
rollback;


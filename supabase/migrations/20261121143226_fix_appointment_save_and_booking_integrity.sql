
create or replace function public.save_staff_appointment(
  p_shop_id uuid,p_appointment_id uuid,p_customer_id uuid,p_appointment_date date,
  p_start_time time without time zone,p_duration_minutes integer default null,
  p_notes text default null,p_status text default 'confirmed'
)
returns uuid language plpgsql security invoker set search_path=public,pg_temp
as $function$
declare
  v_uid uuid:=auth.uid(); v_settings public.shop_settings%rowtype;
  v_customer public.customers%rowtype; v_appointment public.appointments%rowtype;
  v_slot public.appointment_slots%rowtype; v_slot_id uuid:=null;
  v_appointment_id uuid; v_start integer; v_end integer; v_min integer;
begin
  if v_uid is null or not public.is_shop_staff(p_shop_id) then raise exception 'غير مصرح لك بإدارة مواعيد هذا المحل'; end if;
  if p_appointment_date is null or p_appointment_date<current_date then raise exception 'اختر تاريخاً صحيحاً من اليوم أو بعده'; end if;
  if p_start_time is null or extract(second from p_start_time)<>0 or mod(extract(minute from p_start_time)::integer,15)<>0 then raise exception 'اختر وقتاً صحيحاً بفواصل 15 دقيقة'; end if;
  if p_duration_minutes is not null and (p_duration_minutes<5 or p_duration_minutes>360) then raise exception 'مدة الموعد يجب أن تكون بين 5 و360 دقيقة'; end if;
  if coalesce(p_status,'confirmed') not in ('pending','confirmed','rejected','in_service','completed','no_show','cancelled') then raise exception 'حالة الموعد غير صالحة'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_shop_id::text||':'||p_appointment_date::text,0));
  select * into v_settings from public.shop_settings where shop_id=p_shop_id;
  if not found then raise exception 'لم يتم العثور على إعدادات دوام المحل'; end if;
  if v_settings.weekly_day_off is not null and extract(isodow from p_appointment_date)::smallint=v_settings.weekly_day_off then raise exception 'المحل مغلق في يوم العطلة الأسبوعية'; end if;
  v_start:=extract(hour from v_settings.work_start)::integer*60+extract(minute from v_settings.work_start)::integer;
  v_end:=extract(hour from v_settings.work_end)::integer*60+extract(minute from v_settings.work_end)::integer;
  v_min:=extract(hour from p_start_time)::integer*60+extract(minute from p_start_time)::integer;
  if v_start=v_end then raise exception 'حدد ساعات دوام صحيحة قبل حفظ الموعد';
  elsif v_end>v_start and not(v_min>=v_start and v_min<v_end) then raise exception 'وقت الموعد خارج ساعات دوام المحل';
  elsif v_end<v_start and not(v_min>=v_start or v_min<v_end) then raise exception 'وقت الموعد خارج ساعات دوام المحل'; end if;
  select * into v_customer from public.customers where id=p_customer_id and shop_id=p_shop_id;
  if not found then raise exception 'الزبون المحدد لا يتبع مساحة العمل الحالية'; end if;
  if p_appointment_id is not null then
    select * into v_appointment from public.appointments where id=p_appointment_id and shop_id=p_shop_id for update;
    if not found then raise exception 'لم يتم العثور على الموعد المطلوب تعديله'; end if;
  end if;
  if coalesce(p_status,'confirmed') not in ('cancelled','rejected','no_show') then
    if exists(select 1 from public.appointments a where a.shop_id=p_shop_id and a.appointment_date=p_appointment_date and a.id is distinct from p_appointment_id and a.status not in ('cancelled','rejected','no_show') and (a.appointment_date+a.start_time)<(p_appointment_date+p_start_time+make_interval(mins=>coalesce(p_duration_minutes,15))) and (a.appointment_date+a.start_time+make_interval(mins=>coalesce(a.duration_minutes,15)))>(p_appointment_date+p_start_time)) then raise exception 'هذا الموعد يتعارض مع موعد آخر. اختر وقتاً مختلفاً'; end if;
    insert into public.appointment_slots(shop_id,slot_date,start_time,status) values(p_shop_id,p_appointment_date,p_start_time,'available') on conflict(shop_id,slot_date,start_time) do nothing;
    select * into v_slot from public.appointment_slots where shop_id=p_shop_id and slot_date=p_appointment_date and start_time=p_start_time for update;
    if not found then raise exception 'تعذر تجهيز وقت الحجز. حدّث الأوقات ثم أعد المحاولة'; end if;
    if v_slot.status='booked' and (p_appointment_id is null or v_slot.appointment_id is distinct from p_appointment_id) then raise exception 'هذا الوقت محجوز بالفعل، اختر وقتاً آخر'; end if;
    v_slot_id:=v_slot.id;
  end if;
  if p_appointment_id is null then
    insert into public.appointments(shop_id,customer_id,created_by,idempotency_key,appointment_date,start_time,duration_minutes,customer_name_snapshot,customer_phone_snapshot,status,notes,slot_id,updated_at)
    values(p_shop_id,p_customer_id,v_uid,gen_random_uuid(),p_appointment_date,p_start_time,p_duration_minutes,v_customer.full_name,v_customer.phone,coalesce(p_status,'confirmed'),nullif(trim(coalesce(p_notes,'')),''),v_slot_id,now())
    returning id into v_appointment_id;
  else
    update public.appointments set customer_id=p_customer_id,appointment_date=p_appointment_date,start_time=p_start_time,duration_minutes=p_duration_minutes,customer_name_snapshot=v_customer.full_name,customer_phone_snapshot=v_customer.phone,status=coalesce(p_status,'confirmed'),notes=nullif(trim(coalesce(p_notes,'')),''),slot_id=v_slot_id,updated_at=now()
    where id=p_appointment_id and shop_id=p_shop_id returning id into v_appointment_id;
    if v_appointment_id is null then raise exception 'لم يتم حفظ تعديلات الموعد'; end if;
  end if;
  return v_appointment_id;
end;
$function$;
revoke all on function public.save_staff_appointment(uuid,uuid,uuid,date,time,integer,text,text) from public,anon;
grant execute on function public.save_staff_appointment(uuid,uuid,uuid,date,time,integer,text,text) to authenticated;


create or replace function public.book_my_appointment_slot(p_slot_id uuid,p_notes text default null)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $function$
declare
 v_uid uuid:=auth.uid(); v_customer public.customers%rowtype;
 v_slot public.appointment_slots%rowtype; v_settings public.shop_settings%rowtype;
 v_slot_date date; v_appointment_id uuid; v_start integer; v_end integer; v_min integer;
begin
 if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
 select * into v_customer from public.customers where user_id=v_uid limit 1;
 if not found then raise exception 'حساب الزبون غير مرتبط بالمحل'; end if;
 select slot_date into v_slot_date from public.appointment_slots where id=p_slot_id and shop_id=v_customer.shop_id;
 if not found then raise exception 'هذا الوقت غير متاح للحجز'; end if;
 perform pg_advisory_xact_lock(hashtextextended(v_customer.shop_id::text||':'||v_slot_date::text,0));
 select * into v_slot from public.appointment_slots where id=p_slot_id and shop_id=v_customer.shop_id for update;
 if not found or v_slot.status<>'available' then raise exception 'هذا الوقت لم يعد متاحاً. حدّث الأوقات واختر وقتاً آخر'; end if;
 if v_slot.slot_date<current_date then raise exception 'لا يمكن حجز تاريخ سابق'; end if;
 select * into v_settings from public.shop_settings where shop_id=v_customer.shop_id;
 if not found then raise exception 'تعذر تحميل إعدادات دوام المحل'; end if;
 if v_settings.weekly_day_off is not null and extract(isodow from v_slot.slot_date)::smallint=v_settings.weekly_day_off then raise exception 'الحلاق في عطلة بهذا اليوم'; end if;
 v_start:=extract(hour from v_settings.work_start)::integer*60+extract(minute from v_settings.work_start)::integer;
 v_end:=extract(hour from v_settings.work_end)::integer*60+extract(minute from v_settings.work_end)::integer;
 v_min:=extract(hour from v_slot.start_time)::integer*60+extract(minute from v_slot.start_time)::integer;
 if v_start=v_end then raise exception 'المحل لم يحدد ساعات دوام صحيحة';
 elsif v_end>v_start and not(v_min>=v_start and v_min<v_end) then raise exception 'هذا الوقت خارج ساعات دوام المحل';
 elsif v_end<v_start and not(v_min>=v_start or v_min<v_end) then raise exception 'هذا الوقت خارج ساعات دوام المحل'; end if;
 if exists(select 1 from public.appointments a where a.shop_id=v_customer.shop_id and a.appointment_date=v_slot.slot_date and a.status not in ('cancelled','rejected','no_show') and (a.appointment_date+a.start_time)<(v_slot.slot_date+v_slot.start_time+interval '15 minutes') and (a.appointment_date+a.start_time+make_interval(mins=>coalesce(a.duration_minutes,15)))>(v_slot.slot_date+v_slot.start_time)) then raise exception 'هذا الوقت يتعارض مع موعد آخر. اختر وقتاً آخر'; end if;
 insert into public.appointments(shop_id,customer_id,created_by,idempotency_key,appointment_date,start_time,service_id,service_name,customer_name_snapshot,customer_phone_snapshot,status,notes,slot_id)
 values(v_customer.shop_id,v_customer.id,v_uid,gen_random_uuid(),v_slot.slot_date,v_slot.start_time,null,'',v_customer.full_name,v_customer.phone,'pending',nullif(trim(coalesce(p_notes,'')),''),v_slot.id)
 returning id into v_appointment_id;
 return v_appointment_id;
end;
$function$;
revoke all on function public.book_my_appointment_slot(uuid,text) from public,anon;
grant execute on function public.book_my_appointment_slot(uuid,text) to authenticated;


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

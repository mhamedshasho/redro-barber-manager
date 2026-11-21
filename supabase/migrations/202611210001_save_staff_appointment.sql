create or replace function public.save_staff_appointment(
  p_shop_id uuid,
  p_appointment_id uuid,
  p_customer_id uuid,
  p_appointment_date date,
  p_start_time time,
  p_duration_minutes integer default null,
  p_notes text default null,
  p_status text default 'confirmed'
)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_customer public.customers%rowtype;
  v_appointment public.appointments%rowtype;
  v_slot public.appointment_slots%rowtype;
  v_appointment_id uuid;
  v_slot_id uuid;
  v_status text := coalesce(nullif(p_status, ''), 'confirmed');
begin
  if v_user is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if not public.is_shop_staff(p_shop_id) then raise exception 'ليس لديك صلاحية إدارة هذا المحل'; end if;
  if p_appointment_date is null or p_start_time is null then raise exception 'تاريخ ووقت الموعد مطلوبان'; end if;
  if p_duration_minutes is not null and (p_duration_minutes < 5 or p_duration_minutes > 360) then raise exception 'مدة الموعد يجب أن تكون بين 5 و360 دقيقة'; end if;
  if v_status not in ('confirmed','pending','in_service','completed','no_show','cancelled','rejected') then raise exception 'حالة الموعد غير صالحة'; end if;
  select * into v_customer from public.customers where id=p_customer_id and shop_id=p_shop_id;
  if not found then raise exception 'الزبون غير موجود ضمن هذا المحل'; end if;
  if p_appointment_id is not null then
    select * into v_appointment from public.appointments where id=p_appointment_id and shop_id=p_shop_id for update;
    if not found then raise exception 'الموعد المطلوب تعديله غير موجود أو لا تملك صلاحية الوصول إليه'; end if;
  end if;
  if v_status not in ('cancelled','rejected','no_show') then
    if exists (select 1 from public.appointments a where a.shop_id=p_shop_id and a.appointment_date=p_appointment_date and a.start_time=p_start_time and a.id is distinct from p_appointment_id and a.status not in ('cancelled','rejected','no_show')) then
      raise exception 'هذا الوقت محجوز بالفعل';
    end if;
    insert into public.appointment_slots(shop_id,slot_date,start_time,status) values(p_shop_id,p_appointment_date,p_start_time,'available')
    on conflict(shop_id,slot_date,start_time) do nothing;
    select * into v_slot from public.appointment_slots where shop_id=p_shop_id and slot_date=p_appointment_date and start_time=p_start_time for update;
    if v_slot.status='booked' and v_slot.appointment_id is distinct from p_appointment_id then raise exception 'هذا الوقت محجوز بالفعل، اختر وقتاً آخر'; end if;
    v_slot_id:=v_slot.id;
  end if;
  if p_appointment_id is not null then
    update public.appointments set customer_id=p_customer_id,appointment_date=p_appointment_date,start_time=p_start_time,duration_minutes=p_duration_minutes,customer_name_snapshot=v_customer.full_name,customer_phone_snapshot=v_customer.phone,notes=p_notes,status=v_status,slot_id=v_slot_id,updated_at=now()
    where id=p_appointment_id and shop_id=p_shop_id returning id into v_appointment_id;
  else
    insert into public.appointments(shop_id,customer_id,created_by,idempotency_key,appointment_date,start_time,duration_minutes,customer_name_snapshot,customer_phone_snapshot,notes,status,slot_id)
    values(p_shop_id,p_customer_id,v_user,gen_random_uuid(),p_appointment_date,p_start_time,p_duration_minutes,v_customer.full_name,v_customer.phone,p_notes,v_status,v_slot_id)
    returning id into v_appointment_id;
  end if;
  if v_slot_id is not null then
    update public.appointment_slots set status='booked',appointment_id=v_appointment_id where id=v_slot_id;
  end if;
  if p_appointment_id is not null and v_appointment.slot_id is not null and v_appointment.slot_id is distinct from v_slot_id then
    update public.appointment_slots set status='available',appointment_id=null where id=v_appointment.slot_id and appointment_id=v_appointment_id;
  end if;
  if v_status in ('cancelled','rejected','no_show') then
    update public.appointment_slots set status='available',appointment_id=null where appointment_id=v_appointment_id;
    update public.appointments set slot_id=null where id=v_appointment_id;
  end if;
  return v_appointment_id;
end;
$$;
revoke all on function public.save_staff_appointment(uuid,uuid,uuid,date,time,integer,text,text) from public;
grant execute on function public.save_staff_appointment(uuid,uuid,uuid,date,time,integer,text,text) to authenticated;

create or replace function public.sync_appointment_slot()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_slot public.appointment_slots%rowtype;
begin
  if tg_op = 'UPDATE' and old.slot_id is not null and old.slot_id is distinct from new.slot_id then
    update public.appointment_slots
       set status = 'available', appointment_id = null
     where id = old.slot_id and appointment_id = old.id;
  end if;

  if new.slot_id is not null then
    select * into v_slot
      from public.appointment_slots
     where id = new.slot_id
     for update;

    if not found
       or v_slot.shop_id <> new.shop_id
       or v_slot.slot_date <> new.appointment_date
       or v_slot.start_time <> new.start_time then
      raise exception 'الوقت المختار غير مطابق لجدول الأوقات المتاحة';
    end if;

    if new.status in ('cancelled','rejected','no_show') then
      update public.appointment_slots
         set status = 'available', appointment_id = null
       where id = new.slot_id and (appointment_id is null or appointment_id = new.id);
    else
      if v_slot.status = 'booked' and v_slot.appointment_id is distinct from new.id then
        raise exception 'هذا الوقت محجوز بالفعل';
      end if;
      update public.appointment_slots
         set status = 'booked', appointment_id = new.id
       where id = new.slot_id;
    end if;
  end if;
  return new;
end;
$function$;

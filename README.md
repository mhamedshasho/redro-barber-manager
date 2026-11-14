# Redro Barber Manager

Cloud-only manager dashboard connected to the dedicated Redro Barber Supabase project.

## Features
- Daily appointment list, customer totals, attendance and queue preview.
- Manager can search existing customer accounts and create or edit appointments.
- Pending requests are visible by selecting the requested date.
- Attendance is recorded as one mutually exclusive value: present or absent.
- Appointment states: pending, confirmed, in service, completed, no-show, cancelled, rejected.
- Printable appointment tickets and daily reports (browser print → Save as PDF).
- Shop name, phone, and secure public logo upload (PNG/JPG/WebP, maximum 2 MB).
- No appointment deletion control or DELETE database privilege.
- Per-action duplicate lock and three-second cooldown, plus unique idempotency key for inserts.

## First manager account
1. Open the Manager app and create an account using email and password.
2. Confirm the email if requested, then sign in.
3. In Supabase Dashboard → Authentication → Users, copy that account's UUID.
4. Run this SQL once in the Supabase SQL Editor, replacing the UUID and display name:

```sql
insert into public.staff_members (user_id, role, display_name)
values ('PASTE-AUTH-USER-UUID-HERE', 'owner', 'Shop Owner')
on conflict (user_id) do update
set role = excluded.role, display_name = excluded.display_name, active = true;
```

Public registrations cannot assign themselves staff access. Provision additional managers/barbers through the same trusted SQL process.

## Deployment
GitHub Actions deploys the repository root to GitHub Pages. In repository Settings → Pages, select GitHub Actions.

## Security
- RLS is enabled on every exposed business table.
- Customers can only access their own profile and appointments.
- Staff membership is provisioned outside the public application.
- No DELETE privilege is granted to authenticated users.
- Queue numbers are calculated by a private database trigger and stored on each appointment; customer RLS exposes only the signed-in customer's own appointment and queue number.
- Only the Supabase publishable key is used in the browser. Never add a service-role or secret key to this repository.

## Cost policy
Use Supabase Free and free GitHub Pages/public-repository Actions allowances only. Do not upgrade or enable paid add-ons. If free quotas are reached, pause usage instead of paying. Free-tier services may pause or become limited when quotas are exceeded.

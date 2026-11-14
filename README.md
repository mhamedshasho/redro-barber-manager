# Redro Barber Manager

Cloud-only, multi-tenant barber shop manager. Each account owns an isolated shop workspace in the shared Supabase project. The barber uses this application to manage customers, appointments, attendance, services, availability, settings and reports. The customer portal is a separate optional Vercel application and is never opened automatically by the manager.

## Features
- Email/password manager sign-in; first sign-in creates the user's own shop workspace automatically.
- Shop-isolated customers, services, appointments, settings, logo, and theme colors.
- Per-shop customer numbers (01, 02, 03...) generated atomically by PostgreSQL.
- Daily appointment dashboard, attendance, queue, search, reports, and printable PDF tickets. Appointments use customer, date, time, duration, status and notes; there is no service catalog.
- Shop settings: name, phone, logo, primary/background/panel/text colors, plus six ready-made themes: Classic, Blue & Gold, Green & Gold, Black & Gold, Ruby & Gold, and Night Violet.
- Optional Vercel customer-booking link that can be copied manually when needed.
- No appointment deletion control or DELETE database privilege.
- Duplicate-action lock, visible three-second cooldown, and unique idempotency key for inserts.

## Applications

Manager: `https://redro-barber-manager.vercel.app/`

Customer portal: `https://redro-barber-client.vercel.app/?shop=SHOP_SLUG`

The manager does not redirect to the customer portal. Customer data used for management stays inside the manager's shop-scoped workspace.

## Authentication setup

The manager uses Supabase email/password authentication. Configure the Supabase authentication provider and the allowed manager URL in the dedicated Redro Supabase project. No service-role key or client secret belongs in this repository.

## Deployment

The manager and customer portal are deployed on Vercel. GitHub Pages is not required for normal use. The customer portal is separate and optional; the manager remains usable without opening it.

## Isolation and security
- Every business row carries a shop_id; RLS restricts access to the current shop and its signed-in customers.
- One account owns one shop. Each shop has its own independent customer-number counter.
- The manager only reads and mutates rows scoped to the signed-in shop.
- No DELETE privilege is granted to authenticated users.
- Only the Supabase publishable key is used in the browser. Never add a service-role or secret key to this repository.

## Performance
- No polling or background refresh loops beyond the existing appointment update channel.
- Manager loads the dashboard's essential shop, customer, and selected-day appointment data first.
- Services and availability slots load only when the appointment/settings workflows need them.
- Database indexes support shop/date, customer, service and queue lookups.

## Free-only rule
Use Supabase Free and Vercel's existing free deployment allowances only. Do not upgrade or enable paid add-ons. If free quotas are reached, pause usage instead of paying.

### Settings and chair capacity

The settings center is organized into category buttons. Work start/end use Arabic 12-hour selectors and support overnight hours. Run `add_chair_count.sql` once in Supabase to persist each shop's chair capacity; the UI safely falls back to three chairs until the column exists.

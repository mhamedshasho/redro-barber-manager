# Redro Barber Manager

Cloud-only, multi-tenant barber shop manager. Each account owns an isolated shop workspace in the shared Supabase project. The current product mode is **manager-only**: the barber manages customers, appointments, attendance, services, availability, settings and reports from this application without opening the customer portal.

## Features
- Email/password manager sign-in; first sign-in creates the user's own shop workspace automatically.
- Shop-isolated customers, services, appointments, settings, logo, and theme colors.
- Per-shop customer numbers (01, 02, 03...) generated atomically by PostgreSQL.
- Daily appointment dashboard, attendance, queue, search, reports, and printable PDF tickets.
- Shop settings: name, phone, logo, primary/background/panel/text colors.
- No customer-portal redirect or customer-app dependency in the manager UI.
- Service catalog: add services, set duration/optional price, activate/deactivate.
- No appointment deletion control or DELETE database privilege.
- Duplicate-action lock, visible three-second cooldown, and unique idempotency key for inserts.

## Authentication setup

The manager uses Supabase email/password authentication. Configure the Supabase authentication provider and the allowed manager URL in the dedicated Redro Supabase project. No service-role key or client secret belongs in this repository.

## Deployment

GitHub Actions deploys the repository root to GitHub Pages. In repository Settings → Pages, select **GitHub Actions**. The customer portal repository is separate and is not required to operate this manager-only application.

## Isolation and security
- Every business row carries a shop_id; RLS restricts access to the current shop and its signed-in customers.
- One account owns one shop. Each shop has its own independent customer-number counter.
- The manager only reads and mutates rows scoped to the signed-in shop.
- No DELETE privilege is granted to authenticated users.
- Only the Supabase publishable key is used in the browser. Never add a service-role or secret key to this repository.

## Performance
- No realtime subscriptions, polling, or background refresh loops beyond the existing appointment update channel.
- Manager loads the dashboard's essential shop, customer, and selected-day appointment data first.
- Services and availability slots load only when the appointment/settings workflows need them.
- Database indexes support shop/date, customer, service and queue lookups.

## Free-only rule
Use Supabase Free and GitHub free public-repository/Pages allowances only. Do not upgrade or enable paid add-ons. If free quotas are reached, pause usage instead of paying.

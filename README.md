# Redro Barber Manager

Cloud-only, multi-tenant barber shop manager. Each Google account owns an isolated shop workspace in the shared Supabase project.

## Features
- Google sign-in; first sign-in creates the user's own shop workspace automatically.
- Shop-isolated customers, services, appointments, settings, logo, and theme colors.
- Per-shop customer numbers (01, 02, 03...) generated atomically by PostgreSQL.
- Daily appointment dashboard, attendance, queue, search, reports, and printable PDF tickets.
- Shop settings: name, phone, logo, primary/background/panel/text colors.
- Customer booking link generated for the current shop.
- Service catalog: add services, set duration/optional price, activate/deactivate.
- No appointment deletion control or DELETE database privilege.
- Duplicate-action lock, three-second cooldown, and unique idempotency key for inserts.

## Google OAuth setup (one time)
1. In Google Cloud Console, create an OAuth Client ID for a Web application.
2. Add this authorized redirect URI:
   `https://kqllombatzcpxjyltrsn.supabase.co/auth/v1/callback`
3. In Supabase Dashboard → Authentication → Sign In / Providers → Google, enable Google and enter the Google Client ID and Client Secret.
4. In Supabase Dashboard → Authentication → URL Configuration, add this redirect URL:
   `https://mhamedshasho.github.io/**`
5. Publish both repositories with GitHub Pages. Sign in with Google in Manager; the shop is created automatically.

Google OAuth requires your own free Google OAuth credentials. The app does not contain a client secret.

## Deployment
GitHub Actions deploys the repository root to GitHub Pages. In repository Settings → Pages, select GitHub Actions.

## Isolation and security
- Every business row carries a shop_id; RLS restricts access to the current shop and its signed-in customers.
- One Google account can own one shop. Each shop has its own independent customer-number counter.
- Customers can only read/update their own profile and appointments.
- The public shop lookup exposes only the shop name, phone, logo and theme needed by its booking page.
- Queue lookup verifies appointment ownership before returning queue position.
- No DELETE privilege is granted to authenticated users.
- Only the Supabase publishable key is used in the browser. Never add a service-role or secret key to this repository.

## Performance
- No realtime subscriptions, polling, or background refresh loops.
- Manager loads only the selected day's appointments, with bounded result sets.
- Customer, service, settings, and appointment data are refreshed separately after relevant actions.
- Database indexes support shop/date, customer, service and queue lookups.

## Free-only rule
Use Supabase Free and GitHub free public-repository/Pages allowances only. Do not upgrade or enable paid add-ons. If free quotas are reached, pause usage instead of paying. Free-tier services may pause or become limited when quotas are exceeded.

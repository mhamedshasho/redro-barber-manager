# Redro Barber Manager

Cloud-only, multi-tenant barber shop manager. Each account owns an isolated shop workspace in the dedicated Redro Barber Supabase project. The manager handles customers, appointments, attendance, queue, services, availability, settings and reports. The customer portal is a separate Vercel application.

## Features

- Manager sign-in with email and password.
- First successful sign-in creates or restores the account's shop workspace through `ensure_my_shop`.
- Shop-scoped customers, services, appointments, settings, logo and theme colors.
- Per-shop customer numbers allocated by PostgreSQL.
- Daily dashboard, attendance, queue, search, reports and printable views.
- Shop settings include name, phone, logo, theme colors, working hours, weekly day off and chair capacity.
- Individual appointment slots are managed by the barber; customers can request available slots through the separate client portal.
- Appointment status and service details are managed by the barber.
- Duplicate-action locks and cooldown feedback help prevent repeated submissions.
- No direct appointment deletion interface or general authenticated DELETE access is provided.
- The workspace owner has a separate explicit `delete_my_workspace` RPC. It deletes that owner's workspace data after confirmation in the manager UI.

## Applications

Manager: https://redro-barber-manager.vercel.app/

Customer portal: https://redro-barber-client.vercel.app/?shop=SHOP_SLUG

The manager does not redirect to the customer portal. The customer portal is optional and separate.

## Authentication

The manager uses Supabase email/password authentication. The client portal uses a separate customer-number and registered-phone verification flow with Supabase Anonymous Sign-ins. Manager and customer authentication flows are not interchangeable.

Use only the dedicated Redro Barber Supabase project. The browser client uses a publishable key; never place a service-role or secret key in this repository.

## Database security

- Public business tables have Row Level Security enabled.
- Shop data access is scoped by shop membership and customer ownership.
- Customer-facing RPCs validate the authenticated user and the relevant shop/customer relationship.
- Public shop lookup returns only the fields needed to render a booking page.
- Trigger functions are not intended to be callable as public RPC endpoints.
- Anonymous customer sessions use the Postgres `authenticated` role; policies must therefore enforce customer ownership and shop scope rather than relying on the role name alone.

Database policies and RPC definitions are maintained in the dedicated Redro Barber Supabase project. Client-side checks are not a substitute for RLS.

## Deployment

Both applications are deployed on Vercel:

- Manager: https://redro-barber-manager.vercel.app/
- Client: https://redro-barber-client.vercel.app/

GitHub Pages is not required for normal deployment.

## Performance and cost

The applications are cloud-only and require an internet connection. The manager loads shop and selected-day data as needed; customer booking availability is loaded on demand. Use the existing free-tier allowances only. Do not enable paid services or upgrade plans without the owner's explicit decision.



## Appointment save integrity

Appointment creation and editing use the `save_staff_appointment` database RPC. The transaction validates staff membership, customer ownership, working hours, weekly day off, appointment overlap, and slot availability, then updates the appointment and its slot together. The customer booking RPC performs the same server-side schedule and overlap checks. The browser prevents selecting elapsed times for today.

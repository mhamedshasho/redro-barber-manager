# Redro Barber Manager outcomes

## 1. Preserve the existing product and visual identity
- Keep the existing Redro Barber Manager application rather than rebuilding it from scratch.
- Preserve existing features, business rules, database relationships, authentication, customer privacy rules, and the red, black, and dark visual identity.
- Keep the application responsive on mobile and desktop, with clear navigation, compact spacing, readable typography, usable buttons/forms/cards/tables, and subtle animations that do not hurt performance.
- Improve loading, empty, error, and success states without introducing mock data, fake functionality, paid services, or unapproved dependencies.

## 2. Make manager operations reliable and tenant-safe
- Audit and correct appointment creation, editing, cancellation/approval/rejection, and attendance handling while keeping all operations scoped to the signed-in shop.
- Validate appointment, customer, service, schedule, and settings inputs in the client as well as through existing database protections.
- Prevent duplicate submissions and accidental repeated actions, and prevent conflicting appointment-slot use.
- Preserve customer IDs and shop isolation; never touch Aleppo Center Cash or its Supabase database.

## 3. Reduce unnecessary work without sacrificing consistency
- Keep data requests bounded to the selected shop/day and avoid duplicate or redundant requests.
- Do not add polling, paid services, service-role credentials, or local business-data fallbacks.
- Retain appropriate loading/disabled states and refresh only the affected data after mutations.

## 4. Validate and report the change
- Inspect the entire existing codebase before editing.
- Run JavaScript/HTML static validation, inspect the final diff, and test the important client-side workflows that can be verified without production credentials.
- Record any tests that cannot be performed because authenticated accounts, Supabase provider setup, or test data are unavailable.
- Deliver a clear summary of modifications, tests, remaining issues, and performance/security findings.

# Redro Barber Manager change report

## Changes made

The existing single-page manager was preserved. The orphaned customer-form fragment was removed, and the booking link now targets the client repository's published GitHub Pages URL: `https://mhamedshasho.github.io/redro-barber-client/?shop=...`.

Appointment state now carries `slot_id`, validates the selected date, time, and duration at submit time, requires an active service, scopes appointment updates to the current shop, and releases the previous slot after a successful move when the database permits that update. Customer creation now validates name and phone length before inserting. Attendance changes now validate the allowed values and include an explicit `shop_id` predicate. Settings saves now validate time, weekly-day, and color values before mutation.

The existing dark red/black RTL interface, mobile navigation, Supabase client, RLS model, and no-delete/no-paid-service policy were retained. No Aleppo Center Cash code or database was accessed or modified.

## Validation performed

- Parsed `index.html` with Python's HTML parser successfully.
- Extracted the inline module and passed `node --check`.
- Confirmed no duplicate HTML IDs.
- Confirmed the stale Vercel client URL is absent and the GitHub Pages client URL is present.
- Ran `git diff --check` successfully.
- Confirmed manager and client reference the same dedicated Supabase project URL and only the publishable browser key is present.
- Reviewed the final diff and repository workflows.

## Not performed

Authenticated Supabase workflows, RLS behavior, database triggers/functions, real appointment concurrency, Google/email provider configuration, live customer data preservation, and mobile/desktop browser rendering could not be exercised safely without a test account and explicit test data. No production writes were made.

## Remaining issues and recommendations

The current static client still relies on database-side behavior for atomic slot reservation and move/release consistency. A server-side transactional RPC or equivalent database function should be reviewed before claiming full concurrency safety. The README describes Google OAuth while the current manager source presents email/password auth; this is a pre-existing documentation/configuration mismatch that should be reconciled deliberately rather than changing authentication during this UI/logic pass. The stylesheet also contains overlapping responsive overrides; consolidating them should be done alongside visual regression testing.

## Arabic-first usability pass

The visible manager language is now Arabic-first: English section labels, ID terminology, cloud status wording, report labels, and action text were replaced with clear Arabic wording while keeping the Redro brand name. A quick-use guide was added to the dashboard explaining the order of work: add an available time, add the customer, then create the appointment. The appointment dialog now explains what to fill in before saving, and close controls have accessible labels/tooltips.

The visual layer now includes a calmer instructional banner, stronger focus states, clearer hover/press feedback, gentle card lift and modal entrance animations, a subtle action shimmer, and reduced-motion fallbacks. No business logic or database schema was changed in this visual pass.

## Login speed and anti-double-submit pass

Successful email/password authentication now passes the session returned by Supabase directly into the workspace-loading path instead of immediately calling `getSession()` a second time. This removes one redundant authentication round trip from login.

All mutation buttons using the shared action guard now show `جارٍ التنفيذ…` while the request is active, then remain disabled for a visible three-second countdown (`انتظر 3 ثوانٍ` down to `انتظر 1 ثوانٍ`) before becoming available again. Duplicate presses are ignored with a clear Arabic message, while the existing per-action lock remains in place.

## Data-loading performance pass

The initial manager load now requests only the data required to show the dashboard: shop settings, customers, and the selected day's appointments. Services and appointment slots are no longer requested during login/dashboard startup; they load only when the user opens the appointment form or enters shop settings. This reduces the initial request set from five data loads to three and prevents secondary settings data from delaying the first useful view.

## Manager-only mode and 404 diagnosis

The manager does not open the customer portal automatically. It shows an optional Vercel booking link that the barber may copy manually when needed; the manager remains usable without opening the customer application.

A direct HTTP check confirmed that the Vercel hostnames redro-barber-manager.vercel.app and redro-barber-client.vercel.app respond successfully, while the GitHub Pages URLs return 404. The applications are therefore documented and linked through Vercel; GitHub Pages is not required for normal use.

## Vercel deployment correction

The previous GitHub Pages diagnosis was based on the wrong deployment target. The confirmed live hosts are `https://redro-barber-manager.vercel.app/` and `https://redro-barber-client.vercel.app/`. The manager now points to the client Vercel host only for an optional manually copied booking link and never redirects the barber into the client application.

## Faster initial barber-data loading

The dashboard no longer loads the full customer directory during login. It now loads only shop settings and the selected day's appointments; appointment customer snapshots supply the names and phone details needed for the dashboard, queue, reports, and ticket printing. The full customer directory loads only when the customer section or a new/edit appointment workflow needs it. This reduces the initial data request set again while keeping customer records out of local storage.

## Customer-specific Vercel links

The manager now provides a `نسخ رابط الدخول` action in the customer directory. It creates a Vercel URL containing the shop slug and that customer's number, so the customer app can load the correct shop and prefill the customer number. The phone is intentionally not placed in the URL because it is the customer's login secret and would be exposed in browser history, copied messages, and referrer logs; the customer enters it on the login screen.

## Theme presets

The manager settings now include six ready-made visual themes: Redro Classic, Royal Blue & Gold, Emerald & Gold, Black & Gold, Ruby & Gold, and Night Violet. Selecting a preset updates the manager immediately; saving persists the four theme colors already stored for the shop. The customer app reads those same saved colors from `shop_settings`, so the selected appearance carries over to the customer experience without a schema change.

## Manager visual cleanup

The manager now has a theme-aware visual layer that overrides the older fixed-color rules: panels, sidebar, navigation, modals, tables, inputs, connection status, and primary buttons follow the selected shop theme. Focus states, hover/press feedback, mobile navigation surfaces, backdrop blur, and reduced-motion handling were also normalized so the manager and customer app share a cleaner interaction language.

## Full mobile-first manager UI rebuild

The accumulated legacy manager stylesheet was removed and replaced with one coherent mobile-first design system. The rebuilt shell uses a compact sticky header, touch-sized controls, responsive two-column cards, a bottom mobile navigation launcher with a clean navigation sheet, mobile bottom-sheet modals, horizontal table scrolling, theme-driven surfaces, and consistent focus/press states. Existing HTML IDs, Supabase logic, appointments, reports and settings behavior were preserved so the rebuild changes the experience without changing business data or booking rules.

## Removed service catalog

The unused service feature was removed from the manager UI and booking form. Appointment creation now uses customer, date, time, duration, status and notes only. Existing appointment rows and service columns in the database were not deleted or migrated; historical data remains intact, but the manager no longer loads, edits, displays or inserts service records.


## Availability rules

The manager's optional weekly day-off remains configurable for any day from Monday through Sunday. The manager prevents adding slots on that day or outside the configured opening interval. The customer app now loads the same day-off and opening/closing settings, hides slots outside the interval, hides elapsed slots for today, and disables the booking button until a valid future slot exists.

## Coordinated UI refinement

Added a shared visual refinement layer for the manager: clearer hierarchy, stronger touch targets, calmer toolbar treatment, improved mobile action placement, and more consistent focus and card states.

## Top-corner navigation

On mobile, the navigation launcher was moved from the bottom edge to the top corner so it cannot cover save, cancel, or other form actions. Arabic RTL places it at the upper right; the CSS automatically places it at the upper left when the document switches to LTR English. The menu sheet now opens below the launcher.


## Automatic availability generation

The manager no longer requires entering every available time manually. For a selected date, the barber chooses a 30-minute or 60-minute interval and the system generates slots automatically from the configured opening time up to, but not including, the closing time. It skips the weekly day off, rejects past dates, avoids duplicate slots, and the customer app reads the generated slots with the same work-hour/day-off filters.

## Overnight opening hours

Opening hours now support crossing midnight. For example, 12:00 to 01:00 generates slots from 12:00 through 00:30 and stops before 01:00. The customer app applies the same rule and explicitly rejects a stale or invalid booking with a message that the shop is closed at that time.

## Removed visible available-times feature

The manager no longer shows or manages an available-times list. The barber sets only opening time, closing time and weekly day off. Manager-created appointments validate the requested time directly against that range and reject conflicts.

## Whole-hour booking and registration fix

Appointments are now restricted to whole hours only, such as 1:00, 2:00, and 3:00. Hidden conflict-protection records are generated by the authenticated manager for the next 60 days; the customer app never creates them, preventing the previous registration failure.

## Arabic 12-hour time controls

Appointment forms now show hours 1–12 with صباحاً/مساءً and quarter-hour minutes 00, 15, 30 and 45. Users no longer see 13, 16, 21 or 23; the app converts the selected display time to the server's internal 24-hour value.

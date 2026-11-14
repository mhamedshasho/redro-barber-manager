# Redro Barber Manager

A mobile-first barber appointment and queue management frontend prototype.

## Current stage

- Frontend prototype only.
- Uses temporary in-memory demo data for interface testing.
- No local persistence, Local Mode, IndexedDB, or browser storage.
- No Supabase connection yet.
- No customer accounts or real appointment submissions yet.
- The final application is Cloud Only and requires an internet connection.

## Included in this prototype

- Daily appointment dashboard and customer counts.
- Customer directory with automatically assigned demo IDs.
- Appointment creation and editing.
- Attendance controls (Present / Absent).
- Queue preview and appointment status.
- Shop name, phone, and logo preview settings.
- Printable appointment ticket and daily report (Save as PDF through the browser print dialog).
- Duplicate-action guard with a three-second cooldown.
- No delete action.

## Deployment

GitHub Actions deploys the static frontend to GitHub Pages on pushes to `main`.

## Planned next stages

1. Review and refine the Manager UI.
2. Build the Client frontend prototype.
3. Create a separate Redro Barber Supabase project and implement authentication, database, and row-level security.
4. Connect both apps to the same Redro Barber backend.
5. Build and test Android APK packages.

# Redro Barber Manager enhancement plan

## Scope
Improve the existing single-page Redro Barber Manager without rebuilding it, removing features, changing its authentication model, or touching any other application/database. The manager and client both use the dedicated Redro Supabase project already present in the source.

## Implementation approach
- Preserve the existing Arabic RTL single-page structure, Supabase client, RLS boundaries, and GitHub Pages deployment.
- Correct concrete reliability issues in the existing appointment, slot, customer, and booking-link flows.
- Keep the current mobile-first navigation and dark red/black visual identity, while improving accessible labels, responsive controls, empty/error feedback, and small interaction details.
- Keep initial data bounded to the selected shop/day and avoid adding polling or paid dependencies.
- Validate the inline module with Node syntax checks and run repository-level static checks before committing.

## Main areas
- Appointment integrity: validate inputs at submit time, carry slot IDs through state, reject invalid/past appointments, and release a previously booked slot when an appointment is moved successfully.
- Customer integrity: validate name and phone in both create and edit flows and preserve customer numbers.
- Booking link correctness: use the deployed client repository's GitHub Pages URL rather than a stale alternate host.
- UI cleanup: remove orphaned duplicate modal markup, add clearer accessibility labels and responsive feedback without changing existing workflows.

## Project structure
- `index.html`: the complete RTL manager UI, styles, Supabase client, state, rendering, and event handlers.
- `README.md`: authentication, isolation, performance, and deployment notes.
- `.github/workflows/`: syntax validation and GitHub Pages deployment.

## Design direction
Three possible directions: **Midnight atelier** (0.06), **Crimson command center** (0.07), **Quiet industrial ledger** (0.08). Chosen: **Midnight atelier**.

- **Design Movement:** premium barbershop atelier translated into a focused operations console.
- **Core Principles:** strong hierarchy, dark calm surfaces, red only for decisions, dense information with breathing room.
- **Color Philosophy:** near-black backgrounds reduce fatigue; warm red marks action and brand; muted green/amber/blue distinguish operational states.
- **Layout Paradigm:** a persistent command rail on desktop and compact bottom command bar on mobile, with task-focused panels rather than a centered marketing grid.
- **Signature Elements:** clipped red accent on active navigation, compact status pills, and queue cards with progress rails.
- **Interaction Philosophy:** every mutation is explicit, disabled while running, and followed by a concise Arabic confirmation or error.
- **Animation:** short translate/fade transitions only; honor `prefers-reduced-motion`.
- **Typography System:** preserve the existing Tahoma/Segoe UI Arabic-safe stack; use weight and size contrast instead of adding dependencies.
- **Brand Essence:** a dependable cloud workspace for barbers who need the day's queue and customer context at a glance; precise, calm, practical.
- **Brand Voice:** direct operational Arabic. Example: “احفظ الموعد بعد التحقق من الوقت.” / “تم تحديث الحضور.”
- **Wordmark & Logo:** preserve the scissors mark and Redro wordmark; do not introduce a new asset dependency.
- **Signature Brand Color:** Redro crimson `#e52d38`.

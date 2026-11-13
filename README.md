# ShiftDesk Staff

A Flutter shift-booking app built with GetX and a simple presentation/domain/data structure.

## Run

1. Install Flutter 3.x and Android Studio.
2. Run `flutter pub get`.
3. Run `flutter run`.

Check your installed version with `flutter --version`.

## Architecture

- `features/`: screens and GetX controllers.
- `domain/`: models, repository contract and pure Dart claim rules.
- `data/`: fake API and repository implementation.
- `core/`: shared errors, date helpers and session storage.
- `app/`: routing, dependency injection and theme setup.

GetX is used for dependency injection, routing and reactive app state. Local widget state is kept inside widgets where appropriate.

## Seeded users

- Alex Morgan – Doctor, active, long-valid licence.
- Sam Taylor – Nurse, active, licence expiry within the next month.
- Jamie Lee – Technician, deactivated.

## Developer settings

Open the overflow menu on the Open Shifts screen and select Developer settings.

- Flaky network: approximately 1 in 5 API calls return 503.
- Busy hospital: approximately 1 in 3 claim attempts return 409.

## Tests

Run `flutter test`.

The claim-rule unit tests cover role, active status, capacity, overlap/back-to-back, duplicates and weekly hours. A basic widget smoke test is included.

## Current implementation and trade-offs

Implemented: staff picker and persisted selection, open shifts with 20-item cursor paging, department filter, refresh, loading/error/retry states, shift details, claim validation in UI and fake API, My Shifts, cancellation, developer toggles, tests and Part 2 reference fixes.

Not fully implemented: date-range filtering UI, true offline cache, cancel-within-24-hours bonus, optimistic claiming, overnight-shift-specific grouping, production HTTP integration and exhaustive Part 2 regression tests. The provided `part2/debug` files are reference fixes based on the candidate brief snippets; adapt their model/import paths to the actual Part 2 starter repository.

Assumption: the fake API data and bookings live in memory and reset when the app process restarts. Only the selected staff ID is persisted, as requested.

## AI usage

See `AI_USAGE.md`.

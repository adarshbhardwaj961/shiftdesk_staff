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

The claim-rule tests cover future start times, role, active status, licence expiry, capacity, overlap/back-to-back, duplicate bookings, and the 48-hour weekly limit. Fake API tests cover claim-rule enforcement and cursor behavior. Shift-controller regression tests cover pagination deduplication, department/date filter resets, stale requests, retry behavior after 503 errors, 409 claim conflicts, loading/error state, and disposal. Widget smoke tests cover app launch.

## Current implementation and trade-offs

Implemented: staff picker and persisted selection, 20-item keyset cursor paging over 5,000 seeded shifts, department and date-range filters, refresh, loading/error/retry states, shift details, claim validation in UI and fake API, My Shifts, cancellation, developer toggles, and regression tests.

Not implemented: true offline cache, optimistic claiming, overnight-shift-specific grouping, production HTTP integration, or cancellation restrictions. Cancellation intentionally remains available at any time because no 24-hour cancellation policy was specified. The provided `part2/debug` files are reference examples based on candidate-brief snippets; they are not integrated into the app and may need adaptation to another Part 2 starter repository.

Assumption: the fake API data and bookings live in memory and reset when the app process restarts. Only the selected staff ID is persisted, as requested.

## AI usage

See `AI_USAGE.md`.

## lib/ folder structure

lib/
│
├── main.dart
│   # Entry point of the Flutter application.
│   # The app starts executing from this file.
│
├── app/
│   # Contains global app configuration.
│   # Includes routes, navigation, and dependency bindings.
│
├── core/
│   # Contains common functionality used across the app.
│   # Includes constants, helpers, utilities, and shared services.
│
├── features/
│   # Contains separate application features.
│
│   └── developer/
│       # Contains developer tools and testing functionality.
│
│       ├── controllers/
│       │   # Contains GetX controllers and feature business logic.
│       │
│       └── presentation/
│           # Contains UI screens and widgets.
│
├── data/
│   # Handles data operations, repositories, and API integration.
│
└── models/
# Defines data models and their properties.

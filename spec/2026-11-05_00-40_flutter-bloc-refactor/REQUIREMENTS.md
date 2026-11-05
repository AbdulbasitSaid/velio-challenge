# Requirements: Flutter app refactor from Riverpod to flutter_bloc

- **Spec ID:** 2026-11-05_00-40_flutter-bloc-refactor
- **Source:** owner request, 2026-11-05: "swap riverpod with flutter bloc; strictly use the official flutter_bloc architecture; no use of private classes for widgets; no business logic in UI". Behavior requirements come from S7 and S7b, which this spec does not change.

## 1. Purpose and scope

Restructure `apps/mobile` onto `flutter_bloc` with the official layered architecture, with no change to what users see or to how the app talks to the API.

## 2. Goals and non-goals

**Goals:** Riverpod removed; four layers (data providers, repositories, blocs, presentation) with one-way dependencies; all business logic in blocs; public widget classes; every bloc tested.

**Non-goals:** new features, visual changes, copy changes, API or contract changes, changes to `packages/api-client-dart` or `packages/design-tokens`, router replacement, CI changes.

## 3. Functional requirements

- **FR-001** `flutter_riverpod` is removed from `pubspec.yaml` and `pubspec.lock`, and no file under `lib/`, `test/` or `integration_test/` imports `riverpod`.
- **FR-002** State management uses `flutter_bloc` / `bloc` at the latest stable versions, pinned exactly (CLAUDE.md "Versions").
- **FR-003** The code is organised in the four layers of PLANNING §4.1. Data providers do not import repositories, blocs or widgets. Repositories do not import blocs or widgets. Blocs depend only on repositories and value types passed in their constructors.
- **FR-004** Repositories are provided once at the app root with `RepositoryProvider` / `MultiRepositoryProvider`; app-wide blocs and cubits with `BlocProvider` / `MultiBlocProvider` above the router.
- **FR-005** Each screen's page widget creates its bloc with `BlocProvider(create: …)` and the bloc is closed when the route is removed.
- **FR-006** Bloc files, classes, events and states follow the bloc naming conventions: `<feature>_bloc.dart` with `part` files for events and states; events named in the past tense for what happened (`…Pressed`, `…Submitted`, `…Changed`, `…Requested`); states extend `Equatable`.
- **FR-007** Files follow the feature-first layout of PLANNING §4.3 (`bloc/`, `view/`, `widgets/` per feature, shared widgets in `ui/`).
- **FR-008** Business logic lives in blocs or below them, never in widgets. In particular, no widget calls a repository or data provider, catches `ApiException`, maps outcomes, reads or writes idempotency keys, reads the cache, starts a business timer, applies the live-spots version gate, validates a form, builds a PATCH or decides an optimistic revert. (Bloc closes, the page's initial event, and UI-owned controllers are allowed.)
- **FR-009** Widgets render state and dispatch events. Side effects (navigation after a result, haptics, snack bars, screen-reader announcements, share sheet, URL launch) run only in `BlocListener` callbacks or in direct response to a user's tap that needs no decision.
- **FR-010** No `Widget` subclass is private (no class whose name starts with `_` extends `StatelessWidget`, `StatefulWidget` or another `Widget`). Private widget-building methods are replaced by public widget classes. Scope for `State`, painters and formatters per PLANNING §12 Q-3.
- **FR-011** `sessionVersionProvider` is replaced by a session stream on `SessionRepository` and a `SessionBloc`. Signing in or out, or a 401 from the API, still reloads screens that depend on who is signed in, and still reconnects the socket with the new token (CHANGELOG entry for S7b socket auth).
- **FR-012** `roleProvider` is replaced by a `RoleCubit`. The role is still loaded before the first frame, persisted to `velio.role`, and still decides the initial location (`/host` or `/`) (S7b FR-001).
- **FR-013** `onlineProvider` is replaced by a `ConnectivityCubit` fed by `ConnectivityRepository`. Connectivity stays a hint only (S7 §4.8).
- **FR-014** `LiveSpots` and `LiveCounts` no longer extend `ChangeNotifier` or import Flutter widgets. Live updates reach blocs as streams; realtime rules 1–6 (subscribe then fetch, ignore older versions, refetch on resync, poll every 10 s while disconnected, refetch on Plan and attendance hints, ack each painted version) still hold.
- **FR-015** The polite spots announcement (at most once every 5 s, UX NFR-003) and render acks still happen, from presentation widgets driven by state.
- **FR-016** Each attempt to Book, Claim, Publish or Save is handled once: a second tap while one is in flight is ignored (`droppable`), and the idempotency key is reused on retry and cleared on a final outcome exactly as now (S7 claim, S7b FR-005).
- **FR-017** Haptics fire on the same transitions as now: medium on book or claim success, heavy on sold out (page lands on sold out, or sold out on attempt) (PRD M3).
- **FR-018** The open beacon is still sent once per invite screen, after its first frame (S7 FR-009).
- **FR-019** `main.run()` keeps a test seam for the photo picker and any other platform service the integration tests replace, without Riverpod `overrides`.
- **FR-020** Every screen and state in S7 and S7b renders as before: the same widgets, text, semantics and routes.

## 4. Non-functional requirements

- **NFR-001** `dart format --set-exit-if-changed` (page width 120) and `flutter analyze` report no issues.
- **NFR-002** Every existing test case (63 at spec time) still runs and passes with the same assertions; only setup and imports change. A test is removed only if its subject is deleted, and that is recorded in VALIDATION Part B.
- **NFR-003** Every bloc and cubit has a `bloc_test` suite covering each event handler's success and failure paths.
- **NFR-004** Live-spot ticks do not rebuild a whole screen: views use `BlocSelector` or `buildWhen` for the spots badge.
- **NFR-005** No new runtime dependencies beyond `flutter_bloc`, `bloc`, `equatable` and `bloc_concurrency`; dev only `bloc_test` and `mocktail`.

## 5. Use cases

Unchanged from S7 and S7b: a guest enters a code and claims; a booker browses, books and invites; a host creates, edits and runs attendance.

## 6. Acceptance criteria

- **AC-001** No `riverpod` match in `apps/mobile/lib`, `test`, `integration_test`, `pubspec.yaml` or `pubspec.lock`.
- **AC-002** No match for a private `Widget` subclass declaration in `apps/mobile/lib` (grep in VALIDATION).
- ~~**AC-003** No file under `lib/*/view/`, `lib/*/widgets/` or `lib/ui/` imports `data/` or `repositories/`, or references `Api`, `OfflineCache`, `RealtimeClient`, `Identity`, `AttemptKeys` or `ApiException`.~~ Superseded by AC-009 (2026-11-05): the official page pattern reads repositories in `BlocProvider.create`.
- **AC-009** No file under `lib/*/widgets/` or `lib/ui/` imports `data/` or `repositories/`. Under `lib/*/view/`, repositories are read only to construct blocs in `BlocProvider(create: …)` (the official page pattern); no view calls a repository method or references `Api`, `OfflineCache`, `RealtimeClient`, `Identity`, `AttemptKeys` or `ApiException`.
- **AC-004** No file under `lib/*/bloc/` or `lib/repositories/` imports `package:flutter/material.dart`, `widgets.dart`, `services.dart`, `go_router` or `share_plus`.
- **AC-005** `flutter analyze` clean, `dart format` clean, `flutter test` all green, including every pre-existing test case.
- **AC-006** Each bloc has a test file with `blocTest` cases for every event.
- **AC-007** On the iOS simulator against the local API, `integration_test/smoke_test.dart` and `parity_test.dart` pass.
- **AC-008** Manual pass on the simulator: code entry → invite → claim → You're in; Explore → activity → Book; switch to Host → create with a photo → attendance shows a second person's booking live → remove. Behavior matches the pre-refactor app.

## 7. Business rules and edge cases

All S7 and S7b rules carry over unchanged. Those most at risk in a rewrite, each with an explicit bloc test:

- Booking and claim outcomes (`signIn`, `refresh`, `soldOut`, `started`, `paused`, `error`) and which ones clear the idempotency key.
- The invite screen falls back to the cached invite with "Last updated …" when offline; Claim never queues.
- Members are refetched after a random 0–2 s delay after a spots change; a newer change replaces the pending one.
- Attendance flips from Remove to Attended / No-show at the start time; marks are optimistic and revert with the web's messages on failure.
- The activity form validates on submit, sends only changed fields, locks date and location after the first booking, and maps `location_locked` and `capacity_below_bookings` to fields.
- Places search is debounced and only the latest request's result is shown.

## 8. Error handling and failure behavior

Unchanged. `ApiException` mapping moves from `State` classes into blocs and repositories; each screen's failure states (not found, offline with retry, server error with retry, 401 → sign in) remain.

## 9. Security and privacy

- **SEC-001** No `BlocObserver` logs events or states in release builds, and none logs contacts, codes or tokens in any build (CLAUDE.md telemetry rule).
- **SEC-002** Session token and device ID remain in platform secure storage; only the masked contact is kept in state (S7).
- **SEC-003** Deep-link handling (only `/i/<code>` with a valid code opens in the app) is unchanged (S7 SEC-005).

## 10. Performance and reliability

NFR-004. The realtime socket remains one per app, owned by `LiveRepository`; per-screen blocs add and remove watches only.

## 11. Compatibility constraints

Flutter 3.47.9, Dart `^3.13.7`, `go_router` 18.1.3 and all other current pins unchanged. iOS and Android as before.

## 12. Data and migration

No data migration. Shared-preferences keys (`velio.role`, `velio.claim_key.*`, `velio.book_key.*`, cache keys) and secure-storage keys are unchanged, so an installed app upgrades in place.

## 13. Dependencies and integrations

`flutter_bloc`, `bloc`, `equatable`, `bloc_concurrency`, `bloc_test`, `mocktail` (versions in PLANNING §2, re-checked at implementation). No API changes.

## 14. Explicitly excluded

Changing the router, the design system, the generated API client, the API, CI, or any user-visible behavior. Adding `bloc_lint` / `bloc_tools` (pre-release CLI).

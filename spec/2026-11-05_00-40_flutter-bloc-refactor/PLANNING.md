# Planning: Flutter app refactor from Riverpod to flutter_bloc

- **Spec ID:** 2026-11-05_00-40_flutter-bloc-refactor
- **Created:** 2026-11-05 00:40 (local)
- **Status:** Implemented (2026-11-05; approved for implementation by the owner, 2026-11-05: "Approve and implement")
- **Parents:** `spec/2026-11-04_12-50_s7-flutter-app/` and `spec/2026-11-04_23-59_s7b-flutter-web-parity/` (both Implemented). This spec changes how the app is built, not what it does.

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

The owner asked on 2026-11-05 to refactor `apps/mobile` so that:

1. Riverpod is replaced by `flutter_bloc`.
2. The app follows the official bloc architecture strictly (bloclibrary.dev: data, repository, business logic and presentation layers, plus its naming conventions).
3. No widget class is private.
4. The UI holds no business logic.

## 2. Context and current behavior

- [Verified, `apps/mobile/pubspec.yaml`] `flutter_riverpod: 3.4.3`, `go_router: 18.1.3`, Flutter 3.47.9, Dart `^3.13.7`. `flutter_lints` 6.0.0 with page width 120.
- [Verified, `lib/core/providers.dart`, `online.dart`, `role.dart`, `features/claim.dart`] 15 providers. Most are used as dependency injection (`identityProvider`, `apiProvider`, `cacheProvider`, `realtimeProvider`, `platformProvider`, `clockProvider`, `mapsEnabledProvider`, `prefsProvider`, `placesProvider`, `photoUploaderProvider`, `photoPickerProvider`, `attemptKeysProvider`). Three hold state: `roleProvider` and `sessionVersionProvider` (legacy `StateProvider`) and `onlineProvider` (`StreamProvider`).
- [Verified, `lib/main.dart`] `run()` builds a `ProviderContainer`, overrides the services with loaded instances, and listens to `sessionVersionProvider` to reconnect the socket. Integration tests pass `overrides` (for example, a fake photo picker).
- [Verified, `lib/features/*.dart`] Every screen is a `ConsumerStatefulWidget` whose `State` holds the business logic: API calls, `ApiException` mapping, idempotency keys, booking and claim outcomes, live spot subscriptions (`LiveSpots`, `LiveCounts`), timers (the 0–2 s members refetch, the attendance start-time flip), optimistic attendance marks, the photo pipeline, form validation and changed-only PATCH, offline cache reads, and the open beacon. ~125 Riverpod references outside `providers.dart`.
- [Verified, class listing] Private widget classes: `_PlanSkeleton`, `_InviteRow`, `_InviteSheet`, `_ActivitySkeleton`, `_CommunitySkeleton`, `_InviteSkeleton`, `_OpenInvite`, `_ClaimAction`, `_Outcome`, `_DangerButton`, `_FieldError`, `_PickerField`, `_Spots`, `_ZoneSheet`, `_MapNote`, `_MarkButton`. Also many private widget-building methods (`_body`, `_card`, `_formView`, `_photo`, `_back`). Non-widget private classes: `_PathProxy`, `_IconPainter`, `_ScenePainter`, `_DashedBorder`, `_CodeFormatter`, `_PlanData`, the `_PlanLoader` mixin and every `State` subclass.
- [Verified] Pure logic already sits outside widgets and is unit-tested: `core/host_form.dart`, `attendance.dart`, `booking.dart`, `invite_logic.dart`, `format.dart`, `realtime.dart`, `live.dart`, `cache.dart`, `identity.dart`, `photo.dart`, `places.dart`.
- [Verified, `test/`, `integration_test/`] 63 test cases across `core_test`, `services_test`, `realtime_test`, `host_test`, `widgets_test` and `parity_widgets_test`. `test/harness.dart` pumps screens in a `ProviderScope` with overrides (fake API, quiet realtime, fixed clock, fixed connectivity). Two integration tests: `smoke_test`, `parity_test`.
- [Verified, `.github/workflows/ci.yml`] The `mobile` job runs `flutter pub get --enforce-lockfile`, `dart format`, `flutter analyze` and `flutter test`.
- [Verified, pub.dev 2026-11-05] Latest stable: `flutter_bloc` 9.1.1, `bloc` 9.2.1, `bloc_test` 10.0.0, `equatable` 3.0.0, `bloc_concurrency` 0.3.0, `mocktail` 1.0.5. `bloc_lint` 0.4.3 is stable, but its CLI ships in `bloc_tools` 0.1.0-dev.25, which is a pre-release.

## 3. Desired outcome

The app looks and behaves exactly as it does now. All S7 and S7b requirements still hold. Internally:

- No Riverpod import remains, and `flutter_riverpod` is gone from `pubspec.yaml` and the lockfile.
- Each layer has one job: data providers talk to the outside world, repositories expose domain operations and streams, blocs hold all business logic and state, and widgets render state and dispatch events.
- Every widget class is public and lives in its feature's `view/` or `widgets/` folder.
- Every bloc is unit-tested with `bloc_test`, and the existing widget tests still pass on the new harness.

## 4. Proposed solution [Proposal]

### 4.1 Layers (bloclibrary.dev "Architecture")

| Layer | Contents | May depend on |
| --- | --- | --- |
| **Data providers** | Raw I/O, unchanged in behavior: `Api` (Dio + generated client), `RealtimeClient`, `OfflineCache`, `Identity` and `SecretStore`, `PlacesClient`, `PhotoUploader`, connectivity, `SharedPreferencesAsync`, the image picker | Packages only |
| **Repositories** | One per domain, composing data providers into Futures and Streams. No Flutter widget imports. | Data providers |
| **Business logic** | One `Bloc` per screen plus a few app-wide blocs and cubits. No Flutter widget imports, no `BuildContext`, no navigation, no haptics. | Repositories only, injected through the constructor |
| **Presentation** | Pages, views and widgets. `BlocProvider`, `BlocBuilder`, `BlocSelector`, `BlocListener`. Side effects (navigation, haptics, snack bars, screen-reader announcements, share sheet, URL launch) happen only in `BlocListener`s that react to state. | Blocs (via `context.read` / `watch`) |

Repositories (proposed split, by domain):

| Repository | Wraps | Exposes |
| --- | --- | --- |
| `SessionRepository` | `Identity`, `Api` sign-in/out, the 401 hook | `profile`, `signedIn`, `signIn`, `signOut`, `Stream<SessionStatus> changes` (replaces `sessionVersionProvider`); reconnects the socket on change |
| `PreferencesRepository` | `SharedPreferencesAsync` | `loadRole`, `saveRole`, attempt keys (`AttemptKeys` moves here) |
| `ConnectivityRepository` | `connectivity_plus` | `Stream<bool> online` (replaces `onlineProvider`) |
| `LiveRepository` | `RealtimeClient` | `Stream<SpotsUpdate> watchSpots(activityId, {planId, extraTopics})` with the version gate, `Stream<RealtimeStatus> status`, `setForeground`, render acks. `LiveSpots` and `LiveCounts` lose `ChangeNotifier` and their Flutter imports; the 5 s announcement throttle moves to the presentation layer. |
| `InviteRepository` | `Api`, `OfflineCache`, attempt keys | invite view (network, then cache fallback with `cachedAt`), open beacon, claim with one idempotency key per attempt, next steps |
| `ActivityRepository` | `Api`, attempt keys | activity, members, communities, community page, book |
| `PlanRepository` | `Api`, `OfflineCache` | Plan, My plans (with cache), vouch and public-link invites, profile |
| `HostRepository` | `Api`, `PhotoUploader`, `PlacesClient`, image picker | host list, create, changed-only patch, photo pipeline, attendance, mark, remove, place search |

Build-time and platform values (`platform`, `clock`, `mapsEnabled`, `PLACES_KEY`) become an `AppConfig` value passed to repositories and blocs that need it, so tests can fix them as they do now.

### 4.2 Business logic

- **App-wide** (provided above `MaterialApp.router`): `SessionBloc` (signed in or out, reacting to `SessionRepository.changes`), `RoleCubit` (Booker / Host, persisted), `ConnectivityCubit` (online hint), `LifecycleCubit` or a direct `LiveRepository.setForeground` call from the app's lifecycle observer (§12 Q-5).
- **Per screen** (created by the route's page widget, closed with it): `CodeEntryBloc`, `InviteBloc`, `ClaimBloc`, `PlanBloc` (shared by Plan and You're in, replacing the `_PlanLoader` mixin), `InviteSheetBloc`, `MyPlansBloc`, `ProfileBloc`, `SignInBloc`, `CommunityBloc`, `ActivityBloc`, `HostListBloc`, `ActivityFormBloc`, `LocationPickerBloc`, `AttendanceBloc`.
- **Events** are past-tense verbs named for what happened in the UI (`ActivityBookPressed`, `InviteCodeSubmitted`, `AttendanceMarkToggled`), per the bloc naming conventions. Classes are `sealed`/`final`.
- **States** are one `Equatable` class per bloc with a `status` enum (`initial`, `loading`, `success`, `failure`) and `copyWith`, as in the official examples, except where the screen is a true state machine (the invite outcome, the claim outcome), which use sealed subclasses. Existing pure-logic types (`InviteScreen`, `ClaimOutcome`, `BookingOutcome`, `HostForm`, `AttendanceStats`) are reused inside states.
- **Concurrency** uses `bloc_concurrency`: `droppable()` for Book, Claim, Publish and Save (a second tap is ignored while one runs, as today), `restartable()` for the Places search and the attendance search, `sequential()` for marks and removals.
- **Streams** (live spots, connectivity, session) are consumed with `emit.forEach` / `emit.onEach` inside an event handler, so the bloc cancels them when it closes. Timers (members refetch after 0–2 s, attendance start-time flip) live in the bloc and are cancelled in `close()`.
- **Side effects as state:** a bloc that needs a haptic, navigation or announcement exposes it as a state field (for example `ActivityState.lastResult` / a one-shot `effect` with a sequence number). The view's `BlocListener` uses `listenWhen` to act on it. Blocs never touch `HapticFeedback`, `GoRouter`, `SemanticsService` or `Share`.

### 4.3 Presentation and folder layout

Feature-first, as in the official examples (`flutter_todos`, `flutter_weather`):

```
lib/
  main.dart                      bootstrap: load services, build repositories, runApp(App)
  app/                           App (MultiRepositoryProvider + app-wide BlocProviders), AppView, router, theme
  data/                          data providers (today's core/api.dart, realtime.dart, cache.dart, identity.dart, places.dart, photo.dart)
  repositories/                  the repositories in §4.1
  domain/                        today's pure logic (host_form, attendance, booking, invite_logic, format) — see §12 Q-2
  ui/                            shared design-system widgets (components, cards, art, location), all public
  <feature>/                     code_entry, invite, claim, plan, my_plans, profile, sign_in, community,
    bloc/                          activity, host_list, activity_form, attendance, shell, errors
      <feature>_bloc.dart
      <feature>_event.dart       (part of the bloc)
      <feature>_state.dart       (part of the bloc)
    view/
      <feature>_page.dart        public; creates the bloc with BlocProvider and adds the first event
      <feature>_view.dart        public; BlocBuilder / BlocListener
    widgets/                     public widgets; today's _OpenInvite, _InviteRow, _Spots, … and the _body/_card helpers
    <feature>.dart               barrel export
```

- `go_router` stays. Routes build `XPage` widgets. Navigation is triggered from views (taps) and `BlocListener`s (results); route redirects stay in the router, as they are routing, not business rules.
- `StatefulWidget`s remain only for UI-owned objects: `TextEditingController`, `ScrollController`, `AnimationController`, `GoogleMapController`, focus nodes. Their `State` holds no business state; text changes are sent to the bloc as events.
- "No private widget classes" applies to every `Widget` subclass. Private `State` subclasses, `CustomPainter`s and `TextInputFormatter`s are covered by §12 Q-3.

### 4.4 Tests

- `test/harness.dart` provides fake repositories (and the same fake `Api`, quiet realtime, fixed clock, fixed connectivity) through `MultiRepositoryProvider` and the app-wide blocs. Every existing widget test keeps its name, its V-* tag and its assertions; only setup changes.
- A new `bloc_test` suite per bloc, using `mocktail` fakes of the repositories, covers each event and each state transition listed in REQUIREMENTS.
- Repository tests cover the cache fallback, attempt-key reuse, the version gate and session changes (moved from `services_test` and `realtime_test` where they test the same logic).
- `main.run()` takes named test seams (for example `photoPicker:`) instead of Riverpod `overrides`. Both integration tests are updated to match.

## 5. Architectural considerations

- **Behavior parity is the constraint.** S7 and S7b requirements, copy, haptics, realtime rules 1–6, offline behavior and idempotency must not change. Existing tests are the parity net; they are adapted, not weakened.
- **Lifetime:** the realtime socket and caches are app-lifetime singletons owned by repositories, created once in `main`. Per-screen blocs close with their route, which stops their watches (today `LiveSpots.dispose`).
- **Accessibility:** the polite spots announcement (UX NFR-003, at most every 5 s) needs a `FlutterView`, so it moves to a small public presentation widget (`SpotsAnnouncer`) driven by state.
- **Security and privacy:** unchanged. Tokens stay in secure storage; blocs never log state containing contacts or codes (no `BlocObserver` that prints states in release builds).
- **Performance:** `BlocSelector` / `buildWhen` keep live-spot ticks from rebuilding whole screens.

## 6. Components and files affected

- `apps/mobile/pubspec.yaml`, `pubspec.lock`: remove `flutter_riverpod`; add `flutter_bloc`, `bloc`, `equatable`, `bloc_concurrency`; dev `bloc_test`, `mocktail`.
- `apps/mobile/lib/**`: every file moves or changes (layout in §4.3). Data-provider behavior is unchanged.
- `apps/mobile/test/**`, `apps/mobile/integration_test/**`: harness rewritten, imports updated, new bloc and repository tests.
- `README.md` (mobile section, if it names Riverpod or file paths), `CHANGELOG.md`, this spec. Not affected: the API, web, contracts, `packages/api-client-dart`, `packages/design-tokens`, CI workflow (same commands).

## 7. Implementation phases and ordered tasks

Each phase ends with `dart format`, `flutter analyze` and `flutter test` green.

1. **Dependencies and skeleton.** Add bloc packages at the pinned versions; create `data/`, `repositories/`, `app/` structure; move data providers without behavior change; update imports.
2. **Repositories and app-wide state.** Write the repositories and their tests; `SessionBloc`, `RoleCubit`, `ConnectivityCubit`; new `App` with `MultiRepositoryProvider`; new test harness that provides both Riverpod overrides and repositories while screens are migrated.
3. **Guest screens:** code entry, invite, claim, You're in and Plan (with the invite sheet), My plans, profile, sign in, errors. Bloc + tests, page/view/widgets split, private widgets made public.
4. **Booker screens:** shell and role toggle, community, activity.
5. **Host screens:** host list, activity form and location picker, attendance.
6. **Remove Riverpod:** delete `providers.dart`, `online.dart`'s provider, the harness overrides and the dependency; refresh the lockfile.
7. **Verify:** full checks (VALIDATION Part A), the two integration tests on the iOS simulator against the local API, the conformance greps; record results; changelog.

## 8. Dependencies and prerequisites

- Owner answers to §12 open questions before implementation starts.
- Flutter 3.47.9 and the local Compose API for integration tests.
- Package versions re-checked on pub.dev at implementation time and pinned exactly (CLAUDE.md "Versions").

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Behavior drift in a large rewrite (~7k lines of `lib/`) | Existing 63 tests kept with the same assertions; phase-by-phase green builds; integration tests at the end |
| Timing-sensitive tests (fake clock, 0–2 s refetch, 5 s announce throttle, polling) break under bloc's async event queue | Inject clock and `Random` into blocs; `fake_async` in bloc tests; widget tests pump explicitly |
| Lost side effects (haptics, beacon sent once, ack per painted version) | Each has an explicit REQUIREMENTS line and a bloc test; render acks stay tied to the frame callback in the presentation layer |
| `bloc_test` 10.0.0 pulls a `test` version that conflicts with `flutter_test`'s pins | Check with `flutter pub get` in phase 1; if it conflicts, use the newest compatible release and record why |
| Mixed Riverpod + bloc during phases 2–5 | Temporary only; phase 6 removes Riverpod and a grep check enforces it |

## 10. Alternatives considered

- **Cubits everywhere.** Less code, but no event transformers (needed for droppable Book/Claim, restartable search) and less traceability. Cubits kept only for trivial app-wide state (§12 Q-1).
- **Repositories as separate Dart packages under `packages/`** (as `flutter_todos` does). Cleaner boundaries, more boilerplate and workspace wiring. Proposed in-app `lib/repositories/` instead (§12 Q-2).
- **`bloc_lint` for enforcement.** Its CLI is only in pre-release `bloc_tools`, which conflicts with the latest-stable rule; conformance is checked with greps and review instead.
- **Keep Riverpod for DI only.** Rejected: the owner asked for Riverpod to go entirely.

## 11. Assumptions

- [Assumption] "Official flutter_bloc architecture" means bloclibrary.dev's Architecture page, naming conventions and the structure of the official examples, as summarised in §4.
- [Assumption] "No private classes for widgets" covers `Widget` subclasses; widget-returning private helper methods are converted to public widget classes too, since they are widgets in all but name.
- [Assumption] "Business logic" means anything that decides what happens: API calls, validation, outcome mapping, idempotency, timers, live-update rules, caching, optimistic updates. Mapping state to widgets, formatting values for display and dispatching events are presentation.
- [Assumption] No visible change is wanted; any change the refactor forces is raised with the owner first.

## 12. Open questions

All answered by the owner on 2026-11-05.

- **Q-1 Bloc or Cubit.** Decided: `Bloc` for every screen; `Cubit` only for role and connectivity.
- **Q-2 Where repositories and pure logic live.** Decided: inside the app (`lib/repositories/`, `lib/domain/`), not as separate packages.
- **Q-3 Scope of "no private classes".** Decided: all `Widget` subclasses public, and private widget-building methods become public widgets. `State` subclasses, `CustomPainter`s and formatters may stay private.
- **Q-4 Test depth.** Adopted as proposed (approved with the spec): a `bloc_test` suite for every bloc, plus the existing widget and integration tests adapted.
- **Q-5 Lifecycle.** Adopted as proposed: the app view's lifecycle observer calls `LiveRepository.setForeground` directly; no cubit.

## 13. Estimated complexity

Large: every file in `apps/mobile/lib` and `test/` changes. Roughly 15 blocs, 8 repositories, ~30 new public widget files.

## 14. Related specs and PRD sections

S7 (`spec/2026-11-04_12-50_s7-flutter-app/`), S7b (`spec/2026-11-04_23-59_s7b-flutter-web-parity/`), MVP plan (`spec/2026-11-03_07-42_group-bookings-mvp-plan/`). PRD M1–M3 and W1 (behavior unchanged).

## 15. Change log

- 2026-11-05 00:40: created.
- 2026-11-05: owner answered Q-1 to Q-3 with the proposals and approved the spec for implementation; Q-4 and Q-5 adopted as proposed.
- 2026-11-05: AC-003 replaced by AC-009 during implementation. Pages read repositories in `BlocProvider.create`, the official bloc page pattern, which AC-003 had forbidden by mistake. V-GREP-3 was updated to match.
- 2026-11-05: implemented. Code entry's minimum-height clamp was fixed during verification (VALIDATION Part B).

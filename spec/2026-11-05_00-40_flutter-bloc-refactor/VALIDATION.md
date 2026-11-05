# Validation: Flutter app refactor from Riverpod to flutter_bloc

- **Spec ID:** 2026-11-05_00-40_flutter-bloc-refactor

## Part A: Planned checks

### A.1 Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check (A.2).
- [x] Behavior requirements reference S7 / S7b rather than restating them; no new business rules invented.
- [x] Package versions verified on pub.dev on 2026-11-05 (PLANNING §2).
- [x] Open questions Q-1 to Q-5 answered by the owner (2026-11-05).

### A.2 Traceability

| Requirement | Check |
| --- | --- |
| FR-001, AC-001 | V-GREP-1 |
| FR-002, NFR-005 | V-DEPS-1 |
| FR-003, AC-009, AC-004 | V-GREP-3, V-GREP-4, V-REV-1 |
| FR-004, FR-005 | V-REV-1, V-WID-1 |
| FR-006, FR-007 | V-REV-1, V-TREE-1 |
| FR-008, FR-009 | V-GREP-3, V-REV-1 |
| FR-010, AC-002 | V-GREP-2 |
| FR-011 | V-BLOC-1 (`SessionBloc`), V-REPO-1, V-WID-1 (sign-in reload) |
| FR-012 | V-BLOC-1 (`RoleCubit`), V-WID-1 (shell), V-INT-1 |
| FR-013 | V-BLOC-1 (`ConnectivityCubit`), V-WID-1 (offline cases) |
| FR-014 | V-REPO-1 (`LiveRepository`), existing `realtime_test` |
| FR-015 | V-WID-1 (announcement and ack cases), V-REV-1 |
| FR-016 | V-BLOC-1 (double-event and key reuse cases) |
| FR-017 | V-BLOC-1 (effect fields), V-WID-1 (haptic calls via `SystemChannels.platform` mock) |
| FR-018 | V-BLOC-1 (`InviteBloc`), existing beacon widget test |
| FR-019 | V-INT-1 |
| FR-020, NFR-002, AC-005 | V-WID-1, V-TEST-1 |
| NFR-001 | V-FMT-1, V-ANA-1 |
| NFR-003, AC-006 | V-BLOC-1, V-TREE-1 |
| NFR-004 | V-REV-1 |
| SEC-001 | V-GREP-5 |
| SEC-002, SEC-003 | existing `services_test` / `core_test` (`routeForLink`), V-REV-1 |
| AC-007 | V-INT-1 |
| AC-008 | V-MAN-1 |

### A.3 Checks

Run from `apps/mobile` unless noted.

- **V-DEPS-1** `flutter pub get --enforce-lockfile` succeeds; `grep -E 'flutter_bloc|^  bloc|equatable|bloc_concurrency|bloc_test|mocktail' pubspec.yaml` shows exact versions matching pub.dev latest stable (or a recorded exception).
- **V-FMT-1** `dart format --set-exit-if-changed .` → exit 0.
- **V-ANA-1** `flutter analyze` → "No issues found".
- **V-TEST-1** `flutter test` → all pass; the count of pre-existing test names is unchanged (compare `flutter test --reporter json` names before and after).
- **V-BLOC-1** `flutter test test/` includes a `*_bloc_test.dart` (or `*_cubit_test.dart`) per bloc; each event handler has success and failure `blocTest` cases; the risky rules in REQUIREMENTS §7 each have a named case.
- **V-REPO-1** Repository tests: invite cache fallback, attempt-key reuse and clearing, version gate, session change stream and socket reconnect.
- **V-WID-1** Existing widget suites (`widgets_test`, `parity_widgets_test`, `host_test`) pass on the new harness at 360 px and at 390 px with 200% text.
- **V-GREP-1** `grep -rn riverpod lib test integration_test pubspec.yaml pubspec.lock` → no output.
- **V-GREP-2** `grep -rnE 'class _\w+(<[^>]*>)? extends (Stateless|Stateful|Consumer\w*|Inherited\w*|\w*Widget)\b' lib` → no output.
- **V-GREP-3** `grep -rlnE "repositories/|data/" lib/*/widgets lib/ui` → no output; `grep -rnE "\bApi\b|OfflineCache|RealtimeClient|\bIdentity\b|AttemptKeys|ApiException" lib/*/view lib/*/widgets lib/ui` → no output; every `repositories/` import under `lib/*/view` is used only in a `BlocProvider(create: …)` (review).
- **V-GREP-4** `grep -rlnE "package:flutter/(material|widgets|services|cupertino)\.dart|go_router|share_plus" lib/*/bloc lib/repositories lib/data lib/domain` → no output (`foundation.dart` for `@immutable` is allowed).
- **V-GREP-5** `grep -rn BlocObserver lib` → none, or one that is debug-only and logs only event and state type names.
- **V-TREE-1** `find lib -path '*/bloc/*'` matches the bloc list in PLANNING §4.2; each has a test file.
- **V-REV-1** Code review of the diff against PLANNING §4 and FR-003–FR-010.
- **V-INT-1** iOS simulator, local Compose API: `flutter test integration_test/smoke_test.dart` and `integration_test/parity_test.dart` pass.
- **V-MAN-1** The manual pass in AC-008, on the iOS simulator.

### A.4 Preconditions and test data

Local Compose stack up (`README.md`), seeded communities; the existing fixtures in `test/fixtures.dart` and `test/samples/`.

### A.5 Expected results

All checks pass. Baseline before starting: record the current `flutter test` pass count and test names so V-TEST-1 can compare.

### A.6 Known limitations

Haptics and screen-reader announcements are checked through mocked platform channels and code review, not on a device (as in S7). Native maps and Places need keys that aren't set locally.

## Part B: Executed checks

All checks below were run on 2026-11-05 from `apps/mobile` with Flutter 3.47.9.

| Check | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| Baseline | `flutter test --reporter json` before any change | 149 test runs, all passed; names saved for V-TEST-1 | NFR-002 |
| V-DEPS-1 | `flutter pub get` | Passed. `flutter_bloc` 9.1.1, `bloc` 9.2.1, `bloc_concurrency` 0.3.0, `equatable` 3.0.0, dev `bloc_test` 10.0.0 and `mocktail` 1.0.5, all latest stable and pinned exactly; no conflict with `flutter_test`. `flutter_riverpod`, `riverpod` and `state_notifier` left the lockfile. | FR-002, NFR-005 |
| V-FMT-1 | `dart format --set-exit-if-changed lib test integration_test` | Passed (179 files, 0 changed) | NFR-001 |
| V-ANA-1 | `flutter analyze` | Passed: "No issues found" | NFR-001 |
| V-TEST-1 | `flutter test --reporter json`, names compared with the baseline | Passed: 289 test runs, all passed; all 149 baseline names present with their assertions | FR-020, NFR-002, AC-005 |
| V-BLOC-1 | `flutter test` (part of V-TEST-1) | Passed. One `*_bloc_test.dart` per screen bloc (14 files: activity, activity form, attendance, claim, code entry, explore, host list, invite, location picker, My plans, invite sheet, Plan, profile, sign in) and `test/app/app_state_test.dart` for `SessionBloc`, `RoleCubit` and `ConnectivityCubit` | FR-011–FR-018, NFR-003, AC-006 |
| V-REPO-1 | `test/repositories/live_repository_test.dart`, `session_repository_test.dart`; attempt keys and cache in `services_test.dart` | Passed | FR-011, FR-014 |
| V-WID-1 | `widgets_test`, `parity_widgets_test`, `host_test` on the new harness (part of V-TEST-1) | Passed at 360 px and at 390 px with 200% text | FR-004, FR-005, FR-012, FR-013, FR-015, FR-020 |
| V-GREP-1 | `grep -rn riverpod lib test integration_test pubspec.yaml pubspec.lock` | Passed: no output | FR-001, AC-001 |
| V-GREP-2 | Private Widget subclass grep, plus `grep -rnE '^\s+Widget\??\s+_\w+\(' lib` for widget-building helpers | Passed: no output | FR-010, AC-002 |
| V-GREP-3 | Greps as amended for AC-009 | Passed after one fix: `showInviteSheet` built its bloc from `widgets/`, so it moved to `plan/view/invite_sheet_page.dart`. Under `view/`, every repository read is in a `BlocProvider(create: …)`; `app/view/app.dart` forwards the app lifecycle to `LiveRepository` (PLANNING §12 Q-5) | FR-003, FR-008, AC-009 |
| V-GREP-4 | Flutter-UI, go_router, share_plus and `HapticFeedback` grep over `bloc/`, `cubit/`, `repositories/`, `data/`, `domain/` | Passed: no output. `LiveRepository` imports `flutter/scheduler.dart` to defer render acks to the painted frame, as `LiveSpots` did | FR-003, FR-009, AC-004 |
| V-GREP-5 | `grep -rn BlocObserver lib` | Passed: none | SEC-001 |
| V-TREE-1 | `find lib -name '*_bloc.dart' -o -name '*_cubit.dart'`, compared with the test files | Passed: 17 blocs and cubits, each tested | NFR-003 |
| V-REV-1 | Review of the forks' reports and the tree; grep of `view/`, `widgets/` and `ui/` for `try`, `catch`, `Timer(`, `Future.delayed`, preferences, validation and `.apply(` | Passed: none, apart from the throttle timer in `ui/spots_announcer.dart` (presentation, UX NFR-003). A follow-up line-by-line read of the four riskiest blocs (invite, activity, attendance, claim) against the old screens found no behaviour change beyond those listed below. Live watches are bound to the handler's `emit.onEach`, so they end when the bloc closes. Timers and session subscriptions are cancelled in `close()`. Idempotency keys are cleared on exactly the outcomes they were before. | FR-008, FR-009, FR-014, FR-016, NFR-004 |
| V-INT-1 (parity) | iOS simulator (iPhone 17 Pro), local API: `flutter test integration_test/parity_test.dart --dart-define=API_BASE_URL=http://localhost:3001` | Passed: books from Explore, publishes as host with a photo, sees a second person's booking live, removes it | FR-019, AC-007, AC-008 |
| V-INT-1 (smoke) | Same simulator: `flutter test integration_test/smoke_test.dart --dart-define=SMOKE_CODE=<seeded vouch> --dart-define=API_BASE_URL=http://localhost:3001` | Passed with exception. Code → invite → claim → You're in → Plan → My plans all pass. The last assertion waits for an activity titled "E2E App check", which exists on the deployed stack but not in local seed data (`seed-invites.ts` titles are "Seed … Sunset Kayaking"). | AC-007 |

### Defects found and fixed during verification

- **Code entry: layout assertion with the keyboard up.** On the simulator the code field's `LayoutBuilder` computed `minHeight: box.maxHeight - 56`. When the keyboard left less room than that, the height went negative and the assertion broke the subtree, so the typed code was lost. The layout is unchanged from before the refactor, so this was a latent bug. Fixed by clamping the height to zero or more (`lib/code_entry/view/code_entry_page.dart`). Widget tests don't show a keyboard, so only the smoke test caught it.
- **Invite sheet built its bloc from `widgets/`.** Moved to `view/` (see V-GREP-3).

### Checks not run

- **V-MAN-1** (hands-on manual pass) wasn't done by hand. Its AC-008 steps were run by `parity_test` and `smoke_test` on the simulator instead.
- **Smoke test against the deployed stack**, where "E2E App check" exists: not run, since the refactor isn't deployed.
- **Haptics and screen-reader announcements on a device:** not checked (A.6). They are covered by code review and bloc state tests only.

### Deviations from the plan, all reported by the implementers and accepted

- **AC-003 replaced by AC-009** (PLANNING change log).
- **The 5 s throttle on live-spots announcements** lives in the shared presentation widget `SpotsAnnouncer`.
- **Sold-out haptic on an invite** fires only when a live change makes the invite sold out. The old code could also fire on the first socket status change for an invite that was already sold out when it opened.
- **The activity page refetches who's going** only when a live event moves the count, not on a status-only notification.
- **Attendance:** an activity that has already started when it loads flips to marking one event later, not in the same frame. Activity form validation uses the clock at the last edit.
- **Naming:** pages are `XPage` and views `XView`, except `InviteDetailsView`, `PlanDetailsView` and `ExplorePage`, which avoid names already used by `velio_api` models. Files that import both `velio_api` and `activity/activity.dart` must hide one `ActivityState`.

### Final validation status

**Passed with exceptions**: the smoke test's last assertion needs deployed data, and the manual pass was replaced by the two integration tests.

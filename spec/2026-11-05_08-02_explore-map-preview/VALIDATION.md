# Validation: Explore map preview carousel

Spec: `spec/2026-11-05_08-02_explore-map-preview/`

## Part A: Planned checks

### A.1 Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check.
- [x] The PRD (A6, A7) is respected; no departures.
- [x] The owner chose the description source (`summary` on the card).

### A.2 Traceability

| Requirement | Check |
| --- | --- |
| FR-001, AC-002 | C1 `summarise` unit tests |
| FR-002, AC-001 | C2 API community page test |
| FR-003, FR-005, FR-006, FR-009, AC-005 | C7 manual simulator check |
| FR-004, FR-007, AC-004 | C4 `MapPreviewCard` widget test |
| FR-008, AC-003 | C3 bloc test |
| NFR-001 | Code review: no pubspec/package.json dependency changes |
| NFR-002 | C5 static checks, C6 client regeneration |
| SEC-001 | Code review: `summary` derived from description only |

### A.3 Checks

- **C1** `bun test apps/api/test/activities` (`summarise` cases).
- **C2** `bun test apps/api` (community page includes `summary`).
- **C3** `flutter test test/explore`.
- **C4** `flutter test test/widgets_test.dart`.
- **C5** `bun run lint && bun run typecheck && bun run format:check`; `dart format --set-exit-if-changed .` and `flutter analyze` in `apps/mobile`; full `flutter test`; `bun run web:test`.
- **C6** `bun run contracts:openapi && bun run contracts:dart`, then `git diff --stat packages/` shows only the `summary` addition.
- **C7** Manual: run `mobile` from `.vscode/launch.json` (MAPS=true) against local API; tap pins, swipe cards, tap a card.

### A.4 Preconditions and test data

Compose Postgres running (`bun run db:migrate`). Docker for the generator. Seeded community with ≥ 2 open activities, one with a long description, for C7.

### A.5 Expected results

All automated checks pass; manual check shows two-way sync.

### A.6 Known limitations

`GoogleMap` can't be widget-tested; map behaviour is manual only.

## Part B: Executed checks

All run 2026-11-05 on macOS (Apple silicon), Bun 1.4.4, Flutter via fvm, Compose stack local.

| Check | Command / procedure | Result | Covers |
| --- | --- | --- | --- |
| C1 | `bun test apps/api/test/activities/snapshot.test.ts apps/api/test/read` | Pass (21/21) | FR-001, AC-002 |
| C2 | same run: `read-apis.test.ts` community page asserts `summary` collapsed and cut | Pass | FR-002, AC-001 |
| C2 (full) | `bun test` (full Compose stack up) | 276 pass, 4 fail: only the 200-parallel race tests in `apps/api/test/concurrency/` (`ECONNREFUSED` from the local listener; a different subset fails each run). They don't touch cards. See below | none of this spec |
| C3 | `fvm flutter test test/explore` | Pass (15/15) | FR-005, FR-006, FR-008, AC-003 |
| C4 | `fvm flutter test test/widgets_test.dart` (two `MapPreviewCard` tests) | Pass | FR-004, FR-007, AC-004 |
| C5 | `bun run lint`, `bun run typecheck`, `bun run format:check`, `bun run web:test` (221 pass); `dart format --set-exit-if-changed lib test`, `flutter analyze` (no issues), `flutter test` (all 293 pass) | Pass | NFR-002 |
| C6 | `bun run contracts:openapi && bun run contracts:dart`; diff is only `summary` in `ActivityCard` / `HostActivityItem` (+ `openapi.json`) | Pass | NFR-002 |
| Review | No dependency changes; `summary` built only from `activities.description` | Pass | NFR-001, SEC-001 |

### Defects found and fixed during verification

- The card footer overflowed by 7 px at a 320 px card width (widget test). Fixed: the spots badge now scales down to fit.
- Captured API samples (`apps/mobile/test/samples/*.json`) and the web test fixtures lacked `summary`. Added `"summary": ""` to them.

### Checks not run

- **C7 manual simulator check** (FR-003, FR-005, FR-006, FR-009, AC-005): not run. The `GoogleMap` sync (pin ↔ card, camera framing) is untested until someone runs it with `MAPS=true` against an API that has this change.
- The concurrency race tests could not be confirmed locally. Connection refusals under 200 parallel connections are environmental. CI on Linux is the reference.

### Deviations

- `ExploreMap` takes a `stale` flag from `ExploreContent` so card badges show the offline/reconnecting state like the list does (not in §4.2).
- `.vscode/launch.json` was reformatted by Prettier (it failed `format:check` after the earlier `MAPS` dart-define edit).

### Final validation status

**Passed with exceptions**: AC-005 (manual map check) not run.


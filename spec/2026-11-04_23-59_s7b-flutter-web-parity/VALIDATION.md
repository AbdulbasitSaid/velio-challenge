# Validation: S7b Flutter web parity

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check below.
- [x] The PRD departure is recorded (PLANNING §12 D1) and was accepted by the owner.
- [x] No invented targets; rules and copy come from the web modules.

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001, FR-002 | V-NAV-1, V-NAV-2 |
| FR-003 | V-C1-1 |
| FR-004, FR-005 | V-B1-1, V-BOOK-1 |
| FR-006 | V-H3-1, V-ROW-1 |
| FR-007, FR-008 | V-FORM-1, V-FORM-2 |
| FR-009, SEC-001 | V-PHOTO-1 |
| FR-010, SEC-003 | V-LOC-1 |
| FR-011, FR-012, SEC-002 | V-ATT-1, V-ATT-2, V-RT-3 |
| FR-013 | V-NAV-2 |
| NFR-001, NFR-002, AC-003 | V-WID-2 |
| NFR-003 | V-DEP-1 |
| NFR-004, AC-004 | V-CI-1 |
| AC-001 | V-MAN-1 |
| AC-002 | V-FORM-1, V-BOOK-1, V-ATT-1, V-ROW-1 |

### Proposed checks

| ID | Kind | Procedure | Expected |
| --- | --- | --- | --- |
| V-NAV-1 | widget | Toggle Host on code entry; toggle Booker on My activities; restart reads the saved role | Routes `/host` and `/`; role persisted |
| V-NAV-2 | unit/widget | Bottom bar on booker roots only; next-step card pushes `/activities/:id` | No browser call |
| V-C1-1 | widget | Community with activities; empty community; a `spots` event | Cards, count line, empty state, badge updates |
| V-B1-1 | widget | Activity: open (signed in, signed out), host, already going, removed, started, paused, sold out, offline | The web's copy per state |
| V-BOOK-1 | unit/widget | Booking outcomes map; failed attempt retries with the same key; sold out banner; success navigates | As FR-005 |
| V-H3-1 | widget | Empty, upcoming, past, signed out | Cards and chips as `hostRow` |
| V-ROW-1 | unit | `hostRow` for each branch | Web's labels and tones |
| V-FORM-1 | unit | `zonedToIso` (incl. DST zone), `isoToZoned`, `parsePrice`, `validate`, `createBody`, `patchBody`, `saveFailure` | Same results as the web's tests |
| V-FORM-2 | widget | Create with empty form → summary and field errors; edit locked → locked banner and read-only fields | As FR-007, FR-008 |
| V-PHOTO-1 | unit | Crop maths; upload Dio has no interceptors | 16:10 centre; no auth headers |
| V-LOC-1 | unit/widget | Places off → message and "Drop a pin"; Maps off → manual fields | As FR-010 |
| V-ATT-1 | unit | `attendanceStats`, `orderAttendees`, `matchesGuest`, `attendeeSource`, `markFailure` | Web's results |
| V-ATT-2 | widget | Before start (Remove → sheet), after start (marks), empty | As FR-012 |
| V-RT-3 | unit | `attendance` message reaches a watch on `host:<id>` only | Callback once |
| V-WID-2 | widget | Each new screen at 360 × 800 and 390 × 844 with 200% text | No overflow |
| V-DEP-1 | manual | pub.dev latest versions on the day; exact pins | Recorded below |
| V-CI-1 | command | `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` | All pass |
| V-MAN-1 | manual | Simulator or device against an API: book; create with photo; attendance live | As AC-001 |

### Preconditions and test data

Fixtures in `apps/mobile/test/fixtures.dart`, extended for host lists and attendance. The manual check needs a running API and a seeded community.

### Known limitations

Places search and native maps need keys that aren't in the repository. Without them, only the fallbacks are testable.

## Part B: Executed checks

All on 2026-11-05, in `apps/mobile`, Flutter 3.47.9 (`.fvmrc`).

| Check | Command or procedure | Result | Covers |
| --- | --- | --- | --- |
| V-CI-1 | `dart format --output=none --set-exit-if-changed lib test` | Pass | NFR-004 |
| V-CI-1 | `flutter analyze` | Pass: no issues | NFR-004 |
| V-CI-1 | `flutter test` | Pass: 149 tests (S7's 88 unchanged and passing; 61 new) | NFR-004, AC-004 |
| V-FORM-1, V-BOOK-1, V-ROW-1, V-ATT-1, V-PHOTO-1 | `test/host_test.dart` (21 tests) | Pass. Zoned time including a DST zone; prices; validation order and copy; create and patch bodies; save failures; booking outcomes; host rows; sources, search, ordering, stats, mark failures; 16:10 crop; 1280 × 800 and 640 × 400 JPEGs; the bucket Dio has no app interceptor (SEC-001) | FR-005–FR-009, FR-011, FR-012, SEC-001, AC-002 |
| V-RT-3 | `test/realtime_test.dart` (2 new) | Pass: `attendance` reaches only the `host:<id>` watch; `reconnect()` opens a new socket with `resume=1`, subscribes, refetches | FR-011 |
| V-WID-2, V-NAV-1, V-NAV-2, V-C1-1, V-B1-1, V-H3-1, V-ATT-2, V-FORM-2, V-LOC-1 | `test/parity_widgets_test.dart` (19 cases × 2 sizes = 38) | Pass at 360 × 800 and at 390 × 844 with 200% text, with no overflow. One overflow ("You're already going" with "Open plan" at 200%) was found and fixed during the run | FR-001–FR-013, NFR-001, NFR-002, AC-003 |
| V-DEP-1 | pub.dev API on 2026-11-04: `image_picker` 1.2.4, `image` 4.12.0; pinned exactly; lockfile only adds packages | Pass | NFR-003 |
| V-MAN-1 | `flutter test integration_test/parity_test.dart -d <iPhone 17 simulator, iOS 26> --dart-define=API_BASE_URL=http://localhost:3001` against the local API, Postgres and MinIO | **Pass** on the third run. Explore → activity → sign in → Book → "You're in" with a `VLO-` ref; Host toggle → Create → photo uploaded to MinIO → typed place → Publish → "Published…"; attendance → a second person books through the API → their row appears live ("Booked just now", "1 of 10") → Remove → confirm → "E2E removed. Their spot is open again." Run 1 found the photo uploader defect; run 2 found the anonymous socket (PLANNING change log) | AC-001, FR-002, FR-004, FR-005, FR-006, FR-007, FR-009, FR-011, FR-012 |
| S7 smoke (regression) | `flutter test integration_test/smoke_test.dart … --dart-define=SMOKE_CODE=<seeded G1>` on the same simulator | Every step passes: code → invite → claim → You're in → Plan → My plans. The final assertion fails: it waits for an activity titled "E2E App check", and the seeded invite's activity is "Seed … Sunset Kayaking". That's test data, not the app; the test is left unchanged | S7 AC-001 |

### Checks not run

- Places search and native maps with real keys (no `PLACES_KEY` or Maps keys in this environment): only the fallbacks were exercised (V-LOC-1, V-MAN-1 typed coordinates).
- Android device or emulator, and the deployed stack: V-MAN-1 ran on the iOS simulator against local Compose, since it publishes an activity and books spots.
- Hands-on haptics, VoiceOver and TalkBack on the new screens.

### Known defects and deviations

- None open. Two defects found and fixed (PLANNING change log, 2026-11-05).
- Deviations: PLANNING §12 D3–D6 as proposed, and the file and navigation notes in the change log.

### Final validation status

**Passed with exceptions**: every automated check and the simulator run pass. Places and native maps on real keys, Android, the deployed stack and assistive-technology checks are not run.

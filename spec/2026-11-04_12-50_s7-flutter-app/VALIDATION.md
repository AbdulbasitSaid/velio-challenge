# Validation: S7 Flutter app

## Part A: Planned checks

### Spec review checklist

- [x] Every FR, NFR, SEC and AC maps to a check below.
- [x] Scope matches parent S7 (code entry, deep links, invite view, claim, live spots, native map, My plans, offline cache, haptics, skeletons), plus the designed P1, X1, X4 and invite creation (PLANNING §12 Q4).
- [x] No invented targets; platform minimums come from the MVP plan and the pinned packages.
- [x] Open questions Q1–Q4 (PLANNING §12) answered (2026-11-04).
- [ ] S5 T2 (design tokens) done before T3.

### Traceability

| Requirement | Checks |
| --- | --- |
| FR-001, AC-006 | V-API-1 |
| FR-002 | V-CMP-1 |
| FR-003, SEC-001 | V-ID-1 |
| FR-004 | V-CODE-1 |
| FR-005, SEC-005, AC-002 | V-DL-1 |
| FR-006, FR-007, SEC-003 | V-INV-1 |
| FR-008, AC-004 | V-RT-1, V-RT-2 |
| FR-009 | V-INV-2 |
| FR-010, SEC-002 | V-CLM-1 |
| FR-011 | V-CLM-2 |
| FR-012 | V-HAP-1 |
| FR-013 | V-PLAN-1 |
| FR-014 | V-MY-1 |
| FR-015, FR-016, AC-003 | V-OFF-1, V-CACHE-1 |
| FR-017 | V-PROF-1, V-ERR-1 |
| FR-018 | V-MAP-1 |
| FR-019 | V-DL-1 |
| NFR-001, AC-005 | V-WID-1 |
| NFR-002 | V-A11Y-1 |
| NFR-003, NFR-004 | V-VER-1 |
| NFR-005 | V-CI-1 |
| NFR-006 | V-SEC-1 |
| SEC-004 | V-SEC-2 |
| AC-001 | V-E2E-1 |

### Proposed checks

**Automated:**

| ID | Check | Expected |
| --- | --- | --- |
| V-API-1 | `bun run contracts:dart && git diff --exit-code packages/api-client-dart` (in CI) | No diff |
| V-CI-1 | `dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test` in `apps/mobile` | Pass locally and in CI |
| V-CMP-1 | Widget tests for base components: spots badge five states, avatar colours from shared fixtures, skeletons | Pass |
| V-ID-1 | Interceptor tests: `X-Device-Id` always, bearer when signed in, `401` clears the token, `Authorization` redacted from any log | Pass |
| V-CODE-1 | Normalisation and validation (spaces, hyphens, lower case, ambiguous characters); inline invalid and rate-limited states | Pass |
| V-RT-1 | Realtime client against a fake channel: subscribe before fetch; version gate; 10 s polling while disconnected (fake async); resync; `plan` refetch; `rendered` once per painted version; announcement throttle 5 s | Pass |
| V-CACHE-1 | Cache writes after fetch, reads offline with fetch time; nothing queued when a claim fails offline | Pass |
| V-ERR-1 | Each API error code maps to its screen or message | Pass |
| V-INV-1 (unit part) | Screen selection for every S6 §4.3 row | Pass |
| V-WID-1 | Every screen's states at 360 px and at 390 px with `TextScaler.linear(2.0)`, asserting no `RenderFlex` overflow | Pass |
| V-SEC-1 | Release build config: no cleartext, no logging interceptor | Pass |

**Manual (emulator, simulator, real devices; deployed stack):**

| ID | Procedure | Expected |
| --- | --- | --- |
| V-VER-1 | Record latest stable Flutter and each package version at implementation, the pinned values and the platform minimums | Pinned = latest stable (or a recorded exception) |
| V-INV-1 (manual part) | Seeded invites in every state (S6 seed) opened in the app; compare with the F artboards | Matches design |
| V-INV-2 | Open an invite twice on one device; query `invite_opens` | One row, platform `android` or `ios` |
| V-RT-2 | App and browser on one invite; claim the last spot in the browser; then free it; background and foreground the app | Live update; sold out with haptic; refetch on resume |
| V-CLM-1 | Claim as a new guest, then as a signed-in guest ("Claiming as", masked contact), "Not you?"; kill the network mid-claim and retry | One booking; same key on retry |
| V-CLM-2 | G4: reference, members, map, directions on iOS (Apple/Google choice) and Android | As designed |
| V-HAP-1 | Real device: claim success and sold-out landing | Distinct haptics felt |
| V-PLAN-1 | Plan statuses live; create a vouch and share into WhatsApp; public link sheet; removed state | As designed |
| V-MY-1 | My plans upcoming, past, removed, empty, loading | As designed |
| V-OFF-1 | Load an invite and My plans, enable airplane mode, relaunch | Cached views with labels; Claim disabled; "Map unavailable offline" |
| V-MAP-1 | With and without the Maps key; block network to Google | Map or address block; claim works |
| V-PROF-1 | P1 from G6's inviter link; X1 on a fresh install, then My plans | As designed |
| V-DL-1 | Android: `flutter run` (debug keystore listed in `assetlinks.json`), `adb shell pm get-app-links <package>` shows `verified`; tap a link cold and warm; unknown path → X4 | Opens the invite in the app |
| V-A11Y-1 | TalkBack and VoiceOver through the claim flow; 200% system text | Labels read; announcements throttled; no truncation of key information |
| V-SEC-2 | Repository grep for Maps keys; Google Cloud key restrictions | None committed; restricted |
| V-E2E-1 | AC-001 flows on Android and iOS against the deployed stack, plus the integration smoke on local Compose | Complete |

### Preconditions and test data

- S6's seed script for invite states; a one-spot activity for races.
- Android device or emulator, iOS simulator.
- Google Maps mobile keys (or fallback-only runs, noted).
- The local debug keystore's SHA-256 configured in S6's `ANDROID_CERT_SHA256`.

### Known limitations

- No iOS Universal Links (no Apple Developer account, decided 2026-11-04).
- Haptics can only be checked on real devices.
- The full Flutter E2E suite is S9's.

## Part B: Executed checks

Not run. Filled in after implementation.

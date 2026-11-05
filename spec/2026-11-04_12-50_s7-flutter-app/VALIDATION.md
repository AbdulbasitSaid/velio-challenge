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

### V-VER-1: versions (looked up 2026-11-04 on pub.dev, Flutter's release feed, Docker Hub and GitHub)

All pinned exactly in `apps/mobile/pubspec.yaml` and `pubspec.lock` (and `.fvmrc`, the CI job, `generate.sh`); every one is the latest stable unless noted.

| Item | Pinned | Note |
| --- | --- | --- |
| Flutter / Dart | 3.47.9 (2026-10-29) / 3.13.7 | `.fvmrc`, CI `subosito/flutter-action` v2.23.0 by commit |
| flutter_riverpod, go_router, dio | 3.4.3, 18.1.3, 5.11.1 | |
| app_links, web_socket_channel, connectivity_plus | 7.2.2, 3.0.3, 7.3.2 | |
| shared_preferences, flutter_secure_storage | 2.5.6, 11.2.0 | |
| google_maps_flutter (ios 2.18.7, android 2.21.0; GoogleMaps SDK 9.4.0) | 2.19.0 | |
| url_launcher, share_plus, intl, timezone, uuid | 6.3.3, 13.3.1, 0.20.3, 0.11.2, 4.6.0 | |
| path_parsing | 1.1.0 | Added (PLANNING change log) |
| flutter_lints, fake_async, shared_preferences_platform_interface (dev) | 6.0.0, 1.3.3, 2.4.2 | |
| Dart client: openapi-generator image | v7.27.0 `sha256:949efd0d…` | |
| Dart client: dio, json_annotation, copy_with_extension(_gen), json_serializable | 5.11.1, 4.12.0, 18.0.0, 6.15.2 | |
| Dart client: build_runner | 2.11.1 | **Exception**: 2.17.1 is incompatible with copy_with_extension_gen 18 (PLANNING change log) |
| Fonts | Sora 700, DM Sans 400 and 700 (Google Fonts static TTFs, OFL, licences bundled) | Same families as the web |
| Platform minimums (NFR-004) | iOS 15.0, Android API 26 | Flutter needs iOS 13 / API 24, `google_maps_flutter_ios` iOS 14; the iOS simulator build with GoogleMaps 9.4.0 at 15.0 passes |

### Automated checks

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-API-1 | `bun run contracts:dart` twice, hash of `lib/`; then `git diff` (also the CI step) | 2026-11-04 | Pass: identical output on both runs (deterministic). The CI step runs on the next push | FR-001, AC-006 |
| V-API-1 (shape) | `test/core_test.dart`: the generated models parse real responses from the deployed API (invite public and as a member, activity, Plan, My plans, next steps, two profiles; names replaced) | 2026-11-04 | Pass, after the `invitedBy` fix (PLANNING change log): before it, a Plan with a direct member threw | FR-001 |
| V-CODE-1 | `test/core_test.dart` (normalise, reject 0/O/1/I/L and lengths, typing filter) and `test/widgets_test.dart` (G8 typed code upper-cased, unknown code inline with the code kept, rate limited) | 2026-11-04 | Pass | FR-004 |
| V-INV-1 (unit, widget) | Screen selection for every S6 §4.3 row and the live count; widgets: G1 vouch (short names only), G2 public, G5 with "Tell Tunde" and the host's other dates, G6, G7 other, paused | 2026-11-04 | Pass | FR-006, FR-007, SEC-003 |
| V-INV-2 (unit) | Widget test: one beacon `K7PQ2N/android` after G1's first frame; none for a cached offline view | 2026-11-04 | Pass | FR-009 |
| V-ERR-1 | Every claim error code → field, banner (retry or not), done or back; network and unknown → retry | 2026-11-04 | Pass | FR-010, FR-017 |
| V-RT-1 | `test/realtime_test.dart` (fake socket, fake timers): subscribe then fetch, `platform` in the URL; spots and plan routing; drop → refetch, 10 s polling, reconnect with `resume=1`, polling stops; resync refetches all; `rendered`; background closes and foreground resumes with a refetch; last unwatch closes | 2026-11-04 | Pass (one test bug fixed: it read the count after the refetch) | FR-008 |
| V-ID-1 | `test/services_test.dart`: device ID created once, in secure storage, never in shared_preferences; device ID, `X-Client`, `traceparent` on every request, bearer only when signed in; a 401 clears token and profile | 2026-11-04 | Pass | FR-003, SEC-001 |
| V-CACHE-1 | Same file: invite and My plans saved with fetch time, only the asked code returned, unreadable cache dropped; widget tests: offline invite "Last updated 10 min ago", "Reconnect to claim", "Map unavailable offline"; offline My plans "Showing your saved plans." | 2026-11-04 | Pass | FR-015, FR-016 |
| V-CLM-1 (unit, widget) | One key per code, reused until cleared; a failed claim's retry sends the same key; sold out shows the banner with no retry; offline claim sends nothing; "Claiming as … / +254 712 ••• · saved on this phone / Not you?" | 2026-11-04 | Pass | FR-010, FR-016, SEC-002 |
| V-PLAN-1, V-MY-1, V-PROF-1 (widget) | G4 (ref, group, See the plan, Invite a friend); B4 members with "(you)", Via / Direct, invite "Opened"; removed; invite sheet → vouch form → name error; B6 upcoming with removed chip, empty, signed out, offline; P1; X1 empty submit; X4 all four kinds | 2026-11-04 | Pass | FR-011, FR-013, FR-014, FR-017 |
| V-CMP-1 | Spots badge five states; "who's going" label | 2026-11-04 | Pass (avatar colours: `velio_tokens`' own fixture test) | FR-002 |
| V-WID-1 | Every widget case above at 360 × 800 and at 390 × 844 with `TextScaler.linear(2.0)`; an overflow fails the test | 2026-11-04 | Pass after three fixes (PLANNING change log: app bar, "Not you?", Upcoming / Past) | NFR-001, AC-005 |
| V-CI-1 (local) | `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` in `apps/mobile`; `bun run format:check` at the root (Flutter paths added to `.prettierignore`) | 2026-11-04 | Pass: no issues, 87 tests. The CI `mobile` job runs on the next push | NFR-005 |
| iOS build | `flutter build ios --simulator --debug` | 2026-11-04 | Pass (first CocoaPods run, 16 min) | NFR-004 |
| V-SEC-2 (repo) | `grep -rE "AIza[0-9A-Za-z_-]{20,}"` over `apps/mobile`, `packages/api-client-dart` and `spec/` (untracked files included); key files git-ignored | 2026-11-04 | Pass after a fix: the captured API samples carried the server key inside signed `staticMapUrl`s; key and signature replaced with placeholders. `android/secrets.properties` and `ios/Flutter/Secrets.xcconfig` are ignored | SEC-004 |
| V-SEC-1 (config) | Release manifest `usesCleartextTraffic="false"` (debug manifest overrides for local Compose); no logging interceptor | 2026-11-04 | Pass by inspection | NFR-006 |

### Device checks (T12)

| Check | Command or procedure | Date | Result | Covers |
| --- | --- | --- | --- | --- |
| V-E2E-1 (iOS, automated) | `flutter test integration_test/smoke_test.dart -d <iPhone 17 simulator, iOS 26> --dart-define=SMOKE_CODE=<fresh vouch>` against the deployed stack (`https://depimls1pcvv4.cloudfront.net`), real storage, network and socket: G8 code typed in lower case → G1 "wants you on" and the **Live** pill (socket open through CloudFront) → Claim → G3 new guest, two fields → Confirm → G4 "You’re in, E2E." with a `VLO-` ref → See the plan → B4 "(you)" and "Via …" → back → B6 lists the activity | 2026-11-04 | **Pass** (8 s), on the fourth run. Run 1: the claim went through (the keyboard's Done submitted it) but the test then looked for a button that had already turned into "Confirming…" (test bug). Run 2: the simulator was signed in as that guest, so a vouch for the same activity correctly showed "You’re already going" (test data). Run 3: found an **app bug**: iOS keeps the keychain token after a reinstall but not the saved profile, so the guest saw the two-field form while the API booked them as the previous session, and G4 had no name. Fixed: the first launch after an install drops a keychain token (`Identity.load`, unit test added). Run 4: pass; the API shows the vouch claimed and 4 of 6 spots left | FR-004, FR-006–FR-011, FR-013, FR-014, AC-001 (iOS) |
| V-E2E-1 (Android, automated) | Same smoke on the owner's Samsung Galaxy A53 (SM-A536E, Android 16) over USB, debug build signed with the local debug keystore, against the deployed stack, fresh vouch `UCDDMH` | 2026-11-04 | **Pass** (18 s), on the second run. Run 1: the claim tap missed while the keyboard was closing and the layout moved (the framework's hit-test warning; test timing, the form showed no error and nothing was booked); the smoke now closes the keyboard and lets the layout settle before tapping. Run 2: G8 → G1 **Live** → G3 new guest → G4 with ref → B4 "(you)" → B6; the API shows the vouch claimed and 4 of 6 spots left | FR-004, FR-006–FR-011, FR-013, FR-014, AC-001 (Android) |
| V-DL-1 (Android App Links) | After the owner's push (`d417f95`, CI incl. the `mobile` job green, deploy `41927565885` green): `curl` `/.well-known/assetlinks.json`; debug APK installed on the Galaxy A53; `pm verify-app-links --re-verify`, `pm get-app-links`; `am start -W -a VIEW -c BROWSABLE -d https://depimls1pcvv4.cloudfront.net/i/UCDDMH` with the app stopped; screenshot | 2026-11-04 | **Pass**: the file is `200 application/json` with the package and fingerprint; the phone reports `depimls1pcvv4.cloudfront.net: verified`; the link opened `io.github.abdulbasitsaid.velio/.MainActivity` cold (no chooser, no browser) on that invite, which showed G7 "This invite has already been claimed" (correct: this install isn't the claimer). Warm links and the unknown-path X4 are covered by the routing unit tests, not run on the phone | FR-005, FR-019, SEC-005, AC-002 |
| V-CI-1 (GitHub) | CI run `41927142309` on `d417f95` | 2026-11-04 | Pass: `mobile` job: Dart client is up to date, Format, Analyze, Test all green; `check` job green | NFR-005, AC-006 |
| V-MAP-1 (Android, with key) | Keys created with `gcloud services api-keys create` in `velio-maps-5eb36a`: "Velio mobile (Android)" (package + debug SHA-1; Maps SDK for Android, Places API) and "Velio mobile (iOS)" (bundle ID; Maps SDK for iOS, Places API), written to the git-ignored `android/secrets.properties` and `ios/Flutter/Secrets.xcconfig`. Debug APK built with `--dart-define=MAPS=true` and `PLACES_KEY`, on the `Small_Phone` emulator against the deployed stack: Explore → List / Map → Map | 2026-11-05 | **Pass**: the List / Map toggle shows and the Google map renders tiles with the Explore Kenya markers around Nairobi; no Maps authorization error in logcat. **Defect found:** `MAPS` is read with `bool.fromEnvironment`, which only accepts `true`; the README, `domain/env.dart` and PLANNING §change log said `MAPS=1`, which leaves maps off (docs corrected 2026-11-05). Places (New) autocomplete answered with the iOS key and bundle header, and returned 403 without the header. Not run: the single-marker map on G1/G4/B4 and the iOS map on a device (the iOS build with the key ran but there is no tap tool to reach a map screen) | FR-007, FR-011, FR-018 (map on) |
| V-INV-2 (deployed, part) | Run 4's invite open: the API's invite status before the claim | 2026-11-04 | Not checked separately: `invite_opens` rows need database access (the AWS tool was disconnected); the beacon is covered by the widget test | FR-009 |

### Not run yet

- ~~**V-MAP-1 with a key:** the owner's Android and iOS Maps keys don't exist yet; every run used the address-block fallback (FR-018), which the widget tests and the smoke exercise.~~ Keys created and the Android community map checked on 2026-11-05 (above). Still open: the iOS map and the single-marker maps on G1, G4 and B4, checked by hand.
- **V-HAP-1, V-A11Y-1 (VoiceOver, TalkBack), V-OFF-1 (airplane mode), V-RT-2 / AC-004 (app and browser side by side, background and foreground), V-CLM-2 (Apple / Google Maps sheet), V-PLAN-1 (share into WhatsApp):** need a person with a real phone; the logic is unit- and widget-tested.

### Final validation status

**Passed with exceptions** (2026-11-04): all automated checks pass (88 tests, analyze, format, deterministic client generation) and the app completes the claim flow against the deployed stack on iOS (simulator) and Android (real phone). Exceptions: native maps with keys and the hands-on real-device checks above are not run yet. The claim flow passes on the iOS simulator and on a real Android phone.

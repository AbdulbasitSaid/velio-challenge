# Planning: S7b Flutter web parity

- **Spec ID:** 2026-11-04_23-59_s7b-flutter-web-parity
- **Created:** 2026-11-04 23:59 (local)
- **Status:** Implemented (2026-11-05; approved for implementation by the owner, 2026-11-04: "Full match", "Spec, then implement")
- **Parent:** `spec/2026-11-04_12-50_s7-flutter-app/` (Implemented); mirrors S5 (`spec/2026-11-04_12-50_s5-web-host-booker/`)
- **Design:** no Flutter artboards exist for these screens. The app adapts the approved **phone** layouts of the web screens (C1, B1, H1, H2, H3 at 360–430 px in `spec/2026-11-03_10-34_complete-ui-design/`), with the S7 Flutter components.

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

The owner wants the Flutter app to do everything the web app does (2026-11-04). S7 built the guest side only: code entry, invite, claim, Plan, My plans, profile, sign in. Browsing communities, activity pages with direct booking, hosting (create, edit, My activities, live attendance) and the Host / Booker toggle exist only on the web.

## 2. Context and current behavior

- [Verified, S7 PLANNING §4.5] "Activity pages, communities and hosting are web-only (PRD W1, M1). Links from the app to those open the browser." `cardStep` (`apps/mobile/lib/features/invite.dart`) and the Plan's activity link (`plan.dart`) call `openInBrowser('/activities/…')`.
- [Verified, PRD W1, M1] W1 gives the web the role toggle and areas A, B, L, H and I; M1–M3 give Flutter the claim flow. **This spec departs from the PRD's split** (§12 D1).
- [Verified, `packages/api-client-dart/lib/src/api/default_api.dart`] The generated client already has every endpoint needed: communities, community page, bookings, host activities, attendance, mark, removal, create, patch, photo upload.
- [Verified, `apps/web/lib/host-form.ts`, `attendance.ts`, `booking.ts`, `components/host/*`, `activity/activity-live.tsx`, `community/community-live.tsx`] The web's rules: copy-deck validation, zoned times, price parsing, locked fields after the first booking, changed-only PATCH, booking outcomes, attendance stats, ordering, guest search, groups.
- [Verified, `packages/contracts/src/uploads.ts`] Photo types `image/webp`, `image/jpeg`, `image/avif`; 2 MB per object; keys end `.webp|.jpg|.avif`; uploads are S3 presigned POSTs (large 1280 px and small 640 px).
- [Verified, `packages/contracts/src/realtime.ts`] `host:<activityId>` topic with `{type:'attendance', activityId}`; `apps/mobile/lib/core/realtime.dart` doesn't handle it yet.
- [Verified, `apps/mobile/lib/core/providers.dart`] Native maps only with `--dart-define=MAPS=1` and key files; no Places access in the app.
- [Verified, pub.dev 2026-11-04] `image_picker` 1.2.4 (Flutter ≥ 3.41) and `image` 4.12.0 are the latest stable.

## 3. Desired outcome

From the app alone, a person can browse a community, open an activity, book a spot, and land on "You're in". They can switch to Host, create an activity with a photo and a location, edit it, see My activities, and run live attendance: remove guests before the start, mark attended or no-show after it. Guest flows from S7 keep working as before.

## 4. Proposed solution

### 4.1 Navigation (owner decision 2026-11-04: "Role toggle + tabs")

- **Role:** `booker` or `host`, kept in `shared_preferences` (`velio.role`), default `booker`. A Booker | Host `Segmented` sits in the app bar of every top-level screen. Switching goes to `/` (booker) or `/host` (host), as the web's toggle does. The toggle changes the interface, not permissions (PRD Rules).
- **Booker:** a `StatefulShellRoute` with a bottom `NavigationBar`: **Explore** (`/explore`, the first community, like web `/`), **Code** (`/`, still the launch screen, S7 FR-004), **My plans** (`/me/plans`). Detail routes (invite, claim, activity, Plan, profile, sign in) sit above the shell, without the bar.
- **Host:** `/host` My activities (no bottom bar), `/host/new`, `/host/:id/edit[?published=1]`, `/host/:id/attendance`. Signed-out hosts see a sign-in prompt (`/signin?next=/host`).
- Deep links are unchanged: only `/i/<code>` opens in the app (S7 SEC-005).

### 4.2 Screens

| Route | Screen | Ported from | Key behavior |
| --- | --- | --- | --- |
| `/explore`, `/communities/:slug` | **C1** community | `community-live.tsx` | Cover, name, blurb, count line; List / Map toggle; cards with live spots (all activity topics); map shows only activities with spots (native markers; info window opens the activity); without Maps, the toggle hides; empty state |
| `/activities/:id` | **B1** activity | `activity-live.tsx`, `booking.ts` | Photo with live spots, title, detail rows, capacity, who's going (refetched 0–2 s after a spots change), price note, location, host card, About. Actions: host → "Open live attendance"; already going → "Open plan"; removed, started, paused, sold out → banners and next steps; signed out → sign in, then back; offline → "Reconnect to book"; Book → "Booking…" with one idempotency key per attempt, reused on retry. Success: medium haptic → `/plans/:id/welcome`. Sold out mid-attempt: heavy haptic + banner. |
| `/plans/:id/welcome` | **G4 / B2** You're in | S7 `YoureInScreen` | The same screen as after a claim |
| `/host` | **H3** My activities | `host-list.tsx` | Upcoming / Past; cards with thumbnail, title, when, "n of cap booked", status chip as `hostRow`; tap → attendance; Create; empty state |
| `/host/new`, `/host/:id/edit` | **H2** create and edit | `activity-form.tsx`, `host-form.ts` | Photo (pick → crop 16:10 → 1280 and 640 px JPEG → presigned POSTs), title, description, community (create only), date and time pickers, time zone (searchable list; default = the community's zone, §12 D3), location picker (§4.4), meeting point (140), price (create only), spots stepper with floor; error summary; locked banner and fields after the first booking; preview card; Publish → `/host/:id/edit?published=1` with the "Published" banner; Save → "Changes saved"; `location_locked`, `capacity_below_bookings`, photo and permission errors as the web maps them |
| `/host/:id/attendance` | **H1** attendance | `attendance-live.tsx`, `attendance.ts` | Phone layout: Booked or Marked stat with live spots; "has started" banner; guest search (name or ref); rows with ref, booked time, source chip; before start: Remove → confirm bottom sheet → removal; after start: Attended / No-show (optimistic; reverted with the web's messages on failure); live via `host:<id>` `attendance` → refetch; flips to marking at the start time; privacy line; "Edit activity" before start |

Next-step cards (invite outcomes, Plan, profile, activity) now open `/activities/:id` in the app instead of the browser.

### 4.3 Shared logic [Proposal]

`lib/core/host_form.dart`, `lib/core/attendance.dart` and `lib/core/booking.dart` are pure Dart ports of the web modules, with the same copy, so the rules are unit-tested alone. Zoned time uses the `timezone` package (already pinned). `LiveCounts` (in `live.dart`) follows several activities for C1, with the version gate per activity. `LiveSpots` gains extra topics and an `onAttendance` callback; `RealtimeClient` dispatches `attendance` to watches on `host:<id>`.

### 4.4 Location picker (owner decision 2026-11-04: "Places search + pin")

- **Search:** Places API (New) over REST: `POST https://places.googleapis.com/v1/places:autocomplete` (biased to the pin or the community's centre, one session token per pick), then `GET /v1/places/{id}` with field mask `id,displayName,formattedAddress,location`, which ends the session. The key comes from `--dart-define=PLACES_KEY=…`. Requests send `X-Android-Package` or `X-Ios-Bundle-Identifier`, plus `X-Android-Cert` when `--dart-define=ANDROID_CERT_SHA1` is set, so the key can carry app restrictions.
- **Pin:** with Maps on, a native map with the pin at the centre; dragging the map moves the pin. Venue and address fields always show, prefilled by a pick. "Drop a pin without a place" starts at the community's centre.
- **Fallback:** no Places key, or search fails → "Place search isn't available right now. Drop a pin on the map instead." No Maps → venue, address, latitude and longitude typed in (web FR-021).

### 4.5 Photo [Proposal]

`image_picker` (gallery) with a native downscale to at most 2560 px, then an isolate (`compute`) with `image`: orientation baked, centre-cropped to 16:10, resized to 1280 and 640 px, and JPEG at quality 72 (`image` can't encode WebP). Then `POST /api/uploads/photos {contentType:'image/jpeg'}` and both presigned POSTs on a **separate Dio with no interceptors**, so no token or device ID goes to S3. The preview shows the local bytes.

### 4.6 API additions (`lib/core/api.dart`)

`communities`, `community(slug)`, `book(activityId, key)`, `hostActivities`, `attendance(id)`, `mark(bookingId, mark)`, `removeBooking(bookingId)`, `createActivity(body)`, `patchActivity(id, body)`, `photoUpload(contentType)`. Create and patch bodies are hand-built maps, like `createInvite`, because the generated models would serialise unset optional fields as `null`.

## 5. Architectural considerations

- No API, contract or web change. Same endpoints, same rules, same copy.
- Booking and claims never queue offline (PRD M2); Book is disabled offline.
- The host sees names, refs and sources, never contacts (PRD H1, Privacy). The app stores nothing new beyond the role.
- Places requests carry only the typed query and a bias point. No personal data goes to telemetry (CLAUDE.md).

## 6. Components and files affected

- **New:** `lib/features/{shell,community,activity,host_list,host_form,attendance}.dart`, `lib/core/{host_form,attendance,booking,role,places,photo}.dart`, `lib/ui/{cards,picker}.dart`; tests `test/host_test.dart`, `test/parity_widgets_test.dart`.
- **Changed:** `lib/app/router.dart` (shell, routes), `lib/core/{api,live,realtime,providers}.dart`, `lib/features/{code_entry,my_plans,invite,plan,profile}.dart` (toggle, in-app activity links), `lib/main.dart` (role load), `pubspec.yaml` / `pubspec.lock` (two dependencies), iOS `Info.plist` (photo library usage string), `test/widgets_test.dart` (app bar changes), `README.md`, `CHANGELOG.md`, `ROADMAP.md`.

## 7. Implementation phases and ordered tasks

1. **T1:** dependencies; API methods; realtime `attendance`; `LiveCounts`; pure modules and their unit tests.
2. **T2:** role, shell and router; toggle on top-level screens; in-app activity links.
3. **T3:** C1 community and B1 activity with booking.
4. **T4:** H3 My activities and H1 attendance.
5. **T5:** H2 form, photo upload and location picker.
6. **T6:** widget tests at 360 px and at 390 px with 200% text; format, analyze, test; docs.

## 8. Dependencies and prerequisites

- Flutter 3.47.9 (`.fvmrc`). `image_picker` 1.2.4, `image` 4.12.0.
- Places search needs a key with Places API (New) enabled, passed at build time. Without one, the fallback applies (§4.4).

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Decoding large photos in Dart is slow | Native downscale in `image_picker` first; work in an isolate |
| A JPEG over 2 MB is refused | 1280 px at quality 72 is far below the limit; an upload error shows the web's message |
| Places key misuse | App-restriction headers; key never committed; search optional |
| Router rework breaks S7 flows | S7 widget tests and the routing unit tests stay; `/` is still code entry |
| Text at 200% overflows dense host rows | Wrap layouts; every new screen is tested at 390 px and 200% |

## 10. Alternatives considered

- **Opening the web in a WebView for host screens:** rejected. It's not native, and sessions don't carry over (bearer token vs cookie).
- **`flutter_timezone` for the device zone:** a new plugin for one default. The community's zone serves hosts better (§12 D3).

## 11. Estimated complexity

Large: six screens, about 2,500 lines of Dart plus tests.

## 12. Assumptions and open questions

- **D1 (PRD departure, raised and accepted 2026-11-04):** Flutter covers A, B, H and the role toggle too, not only M1–M3. The PRD is not edited. This spec records the departure.
- **D2 [Assumption]:** with no Flutter artboards, the phone layouts of the web designs are the design.
- **D3 [Proposal]:** the create form's time zone defaults to the community's zone (Explore Kenya → `Africa/Nairobi`, The Tanzania Experience → `Africa/Dar_es_Salaam`, The Medina Collective → `Africa/Casablanca`), not the phone's. The host can change it.
- **D4 [Proposal]:** after booking, the app shows the S7 "You're in" screen (G4) as its B2.
- **D5 [Proposal]:** the community map uses native markers with an info window, not the web's HTML pins with clustering.
- **D6 [Proposal]:** the phone attendance layout leaves out the Groups summary and the stat-card grid, as the web does below 768 px.

## 13. Related specs and PRD sections

PRD A1–A7, B1–B3, H1–H2, L1–L2, W1, M1–M3, Q2, Q13; S5 (web host and booker), S6 (web invite and claim), S7 (Flutter app); Maps spec FR-005, FR-017, FR-021.

## 14. Change log

- 2026-11-04: created; scope and navigation and location choices approved by the owner in conversation.
- 2026-11-05 (implementation):
  - **Files:** the screen for H2 is `lib/features/activity_form.dart` (not `host_form.dart`, which would share its name with the rules in `lib/core/`). The shared cards are in `lib/ui/cards.dart`, the picker in `lib/ui/picker.dart`. The widget-test harness moved from `test/widgets_test.dart` to `test/harness.dart` so both suites share it; no S7 test changed its assertions.
  - **Navigation:** the toggle replaces code entry's "My plans" button and My plans' "Enter a code" button, since both are tabs now.
  - **Icons:** `plus`, `minus`, `list`, `clock` and `target` were copied from the web's icon set into `lib/ui/art.dart`.
  - **Entry point:** `main.dart` gains `run({overrides})` so the integration test can replace the gallery with a generated image; `main()` calls `run()`.
  - **Defect found by V-MAN-1, fixed:** `photoUploaderProvider` resolved in the root Riverpod container, where `apiProvider` isn't overridden, so the first photo upload threw. `main.dart` now overrides it next to `apiProvider`.
  - **Defect found by V-MAN-1, fixed (pre-existing, S7):** the socket never sent the bearer token, so the API treated every phone as anonymous and refused `host:` (and `plan:`) topics. Live attendance didn't update, and S7's Plan statuses updated only on refetch. `ChannelSocket` now connects with `Authorization: Bearer`, and `RealtimeClient.reconnect()` runs when the session changes.
  - **Places sessions** use a UUID v4 token, as Places API (New) recommends.


# Planning: S3 Realtime

- **Spec ID:** 2026-11-04_11-42_s3-realtime
- **Created:** 2026-11-04 11:42 (local)
- **Status:** Implemented (2026-11-04)
- **Phase:** 3, Realtime and invites (`ROADMAP.md`), alongside S4
- **Parent:** `spec/2026-11-03_07-42_group-bookings-mvp-plan/` (approved), delivery step S3
- **Builds on:** `spec/2026-11-03_22-30_s2-booking-core/` (implemented), `spec/2026-11-03_09-29_s1-foundations/` (implemented)
- **PRD:** `Velio Group Bookings PRD.md`

Claims are tagged **[Verified]** (checked, with a reference), **[Assumption]** or **[Proposal]**.

## 1. Problem statement

The PRD promises that spots left are live: every open client updates within 2 s at p95 of a booking committing, and the activity flips to Sold out the moment the last spot goes (PRD A2, A3, goal "Availability feels live"). S2 already emits a `pg_notify` on every change to `spots_left`, but nothing listens, there is no WebSocket endpoint, and there is no public activity snapshot for a client to start from or fall back to. The latency goal can't be measured yet either.

## 2. Context and current behavior

- [Verified, `apps/api/src/modules/bookings/engine.ts`, `notifySpots`] Booking, removal and capacity change call `pg_notify('activity_spots', {activityId, spotsLeft, version, committedAt})` as the last statement of their transaction. `committedAt` is `clock_timestamp()`. `version` increments on every change.
- [Verified, `apps/api/src/config.ts`] `DATABASE_LISTEN_URL` exists ("Direct (unpooled) connection for LISTEN, used from S3"); `.env.example` and `infra/docker-compose.prod.yml` set it.
- [Verified, `apps/api/src/index.ts`] `Bun.serve` is already given `websocket` from `hono/bun` "so S3 only adds routes". The `server` object is available after `Bun.serve` returns.
- [Verified, `apps/api/src/app.ts`] The Hono app has `basePath('/api')`. Origin verification and the session middleware run on everything under `/api`.
- [Verified, `infra/aws/lib/app-stack.ts`] CloudFront routes both `/api/*` and `/ws` to the API with caching disabled and `ALL_VIEWER_EXCEPT_HOST_HEADER`, which forwards the WebSocket upgrade headers.
- [Verified, `apps/api/src/modules/identity/middleware.ts`] Sessions are read from `Authorization: Bearer` (mobile) or the `velio_session` cookie (web). A browser sends the cookie on a same-origin WebSocket upgrade.
- [Verified, S2 PLANNING §4.5] `GET /api/activities/:id` (the public snapshot) was left to S3.
- [Verified, Maps spec REQUIREMENTS FR-014] The snapshot returns `location { placeId, venueName, addressText, lat, lng, meetingPoint, staticMapUrl, directionsUrl }`. `staticMapUrl` needs the Google Static Maps signing secret, which is not configured yet [Verified, `config.ts` has no Maps settings; S10 PLANNING lists the Maps secrets as "the first spec that uses Maps"].
- [Verified, `apps/api/src/modules/identity/people.ts`] `toPublicPerson` gives the public name form ("Tunde A.") required on public surfaces (PRD Q12, parent SEC-012).
- [Verified, MVP plan §4.5, §4.12] The protocol, latency measurement and realtime metric names are already designed. This spec turns them into checkable requirements.

## 3. Desired outcome

- `GET /api/activities/:id` returns a public snapshot including `spotsLeft` and `version`, so a client can start, reconnect or poll from it.
- A WebSocket endpoint lets any client subscribe to an activity and receive versioned `spots` events. Plan members and the host also receive change hints for their Plan and attendance views.
- One `LISTEN` connection per API instance turns Postgres notifications into WebSocket messages. A notification is delivered only if its transaction commits (PRD NFR live availability).
- Clients send a render acknowledgement, and the server measures commit-to-ack latency on its own clock (MVP plan §4.5). The PRD's p95 ≤ 2 s target can be read from `realtime_commit_to_ack_seconds`.
- A dropped listener or socket never leaves a client silently stale: the server sends `resync`, and the protocol requires clients to fetch the snapshot again and poll every 10 s while disconnected (PRD R3).
- **Proof:** integration tests in `bun test` connect real WebSockets to the real server and Postgres. A k6 `viewers` smoke holds 250 sockets (5% of the 5,000 target) on one activity while `last_spot_race` runs.

## 4. Proposed solution

### 4.1 Module layout [Proposal]

```text
apps/api/src/modules/
  activities/
    snapshot.ts    # buildSnapshot(db, activityId, viewer?) → PublicActivity (S4's invite view reuses it)
    routes.ts      # + GET /activities/:id
  realtime/
    listener.ts    # one LISTEN connection; parses and validates payloads; reconnect → resync
    gateway.ts     # GET /api/ws upgrade, subscribe/unsubscribe, topic authorization, acks
    topics.ts      # topic names and per-topic authorization
    acks.ts        # recent (activityId, version) → committedAt, per process
    metrics.ts     # realtime instruments
  bookings/
    engine.ts      # + notifyPlan(tx, planId) on booking and removal
packages/contracts/src/
  activities.ts    # + PublicActivity
  realtime.ts      # client and server message schemas, topic grammar
```

Bun-only APIs (`ServerWebSocket`, `server.publish`) stay inside `modules/realtime` and `index.ts` (MVP plan §8).

### 4.2 Activity snapshot: `GET /api/activities/:id`

Public: no session needed (Kofi isn't signed in). With a session, it adds the viewer's own state.

```ts
PublicActivity {
  id, title, description, photoUrl: string | null,      // photo upload is S5; null until then
  startsAt, timezone, priceMinor, currency,
  capacity, spotsLeft, version,
  status: 'open' | 'sold_out' | 'started',              // started wins over sold_out
  bookingsPaused: boolean,
  host: PublicPerson,
  community: { slug, name },
  members: { count, preview: PublicPerson[] },          // confirmed bookings, earliest first, at most 8 [Proposal]
  location: { placeId, venueName, addressText, lat, lng, meetingPoint,
              staticMapUrl: string | null, directionsUrl },
  viewer: { isHost: boolean, booking: { id, planId, status } | null } | null   // null when signed out
}
```

- `spotsLeft`, `version`, `capacity` and `status` come from **one row read**, so the version always matches the count. The member preview is a second query and may be one booking newer or older; the next event or refetch corrects it [Proposal].
- `directionsUrl` is the Google Maps URL `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>&destination_place_id=<placeId>` [Assumption: current Maps URLs format, checked at implementation]. No key or secret is needed.
- `staticMapUrl` is `null` in S3 (see §12, Q1). Clients already handle a missing map (PRD A7).
- `Cache-Control: no-store`. A 404 envelope for an unknown ID.
- People appear only as `PublicPerson` (parent SEC-012). Contact details never appear.

### 4.3 WebSocket endpoint: `GET /api/ws`

- **Path** [Proposal; departs from MVP plan §4.8, which names `/ws`]: `/api/ws` sits inside the Hono app, so origin verification, request IDs and the session middleware apply with no extra wiring, and CloudFront already routes `/api/*` to the API with the right policy. The `/ws` behavior stays in the CDK stack, unused; S5 can remove it.
- **Upgrade** through `upgradeWebSocket` from `hono/bun`. Query: `platform` ∈ `web | ios | android` (required; it labels metrics) and `resume=1` when the client is reconnecting.
- **Identity:** the session from the upgrade request (cookie or bearer), resolved once at connect and kept for the socket's life. Anonymous sockets are allowed and can subscribe to activity topics only.
- **Keep-alive:** the server sends a WebSocket ping every 30 s (MVP plan §4.11, parent NFR-009). Bun's `idleTimeout` is set above that [Assumption: Bun's `sendPings`/`idleTimeout` semantics and CloudFront's WebSocket idle timeout are checked at implementation and recorded].
- **Limits** [Proposal; engineering limits, not product rules]: inbound messages at most 4 kB (`maxPayloadLength`); at most 20 subscribed topics per socket; a malformed message gets `{type:"error", code:"validation_failed"}` and the socket stays open; more than 20 malformed messages closes it with code 1008.
- **Shutdown:** on `SIGTERM` the server closes every socket with code 1012 (service restart) before stopping, so clients reconnect at once and poll in between.

### 4.4 Topics and authorization

| Topic | Who can subscribe | Events |
| --- | --- | --- |
| `activity:<id>` | Anyone, including anonymous sockets | `spots` |
| `plan:<id>` | A user with a booking (any status) in that Plan | `plan` |
| `host:<activityId>` | The activity's host | `attendance`, `spots` |

- Authorization runs once at subscribe, against the database. A rejected subscribe returns `{type:"error", code:"forbidden" | "not_found", topic}` and changes nothing.
- A removed member keeps Plan access, so they see "The host removed this booking" live (PRD Host removal).
- Topic names map one-to-one to Bun pub/sub topics, so `server.publish(topic, msg)` reaches every subscribed socket on that instance (MVP plan §4.5).

### 4.5 Messages (`packages/contracts/src/realtime.ts`)

**Client → server:**

| Message | Meaning |
| --- | --- |
| `{type:"subscribe", topics: string[]}` | Subscribe; answered with `subscribed` or one `error` per rejected topic |
| `{type:"unsubscribe", topics: string[]}` | Unsubscribe |
| `{type:"rendered", activityId, version}` | The client has painted this version (latency ack) |

**Server → client:**

| Message | When |
| --- | --- |
| `{type:"subscribed", topics}` | After a subscribe |
| `{type:"spots", activityId, spotsLeft, version, committedAt}` | Every `activity_spots` notification, on `activity:<id>` and `host:<id>` |
| `{type:"plan", planId}` | Something in the Plan changed: a member joined or was removed (S3), an invite was created, opened or claimed (S4). The client fetches the Plan again |
| `{type:"attendance", activityId}` | A booking, removal or capacity change on the host's activity, or an attendance mark (S4). The host view fetches the list again |
| `{type:"resync"}` | The server may have missed notifications (§4.6). The client fetches every snapshot it shows again |
| `{type:"error", code, topic?}` | A rejected subscribe or malformed message |

- `plan` and `attendance` are **hints** with no payload beyond the ID, because Plan and attendance responses depend on who is asking (names by audience, PRD Q12, D5). The client refetches through the authorized REST endpoint.
- **Client rules** (normative for S5, S6 and S7; parent NFR-006): ignore a `spots` event whose `version` ≤ the version shown; on connect or reconnect, subscribe first and then fetch the snapshot, so no event falls between them; while disconnected, poll the snapshot every 10 s; on `resync`, refetch.

### 4.6 Listener (`realtime/listener.ts`)

- One postgres.js connection on `DATABASE_LISTEN_URL`, outside the Kysely pool, running `LISTEN activity_spots`, `LISTEN plan_changed` and `LISTEN attendance_changed` [Verified, MVP plan §5: postgres.js supports `LISTEN`; Assumption: its automatic re-`LISTEN` after a reconnect works on Bun, checked by V-RT-7].
- Each payload is parsed and validated with the contract schema. An invalid payload is logged (channel only) and dropped.
- `activity_spots` → `spots` on `activity:<id>` and `host:<id>`, plus `attendance` on `host:<id>`. Capacity edits also send `attendance`; it costs the host one extra fetch.
- `plan_changed` → `plan` on `plan:<id>`.
- `attendance_changed` → `attendance` on `host:<activityId>`. S4 sends it when a host marks attended or no-show, which doesn't change spots.
- **Reconnect:** when the listen connection drops and comes back, the server publishes `resync` to every topic that has subscribers on that instance. Notifications sent while it was down are lost (`NOTIFY` isn't durable, MVP plan §4.2), so clients must refetch.
- **Readiness:** `/api/readyz` returns 503 while the listener is not listening, so a deploy doesn't report ready without live updates [Proposal].
- **Payload size:** both payloads are well under Postgres's 8,000-byte limit [Verified, MVP plan §4.2].

### 4.7 Plan notifications (`bookings/engine.ts`)

- `notifyPlan(tx, planId)` runs `pg_notify('plan_changed', json {planId})`.
- Called in the booking transaction (the booking's Plan) and the removal transaction (the removed booking's Plan), after `notifySpots`. A direct booking creates its Plan, so nobody is subscribed yet; the notification is harmless.
- S4 calls the same helper on invite creation, first open, claim and pause.
- `notifyAttendance(tx, activityId)` runs `pg_notify('attendance_changed', json {activityId})`. S3 adds the helper and its listener; S4 calls it from attendance marking.
- Postgres delivers notifications in commit order [Verified, MVP plan §4.2].

### 4.8 Latency measurement (`realtime/acks.ts`)

MVP plan §4.5; PRD Success metrics, "Availability feels live".

- When the listener publishes a `spots` event, it records `(activityId, version) → committedAt` in a per-process map with a 60 s lifetime [Proposal].
- On `{type:"rendered", activityId, version}` from a socket subscribed to that activity, the server records `realtime_commit_to_ack_seconds{platform}` = server receive time − `committedAt`.
- Each socket counts at most once per `(activityId, version)`. Acks for unknown or expired versions, or from sockets not subscribed to the activity, are ignored and counted in `realtime_acks_ignored_total`.
- **Clock:** `committedAt` is the database's clock and the receive time is the API's. Both run on the same EC2 instance (MVP plan §4.11), so skew is negligible. The measure includes the ack's return trip, so it overstates latency slightly: a conservative upper bound (MVP plan §4.5).
- **Multiple instances:** each instance records only the versions its own listener published, which is every version, since every instance listens.

### 4.9 Realtime metrics (`realtime/metrics.ts`)

MVP plan §4.12. Labels only as listed; never activity, plan, user or topic IDs.

| Instrument | Type | Labels |
| --- | --- | --- |
| `realtime_commit_to_ack_seconds` | histogram | `platform` |
| `realtime_notify_lag_seconds` | histogram | none. Listener receive time − `committedAt` |
| `realtime_open_sockets` | observable gauge | `platform` |
| `realtime_reconnects_total` | counter | `platform`. Connections with `resume=1` |
| `realtime_events_published_total` | counter | `type` (`spots`, `plan`, `attendance`, `resync`) [Proposal] |
| `realtime_acks_ignored_total` | counter | none [Proposal] |
| `realtime_listener_reconnects_total` | counter | none [Proposal] |

Grafana dashboards and the p95 > 2 s alert are S8 (MVP plan §7).

### 4.10 Tests and the k6 smoke

**`bun test`** (real server on an ephemeral port, real Postgres, real WebSockets with Bun's client):

- Snapshot shape, public names, viewer field, status order, 404.
- A booking, removal and capacity change each produce one `spots` event with the committed `spotsLeft` and `version` on every subscribed socket, and nothing on unrelated topics.
- A rolled-back booking (sold out, already booked) produces no event.
- Versions arrive strictly increasing per activity under 50 parallel bookings.
- Topic authorization: anonymous → plan and host topics rejected; non-member, non-host rejected; member and host accepted.
- `plan` hint on booking-into-Plan and removal; `attendance` hint to the host.
- Ack: 100 sequential bookings, each acked by a test client → 100 samples in `realtime_commit_to_ack_seconds`, p95 ≤ 2 s (parent AC-004). Duplicate and unknown acks ignored.
- Listener restart: terminate the listen backend with `pg_terminate_backend` → `resync` reaches subscribed sockets, and later bookings still produce events.
- Shutdown closes sockets with 1012.

**k6 `viewers` smoke** (MVP plan §4.13, at 5%): 250 WebSocket VUs subscribe to one seeded activity, then `last_spot_race` runs against it. Each VU checks that versions only increase and records receive time − `committedAt`. Thresholds: p95 ≤ 2 s; zero version regressions; every socket sees the final `spotsLeft = 0`. One command: `bun run load:viewers`.

## 5. Architectural considerations

- **Correctness:** realtime stays a hint (MVP plan §4.1, principle 3). Nothing a socket sends can change bookings. A lost event delays a screen; the database still decides.
- **Security:** plan and host topics are authorized against the database at subscribe time. Events never carry names, contacts, codes or booking references. The WebSocket upgrade goes through the same origin check as REST.
- **Privacy:** `spots` events carry only public data. `plan` and `attendance` carry only an ID, and the content comes from audience-aware REST endpoints.
- **Performance:** one `server.publish` per topic per event, done natively by Bun. At 5,000 viewers on one activity that's 5,000 small frames per booking, which S9 measures. The snapshot is two indexed queries.
- **Scaling:** every instance listens and republishes, so the design already works with more than one instance (MVP plan §4.2). The Redis adapter stays the upgrade path.
- **Operations:** a deploy restarts the single instance (accepted, MVP plan §4.11). Sockets close with 1012, clients poll, and readiness waits for the listener.
- **Accessibility:** no UI in S3. The polite, throttled announcement of spots changes is a client rule (parent NFR-005) for S5–S7.

## 6. Components and files affected

| Path | Change |
| --- | --- |
| `apps/api/src/modules/activities/{snapshot,routes}.ts` | Snapshot builder and `GET /activities/:id` |
| `apps/api/src/modules/realtime/*` | New: listener, gateway, topics, acks, metrics |
| `apps/api/src/modules/bookings/engine.ts` | `notifyPlan` in booking and removal |
| `apps/api/src/modules/health/routes.ts` | Readiness includes the listener |
| `apps/api/src/app.ts`, `src/index.ts` | Mount the WS route; pass the Bun server to the gateway; start and stop the listener; close sockets on shutdown |
| `packages/contracts/src/{activities,realtime,index}.ts` | `PublicActivity`, realtime message schemas |
| `packages/contracts/openapi.json` | Regenerated (snapshot route; the WS upgrade is documented as a route with its message schemas as components) |
| `apps/api/test/realtime/*.test.ts`, `test/activities/snapshot.test.ts`, `test/helpers/` | New tests; a WebSocket test client helper |
| `load/scenarios/viewers.js`, `load/seed.ts` | `viewers` smoke; seed one activity for it |
| `package.json` (root) | `load:viewers` script |
| `README.md`, `CHANGELOG.md`, `ROADMAP.md` | Docs |

**No migration.** **No new npm dependencies** [Proposal]: postgres.js already supports `LISTEN`, and `hono/bun` provides the upgrade.

## 7. Implementation phases and ordered tasks

| # | Task | Verified by |
| --- | --- | --- |
| T1 | Contracts: `PublicActivity`, realtime messages, topic grammar | V-CON-1 |
| T2 | Snapshot builder and `GET /api/activities/:id` | V-SNAP-1…4 |
| T3 | Listener with payload validation, reconnect and `resync` | V-RT-1, V-RT-7 |
| T4 | Gateway: upgrade, identity, subscribe/unsubscribe, topic authorization, limits, pings, shutdown | V-RT-2…4, V-RT-8, V-RT-9 |
| T5 | `notifyPlan` in the engine; `plan` and `attendance` hints | V-RT-5 |
| T6 | Ack measurement and realtime metrics | V-RT-6, V-OBS-1 |
| T7 | Readiness includes the listener | V-RT-10 |
| T8 | k6 `viewers` smoke and `load:viewers`; run it | V-K6-1 |
| T9 | OpenAPI regeneration, README, full CI command set locally | V-CI-1 |
| T10 | Record results; CHANGELOG, ROADMAP | Part B |

## 8. Dependencies and prerequisites

- S2 implemented [Verified, ROADMAP]. Local Compose Postgres.
- Docker for the k6 image (`grafana/k6:2.3.0` is already pinned [Verified, `infra/docker-compose.yml`]; it is bumped if a newer stable release exists at implementation time).
- No AWS, Grafana Cloud or Google Maps work is required. After the user deploys, the realtime metrics reach Grafana Cloud through the existing collector.
- S4 depends on this spec's snapshot builder and `notifyPlan` (S4 PLANNING §8). **Recommended order: implement S3, then S4.**

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| A notification lost while the listener reconnects | `resync` to every live topic on reconnect; client polling while disconnected (R3) |
| A client applies an event older than its snapshot | Subscribe before the snapshot fetch, and the version rule (§4.5) |
| CloudFront drops idle sockets | 30 s server pings; the timeouts are checked and recorded at implementation (§4.3) |
| The listener connection goes through a pooler later | Config comment and README state `DATABASE_LISTEN_URL` must be direct (MVP plan §4.2) |
| Fan-out to 5,000 sockets on one `t4g.small` is too slow | Measured in S9. Bun publishes natively; the Redis adapter or more instances are the path |
| Ack spoofing inflates or deflates the latency metric | Acks count only for versions this instance published, once per socket, from subscribed sockets. It's a health metric, not a security boundary |
| postgres.js `LISTEN` behaves differently on Bun | V-RT-7 kills the backend and checks recovery; fallback is a manual reconnect loop in `listener.ts` |
| Snapshot under polling load (5,000 × every 10 s while sockets are down) | Two indexed queries; S9 measures it; a lighter state endpoint is the fallback [Proposal] |

## 10. Alternatives considered

- **Server-sent events:** simpler and cache-friendly, but the protocol needs client → server acks and subscriptions, and Flutter's WebSocket support is mainstream.
- **Full Plan and attendance payloads over the socket:** fewer requests, but every message would need per-recipient filtering for names by audience. Hints keep the authorized REST endpoints as the only source.
- **One topic per socket (connect per activity):** simpler, but the host and Plan screens need several topics at once.
- **Mount the socket at `/ws` outside the Hono app:** matches the MVP plan's path, but would duplicate origin verification and session resolution. Rejected in favour of `/api/ws`.

## 11. Estimated complexity

Medium (MVP plan §7). Most of the risk is in T3 and T4 (reconnects and lifecycle).

## 12. Assumptions and open questions

**Open questions (answers change scope):**

1. **Q1: Does S3 sign Static Maps URLs?** **Decided 2026-11-04: no, as recommended.** The snapshot's `staticMapUrl` needs the owner's Google Cloud project and a signing secret, which don't exist yet. The first screen that shows a static map is the web invite page (S6). **Recommendation:** S3 returns `staticMapUrl: null` and a working `directionsUrl`. Signing, the secret and the budget alert move to S6, or to S5 if S5 starts first.
2. **Q2: Socket path.** **Decided 2026-11-04: `/api/ws`.** **Recommendation:** `/api/ws` (§4.3) instead of the MVP plan's `/ws`. This is a small departure from MVP plan §4.8, recorded here and in the change log once you decide.

**Assumptions:**

- The member preview shows at most 8 people (an engineering choice for the avatar stack, not a product rule; the UI design shows "+n going").
- The 20-topic and 4 kB limits (§4.3) are engineering limits.
- Bun's ping settings and CloudFront's WebSocket idle timeout are checked at implementation.
- The ack window of 60 s covers any client that renders within the PRD's 2 s target, with margin.
- No message is sent at an activity's start time; clients derive "started" from `startsAt`.

## 13. Related specs and PRD sections

- PRD: A2, A3, A7 (maps never block), goal "Availability feels live", NFR live availability, Edge cases ("Live connection drops"), R3, Q4, Q12.
- MVP plan §4.1 (principle 3), §4.2, §4.5, §4.8, §4.11, §4.12, §4.13; parent FR-002, FR-003, NFR-003, NFR-006, NFR-009, AC-004.
- S2 booking core (engine, `notifySpots`). Google Maps spec FR-014.
- Next: S4 (uses the snapshot and `notifyPlan`), S5–S7 (implement the client rules), S8 (dashboards and alert), S9 (5,000-viewer run).

## 14. Change log

- 2026-11-04 11:42: created.
- 2026-11-04: open questions answered by the user. Q1: S3 returns `staticMapUrl: null` and a working `directionsUrl`; Static Maps signing, its secret and the budget alert move to S6 (or S5 if it starts first). Q2: the socket is at `/api/ws`, departing from MVP plan §4.8 (`/ws`). Also, because S4 now owns attendance marking (S4 PLANNING §12, Q3), the listener adds a third channel, `attendance_changed`, and S3 exports `notifyAttendance` (§4.6, §4.7). Status stays In review until the spec is approved.
- 2026-11-04: **approved for implementation** by the user. Implementation starts with this spec; S4 follows.
- 2026-11-04: **implemented.** Results are in `VALIDATION.md` Part B. Changes made during implementation, all within the approved scope:
  - **WebSocket handling (§4.3).** Bun's handler is used directly instead of `hono/bun`'s `upgradeWebSocket`, which Hono 4.13 marks deprecated and which hides Bun's pub/sub topics. `realtime.attach(server)` gives the gateway the Bun server for upgrades and publishing. The route stays in the Hono app.
  - **Listener (§4.6).** postgres.js's `listen()` re-subscribes once after a drop and silently stops if that fails, so the listener runs `LISTEN` on its own one-connection client (using postgres.js's `onnotify` and `onclose` hooks) and retries with backoff from 250 ms to 5 s until it succeeds.
  - **Notify helpers.** `notifySpots` moved from the engine to `modules/realtime/notify.ts`, beside `notifyPlan` and `notifyAttendance`, so the channel names live in one place. The engine still calls it in the same place.
  - **Frame limit (§4.3).** Bun's `maxPayloadLength` is 64 kB, because Bun closes larger frames with 1009 before the app sees them. The 4 kB limit is checked by the app and answered with `validation_failed`, as FR-014 says.
  - **Backpressure.** A socket over 1 MB of unsent data is closed (`closeOnBackpressureLimit`), so a slow client reconnects and refetches instead of silently missing events.
  - **Histogram buckets.** `realtime_commit_to_ack_seconds` and `realtime_notify_lag_seconds` declare boundaries from 10 ms to 10 s. The SDK defaults (0, 5, 10, …) would put every sample in one bucket.
  - **k6.** `load/seed.ts viewers` seeds one 14-spot activity; `load/check.ts` takes the seed file as an argument. The pinned `grafana/k6:2.3.0` provides `k6/websockets` and `k6/timers`, so no image change was needed.

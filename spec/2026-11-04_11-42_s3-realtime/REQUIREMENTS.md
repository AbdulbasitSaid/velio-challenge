# Requirements: S3 Realtime

## Purpose and scope

The public activity snapshot, the WebSocket gateway, the Postgres `LISTEN` bridge, versioned events, Plan and attendance change hints, render acknowledgements for latency, realtime metrics and a k6 `viewers` smoke. Parent IDs refer to `spec/2026-11-03_07-42_group-bookings-mvp-plan/REQUIREMENTS.md`. Design: `PLANNING.md` in this directory.

## Goals and non-goals

- **Goals:** every committed change to spots left reaches every subscribed socket, in version order; commit-to-render latency is measurable against the PRD's p95 ≤ 2 s; a client always has a way back to fresh data (snapshot, resync, polling).
- **Non-goals:** client implementations of the protocol (S5, S6, S7); Plan, attendance, invite and My plans REST endpoints (S4, S5); Static Maps signing (PLANNING §12, Q1); dashboards and alerts (S8); the 5,000-viewer run (S9); a Redis adapter.

## Functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-001 | `GET /api/activities/:id` is public and returns `PublicActivity` (PLANNING §4.2): details, `capacity`, `spotsLeft`, `version`, `status`, `bookingsPaused`, host and member preview as `PublicPerson`, member count, community, `location` with `directionsUrl` and `staticMapUrl` (null in S3), and `viewer` (null when signed out). Unknown ID → `404 not_found`. Response carries `Cache-Control: no-store`. | PRD A2, A5; Maps FR-014; MVP plan §4.8 |
| FR-002 | `spotsLeft`, `version`, `capacity` and `status` in one snapshot come from a single read of the activity row. | Parent NFR-006 |
| FR-003 | `status` is `started` when the start time has passed, otherwise `sold_out` when `spotsLeft = 0`, otherwise `open`. | PRD A3, Lifecycles |
| FR-004 | `viewer` (signed in) gives `isHost` and the caller's own booking on the activity (`id`, `planId`, `status`) or null. | PRD Edge cases ("Already booked", "Host removed the booking") |
| FR-005 | `GET /api/ws` upgrades to a WebSocket. `platform` (`web`, `ios`, `android`) is required; `resume=1` is optional. The session cookie or bearer token on the upgrade request identifies the user; without one the socket is anonymous. | MVP plan §4.5, §4.6; PLANNING §4.3 |
| FR-006 | Clients subscribe and unsubscribe to topics `activity:<id>`, `plan:<id>` and `host:<activityId>` with the messages in PLANNING §4.5. Each subscribe gets `subscribed` or an `error` per rejected topic. | MVP plan §4.5 |
| FR-007 | Anyone can subscribe to `activity:<id>` for an existing activity. `plan:<id>` needs a booking of any status in that Plan. `host:<activityId>` needs the caller to be the host. Otherwise `forbidden` (or `not_found` for an unknown ID). Authorization is checked against the database at subscribe time. | PRD Q12, D5; parent SEC-012 |
| FR-008 | Every `activity_spots` notification produces one `{type:"spots", activityId, spotsLeft, version, committedAt}` message on `activity:<id>` and `host:<id>`, and one `{type:"attendance", activityId}` on `host:<id>`. | PRD A2, A3; parent FR-002, FR-003 |
| FR-009 | A booking and a host removal also emit `pg_notify('plan_changed', {planId})` in their transaction, and each `plan_changed` notification produces `{type:"plan", planId}` on `plan:<id>`. `notifyPlan` is exported for S4. Each `attendance_changed` notification (`notifyAttendance`, exported for S4's attendance marks) produces `{type:"attendance", activityId}` on `host:<activityId>`. | PRD L1 (live invite status), Notifications in MVP |
| FR-010 | No message is sent for a transaction that rolls back. | PRD NFR live availability |
| FR-011 | For one activity, the `version` values a socket receives strictly increase. | Parent NFR-006 |
| FR-012 | When the listener's connection drops and recovers, the server sends `{type:"resync"}` to every topic with subscribers on that instance. | PRD R3 |
| FR-013 | A client's `{type:"rendered", activityId, version}` records one `realtime_commit_to_ack_seconds{platform}` sample (server receive time − `committedAt`), at most once per socket per `(activityId, version)`, only for versions this instance published within the last 60 s and only from a socket subscribed to that activity. Other acks are ignored and counted. | PRD Success metrics; MVP plan §4.5; parent NFR-003 |
| FR-014 | Malformed or oversize client messages get `{type:"error", code:"validation_failed"}`; the socket stays open until 20 such messages, then closes with 1008. A socket holds at most 20 topics; further subscribes get `error` with `validation_failed`. Inbound frames are at most 4 kB. | PLANNING §4.3 [Proposal] |
| FR-015 | The server pings every open socket every 30 s. | Parent NFR-009 |
| FR-016 | On shutdown, the server closes every socket with code 1012 before stopping. | PLANNING §4.3 |
| FR-017 | `/api/readyz` returns 503 while the listener isn't listening. | PLANNING §4.6 [Proposal] |
| FR-018 | The protocol's client rules are written into the contracts package as documentation next to the schemas: ignore `spots` with `version` ≤ the shown one; subscribe, then fetch the snapshot, on every connect; poll the snapshot every 10 s while disconnected; refetch on `resync`; refetch the Plan on `plan` and the attendance list on `attendance`. | Parent NFR-006; PRD Edge cases ("Live connection drops") |

## Non-functional requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-001 | In the test environment, p95 of `realtime_commit_to_ack_seconds` over 100 bookings is ≤ 2 s. | Parent AC-004, NFR-003 |
| NFR-002 | The k6 `viewers` smoke (250 sockets on one activity during a `last_spot_race`, against local Compose) shows p95 receive − `committedAt` ≤ 2 s, zero version regressions, and every socket ending on `spotsLeft = 0`. | MVP plan §4.13 (5% of 5,000 viewers) |
| NFR-003 | Metrics `realtime_commit_to_ack_seconds` (`platform`), `realtime_notify_lag_seconds`, `realtime_open_sockets` (`platform`), `realtime_reconnects_total` (`platform`), `realtime_events_published_total` (`type`), `realtime_acks_ignored_total` and `realtime_listener_reconnects_total` exist and carry no other labels. | MVP plan §4.12; CLAUDE.md |
| NFR-004 | The listen connection is one direct connection per instance, outside the query pool. | MVP plan §4.2 |
| NFR-005 | Bun-specific WebSocket APIs are used only in `modules/realtime` and `index.ts`. | MVP plan §8 |
| NFR-006 | The snapshot makes at most two database queries for an anonymous caller and three for a signed-in caller. | PRD NFR performance (invite page on 3G) [Proposal] |

## Use cases

- **Kofi watches** Sunset Kayaking, not signed in. Tunde books in another tab; Kofi's count drops from 3 to 2 within a second.
- **Zainab's bus** goes through a tunnel. Her socket drops; she sees "Reconnecting", polls, and on reconnect subscribes and refetches.
- **The API deploys.** Every socket closes with 1012; clients poll for a few seconds and reconnect.
- **Tunde's Plan** shows a new member the moment Zainab claims (S4 sends the hint through the same channel).
- **Amara's attendance view** refetches when a booking lands or she removes someone.

## Acceptance criteria

- **AC-001:** a booking on one connection updates `spotsLeft` on another connected socket subscribed to the activity, with the committed version.
- **AC-002:** over 100 bookings, each acknowledged by a test client, p95 commit-to-ack ≤ 2 s (NFR-001).
- **AC-003:** after `pg_terminate_backend` on the listen connection, subscribed sockets receive `resync`, and the next booking is delivered.
- **AC-004:** an anonymous socket can't subscribe to a `plan:` or `host:` topic; a non-member can't subscribe to `plan:`; a non-host can't subscribe to `host:`.
- **AC-005:** the k6 `viewers` smoke (NFR-002) passes, with its summary recorded in `VALIDATION.md` Part B.
- **AC-006:** the snapshot of a sold-out activity shows `status: sold_out`; of a started activity, `started`, even when also sold out.

## Business rules and edge cases

- Started wins over sold out in `status` (FR-003).
- A removed member keeps access to their Plan topic, so the removal shows live.
- An activity subscription for an unknown ID is `not_found`.
- No event fires at start time; clients derive "started" from `startsAt`.
- Capacity edits send `spots` (and `attendance` to the host) like any other change to `spots_left`.

## Error handling and failure behavior

- REST errors use the S1 envelope. WebSocket errors use `{type:"error", code, topic?}` with codes from the contracts union.
- An invalid notification payload is logged by channel name only and dropped; it never reaches a client.
- If the listener is down, the API keeps serving REST (bookings stay correct), readiness reports 503, and clients poll.
- A socket that fails to receive (backpressure) is handled by Bun's limits; a closed socket is unsubscribed from every topic.

## Security and privacy

| ID | Requirement | Source |
| --- | --- | --- |
| SEC-001 | The snapshot and every WebSocket message expose people only as `PublicPerson`, and never contact details, invite codes, notes or booking references. `plan` and `attendance` messages carry only an ID. | Parent SEC-003, SEC-012; PRD D5 |
| SEC-002 | Plan and host topics are authorized against the database at subscribe time (FR-007). | PRD business rules (Identity) |
| SEC-003 | The WebSocket upgrade passes the same origin verification as REST in production. | Parent SEC-009 |
| SEC-004 | Metrics, spans and logs carry no user, plan, topic or session identifiers; metric labels carry no entity IDs. Activity IDs may appear on spans and in logs. | CLAUDE.md; parent SEC-011 |

## Performance and reliability

NFR-001, NFR-002, NFR-006. The 5,000-viewer run at 10× peak is S9 (parent NFR-007).

## Compatibility constraints

- Contracts additions are backwards-compatible.
- Socket path `/api/ws` (decided 2026-11-04, PLANNING §12, Q2). The CDK `/ws` behavior is left in place.
- Browser WebSocket clients send cookies on same-origin upgrades; Flutter sends `Authorization: Bearer` on the upgrade [Assumption: `web_socket_channel` supports upgrade headers on iOS and Android, checked in S7].

## Data and migration

No migration. No new tables. The ack map is in memory per process.

## Dependencies and integrations

S2 (engine, `notifySpots`). postgres.js `LISTEN`. `hono/bun` `upgradeWebSocket`. k6 (`k6/websockets`) [Assumption: module name for the pinned k6 release, checked at implementation].

## Explicitly excluded

Client code for the protocol; Plan, attendance, invite and My plans endpoints; Static Maps signing; Redis; dashboards and alerts; the full-scale viewers run; messages at activity start time; push notifications.

# NEXT: what I'd have done with more time

The work below was cut for time, not by choice. It's ranked by what it protects for users, most important first, and each item says how I'd know it's done. Product growth work (waitlist, vouch hold, push) is in [`PLANS.md`](PLANS.md) (1c, "48 hours vs. next") and in [`OWNERSHIP.md`](OWNERSHIP.md).

## 1. Prove the SLOs at real load (S9, specified, not built)

The S9 spec is [`spec/2026-11-05_10-01_s9-hardening/`](spec/2026-11-05_10-01_s9-hardening/). It's written but not implemented.

| Item | Why it matters | Done when |
| --- | --- | --- |
| Full k6 suite at 10× assumed peak: 500 bookers on one activity within 10 s, 5,000 live viewers, steady booking mix, invite claims, browse, 30-min soak | Only 5% smoke loads have run (25 VUs per activity, 250 sockets). A Friday-night sell-out is exactly when Amara needs the count to hold. | Exactly N bookings at 500 VUs; socket p95 ≤ 2 s at 5,000 viewers (or the instance's ceiling found and recorded); a baseline on file |
| A temporary spot EC2 load runner in eu-west-2 (CDK stack) | Laptop runs measure the home connection, not the system | Deployed, run, destroyed; no instance left |
| Keep load-test data out of product metrics (a test-community flag, filtered views) | Insert-only tables can't be cleaned up, so a load run on production would distort the admin page | `/admin` reads the same before and after a run |

## 2. Make sure everyone can use it

| Item | Why it matters | Done when |
| --- | --- | --- |
| Playwright E2E for host, booker, guest and live sell-out, in CI | 226 web component tests and 293 Flutter tests exist, but no browser test runs a whole flow on every push | The suite passes in CI and once on the deployed stack |
| Accessibility pass: axe in Playwright, a keyboard-only run, VoiceOver and TalkBack | The PRD requires WCAG AA and polite spots-left announcements; no audit has run | No serious or critical violations; screen-reader checks recorded |
| Lighthouse on the invite and activity pages after the latest changes | Zainab arrives on 3G; the < 1.5 s first-content budget was last measured on 4 Nov | FCP < 1.5 s on the mobile preset |
| Fix the invite-open beacon's `503` through CloudFront on full page loads | The open is still recorded and users see nothing, but it adds 5xx noise to the dashboards | No `503` in three full loads |
| Run the Flutter community-map preview on a device | It's built and unit-tested, but has never run on a simulator or phone | Cards, pins and swipes behave on a device |

## 3. Before real users (general availability)

| Item | Why it matters |
| --- | --- |
| **Real authentication** (verified email or phone) | Today anyone can "continue as" any contact (SEC-008). Acceptable for a prototype, not for people's Plans. |
| **Encrypted CloudFront → origin hop** (CloudFront VPC origin or TLS on the instance) | The origin is locked to CloudFront with a secret header, but that hop is HTTP (SEC-009) |
| **iOS Universal Links and app distribution** (Apple Developer account, TestFlight, Play internal track) | iOS guests land on the web page or type a code; the app isn't installable outside a cabled build |
| **Native maps keys** for the app | Without them the app shows the address and directions, not a map |
| **Live kill switch** (a realtime "activity changed" event) | Pausing bookings works at once, but open pages only show it on their next load |
| **Headless-browser filtering on the open beacon** | Headless Chrome counted as an open in testing, which inflates the denominator of the 25% goal |
| **Count a claim as an open when its beacon never arrived** | Claims made without a recorded open (blocked or failed beacon, or API-only scripts) inflate open-to-claim. Locally, scripted claims push vouch past 100%. The view should count only claims on invites that were opened, or treat a claim as implying an open. |

## 4. Scale and operations

| Item | Trigger to do it |
| --- | --- |
| Move from one EC2 instance to Fargate + RDS (Multi-AZ) | Before GA; the single instance is an accepted single point of failure for the prototype |
| Redis pub/sub adapter behind the realtime interface | Notifying commits in the hundreds per second sustained, or a connection pooler introduced |
| Per-activity booking queue (R2's fallback) | The 10× load test shows row-lock wait dominating booking p95 |
| Make the local concurrency test reliable | 200 parallel connections sometimes hit `ECONNREFUSED` on macOS; it passes in CI and with k6, so it's a local socket limit, not a booking bug |
| A real domain | Shared links are tied to the `cloudfront.net` hostname; keep the old one serving if a domain is added |

## 5. Product next (from the plans)

In PRD order:

1. Waitlist and booker cancellation together, with 24 h reminders and "can't make it".
2. Vouch spot hold, only if sell-out loss exceeds 10% of vouch opens.
3. Push notifications when a friend claims.
4. Host payouts once payments are in scope.

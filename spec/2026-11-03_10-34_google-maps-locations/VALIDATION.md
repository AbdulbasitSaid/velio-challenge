# Validation: Google Maps locations

## Part A: Planned checks

### Spec review checklist

- [ ] Every FR, NFR, SEC and AC maps to a check below.
- [ ] PRD amendments (A1 amended, A4–A7) approved by the owner before the PRD is edited.
- [x] OQ-1 to OQ-3 answered (MAP-D4 to MAP-D6, 2026-11-03).
- [ ] S1 schema amended to match §5.1 before S1 is approved.
- [ ] Every map screen and state is designed in `spec/2026-11-03_10-34_complete-ui-design/`.

### Traceability

| Requirement | Check | Delivery spec |
| --- | --- | --- |
| FR-001, FR-002, FR-003, FR-004 | Playwright: picker search, pin drag, pin without place, validation (AC-001, AC-002) | S5 |
| FR-005 | API integration test: location edit after booking returns `location_locked`; DB check constraint test (AC-003) | S1/S2, S5 |
| FR-006 | Playwright on B1: static map, text, directions link, map loads on tap | S5 |
| FR-007, NFR-001, NFR-002 | Lighthouse 3G profile; network log shows no Maps JS; CLS = 0 from the map (AC-004) | S6 |
| FR-008 | Playwright on G4 and B4; Flutter widget tests | S5, S6, S7 |
| FR-009 | Flutter integration test on iOS and Android devices (AC-007) | S7 |
| FR-010 | Playwright on C1: markers, clustering, sold-out excluded (AC-006) | S5 |
| FR-011 | Manual: directions open on iOS (Apple or Google) and Android | S6, S7 |
| FR-012, FR-013 | Playwright with Google domains blocked (AC-005); Flutter offline test (AC-007) | S5, S6, S7 |
| FR-014, FR-015 | Contract test on the snapshot shape; unit test of URL signing | S1/S2 |
| NFR-003 | Playwright network assertions on B1 and C1 | S5 |
| NFR-004 | axe scan; keyboard-only picker walkthrough | S9 |
| NFR-005 | Lockfile and `pubspec.lock` review | S5, S7 |
| SEC-M01 | Manual review of key restrictions and the $10 budget alert (MAP-D5) in Google Cloud console | S10 |
| SEC-M02 | Bundle scan for secret patterns (AC-008); secret only in server config | S6, S7, S10 |
| SEC-M03, SEC-M05 | Copy review against the design | UX, S5 |
| SEC-M04 | Telemetry label review | S8 |

### Proposed tests

- **Unit:** static map URL signing; directions URL building; coordinate range validation.
- **Integration:** activity create and edit with location; lock after booking; snapshot contract.
- **End-to-end:** Playwright picker, activity, invite, community map, blocked-Google fallback; Flutter native map and offline.

### Static analysis

ESLint, `tsc --noEmit`, `dart analyze`, and a secret scan in CI.

### Manual verification

Directions on real iOS and Android devices; key restrictions in the console; budget alert set.

### Preconditions and test data

A seeded activity per community with real coordinates (Nairobi, Arusha, Marrakech). Test keys restricted to `localhost`.

### Expected results

All ACs pass; invite page budget unchanged; no secret in any client artifact.

### Known limitations

The prototype canvas can't call Google Maps, so designs use representative map imagery. Real map rendering is verified in S5–S7.

## Part B: Executed checks

Not run. Filled in after implementation in the delivery specs.

**Final validation status:** Not run.

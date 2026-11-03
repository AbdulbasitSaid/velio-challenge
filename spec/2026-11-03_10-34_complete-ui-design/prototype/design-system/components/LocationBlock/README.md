# LocationBlock

Where the activity is: map, venue, address, meeting point and Get directions.

- **Provide:** `venue`, `address`, `meetingPoint` (optional, ≤ 140 characters), `mapState` (see `MapView`), `title` (default "Where"; `false` hides it), `copy` for a Copy address action.
- "Get directions" opens Google Maps directions; on iOS Flutter it opens a `BottomSheet` to choose Apple Maps or Google Maps.
- Used on B1, G1, G2, G4 and B4 (PRD A5). The address and directions survive every map failure (A7).

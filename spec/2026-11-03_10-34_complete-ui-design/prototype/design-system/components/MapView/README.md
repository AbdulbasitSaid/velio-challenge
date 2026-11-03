# MapView

The map frame for every location surface, with its loading, failed and offline states.

- **Provide:** `state`: `static` (signed static image: invite pages, You're in, Plan on web), `interactive` (Maps JavaScript or the native Flutter map, with zoom), `dragging` (the host picker), `loading`, `failed`, `offline`; plus `venue` for the label, `ratio`.
- **The art here is representative.** Production renders Google Maps with Google's own attribution; do not ship this drawing.
- A map is never the only way to learn the place: pair it with `LocationBlock` text (PRD A7).
- Invite pages use `static` only, lazy-loaded below the fold (Maps NFR-001).

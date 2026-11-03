# LocationPicker

The host's location field: Google place search, a draggable pin, venue, address and meeting point.

- **Provide:** `state`: `empty`, `results` (place suggestions), `pinned` (map with draggable pin, venue, address and meeting point filled), `noresults`, `unavailable` (search down; drop a pin instead); `query`, `results`.
- The venue name and address prefill from the chosen place and stay editable; they are the host's words (Maps MAP-D4).
- Always show the public-location note (Maps SEC-M05). After the first booking, render the fields read-only with `host.locked` copy.
- Used in H2 (PRD A4).

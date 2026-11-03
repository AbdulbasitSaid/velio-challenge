# Banner

Inline messages: information and disclosure, offline, and errors.

- **Provide:** `tone` (`info` · `offline` · `error`), `title`, `children`, optional `action` (a small `Button`).
- `info` carries the claim disclosure (UX FR-006) and the host privacy note. `error` is a `role=alert`; it always says what happened and the next step.

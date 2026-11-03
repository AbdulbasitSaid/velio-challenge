# AttendanceRow

A row on the host's live attendance list: before start it offers Remove, after start attended or no-show.

- **Provide:** `name`, `bookingRef`, `time`, `source` and `sourceLabel`, `mode` (`before` start: Remove; `after`: attended / no-show), `mark`, `isNew` (lime sweep for a live arrival), `removed`.
- The host never sees contact details (PRD D5).
- Remove always goes through `ConfirmDialog` with `host.remove.confirm` copy.

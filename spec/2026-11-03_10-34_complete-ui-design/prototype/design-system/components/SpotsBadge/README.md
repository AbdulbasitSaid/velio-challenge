# SpotsBadge

The live spots-left count: the hero number on every screen that can book.

- **Provide:** `spots` (the server's count) and `state`: `live` (default), `changed` (flash for 1.4 s after a pushed update, then back to `live`), `stale` (socket down; shows "Reconnecting…").
- It derives the rest: 2 or fewer reads "Last 2 spots" / "Last spot" on `forest`; 0 reads "Sold out" on `ink`.
- Under `prefers-reduced-motion` the flash is a fade, not a colour pop.
- It is a polite live region; announce changes at most once every 5 s (UX NFR-003).
- Never show a number older than the last snapshot without the `stale` state.

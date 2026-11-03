# LivePill

Connection state for realtime screens: Live, Reconnecting, Offline.

- **Provide:** `status` (`live` · `reconnecting` · `offline`) and, offline, `minutes` since the last update.
- Sits top-right on invite, activity, Plan and attendance screens (X2). Hide it entirely on screens with no live data.
- Offline pairs with an offline `Banner` when an action is blocked ("Reconnect to claim").

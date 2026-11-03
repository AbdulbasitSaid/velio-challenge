# Avatar

Initials on a palette colour picked from the person's ID: there are no profile photos in the MVP.

- **Provide:** `name` and `seed` (the user's `avatarSeed`). Colour is `palette[hash(seed) % 5]` over `lime`, `sky`, `sun`, `lilac`, `peach`; initials are always `forest` (≥ 9.9:1 on all five).
- Web and Flutter must compute the same colour from the same seed (MVP FR-032).
- Public surfaces pass the public-form name ("Tunde A."); initials come out the same.
- Initials are part of the graphic: they keep their size when the person raises their system text size (Flutter: `TextScaler.noScaling` on the initials). The name next to an avatar does scale.

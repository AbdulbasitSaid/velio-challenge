# MemberRow

A Plan member or invite: name, how they joined, invite status.

- **Provide:** `name` (full display name: Plans are members-only, PRD Q12), `meta`, `source` (`direct` · `vouch` · `public`, with `sourceLabel` "Via Tunde"), `status` for invites (`created` · `opened` · `claimed`), `you`, `removed`, `pending` (an invite with no claimer yet).
- Put rows inside a `.vl-list` container so dividers draw between them.
- "Created" means the link exists, not that it was sent (`plan.createdHelp`).

# TextField

Labelled inputs: text, multiline, search and the 6-character code field.

- **Provide:** `label` (always visible, never placeholder-only), `id`, and `value` or `placeholder`.
- `help` sits under the field; `error` replaces it with a `danger` message and an icon. Write errors as what to do next.
- `code` sets 20px tracked uppercase centred text for invite codes (G8); `search` adds a search icon; `multiline` makes a textarea; `maxLength` with `count` shows "34 / 140".
- Fields are 52px tall, `radius-field`, `field-border` at 1.5px (2px `danger` on error).

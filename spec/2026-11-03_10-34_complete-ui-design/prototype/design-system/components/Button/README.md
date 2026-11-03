# Button

One clear action per screen: a lime primary pill, a forest-outline secondary, and quiet or destructive text buttons.

- **Provide:** `children` (the label, a verb: "Claim my spot", never "OK"), `variant` (`primary` · `secondary` · `quiet` · `destructive` · `danger`), and `onClick` or `href`.
- **States:** `loading` swaps the icon for a spinner, fills `lime-press` and disables the button ("Confirming…"); `disabled` greys it with `disabled` and `muted`.
- `block` makes it full width (phone CTAs); `small` drops to the 44px touch minimum; `icon` takes an `Icon` name.
- **Use one primary per screen.** `danger` (solid `danger` fill) only confirms a destructive action inside `ConfirmDialog`; `destructive` (red text) starts one.
- Never put lime text on cream, and never use lime for a secondary action.

# Item Authoring

How to write an item for `data/items/`. This derives from docs/PROJECT_PLAN.md §1 (Items) and
§4 (Item schema) — those sections are the source of truth if this drifts.

## Authoring template

> **[Attachment]** — *While [stat] is [highest / lowest / above N], [effect].*

Conditional items are the point: an item can be dormant in one permutation and broken in
another. Aim for roughly **50% conditional / 50% unconditional** so builds still ratchet
forward even in a bad permutation.

## Adding an item

1. Create one new `.tres` file in `data/items/`, filename = item id (e.g. `unsent_letter.tres`).
2. Never edit a system to add an item. If an item needs an effect that doesn't exist yet as an
   `ItemEffect` atom, that's a new effect atom — not a special case inside `item.gd` or `ItemDB`.
3. Drop matching art at `assets/sprites/items/{id}.png` (32×32, transparent PNG) yourself —
   Claude Code does not create art. Missing art resolves to a magenta placeholder stamped with
   the id; that's the expected fallback, not a bug.

## Fields

See docs/PROJECT_PLAN.md §4 for the authoritative schema. Summary:

- `id` — also the texture filename (no extension).
- `display_name`, `flavor` (one line, shown on pickup), `rarity` (0 common … 3 mythic).
- `condition_stat` — `""` for an unconditional item, else `"POWER" | "SPEED" | "LUCK"`.
- `condition_mode` — `"highest" | "lowest" | "above" | "below"`.
- `condition_value` — used by `above` / `below` only.
- `effects` — `Array[ItemEffect]`, composable effect atoms.
- `spread_delta` — `+` widens spread, `-` narrows it, `0` neutral.

## Aesthetic

Buddhist/existential core, deliberately muddied with alchemical objects (retorts, sigils,
glassware, the peacock's tail). Whimsy over doctrinal rigor.

## Fiction

Items persist across rifts; stats don't. They're attachments the soul refused to put down.
That's why a conditional item lighting up on the right permutation matters — it's the moment
`EventBus.item_activated` exists to make loud.

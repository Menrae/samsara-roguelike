# Architecture

How systems talk. Update rarely — this describes the shape of the codebase, not the current
task (that's docs/STATE.md). Nothing below exists yet as code; this is the target shape from
docs/PROJECT_PLAN.md, filled in with specifics as systems land.

## Layout

- `src/autoload/` — singletons: EventBus, RunState, ItemDB, KarmaTracker.
- `src/systems/` — labyrinth_gen, rift, stats, combat, loot.
- `src/entities/` — player, enemy, pickup, rift_node.
- `src/ui/` — UI scenes and controllers.
- `src/debug/` — per-system test scenes + debug overlay.
- `data/` — content as data (items, enemies, realms, room templates as `.tscn`). Adding
  content is a new file in `data/`, never an edit to a system.
- `assets/` — human-owned. Claude Code reads paths here, never writes.
- `scenes/` — main, run, menus.

## Cross-system communication

Systems talk **only** through `EventBus` (autoload) signals — no direct cross-system
references. Current signal list (docs/PROJECT_PLAN.md §4):

- `stats_permuted(old_assignment, new_assignment)`
- `item_acquired(item)`
- `item_activated(item)` — dormant → live after a permutation
- `item_deactivated(item)`
- `rift_entered(color, realm)`
- `karma_shifted(delta, source)`
- `enemy_killed(enemy, realm)`
- `player_died(cause)`

`item_activated` / `item_deactivated` get dedicated signals (rather than being inferred from
`stats_permuted` downstream) specifically to drive the "dormant items light up" UI moment —
that's the game's signature payoff.

## Texture resolution

No texture path is ever stored in a `Resource`. Everything resolves by convention from `id`:

- Items: `assets/sprites/items/{id}.png`
- Enemies: `assets/sprites/enemies/{id}.png`
- Realm tiles: `assets/sprites/tiles/{realm}/`
- Rifts: `assets/sprites/rifts/{color}.png`

Missing art returns a magenta placeholder stamped with the id, never a broken or blank sprite.

## Player spritesheet frame order

TBD — document the frame order here once the player spritesheet exists (docs/PROJECT_PLAN.md
§6).

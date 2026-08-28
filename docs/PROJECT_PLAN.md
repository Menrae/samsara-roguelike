# SAMSARA ROGUELIKE — Project Plan

*Working title. Planning document for Claude Code sessions.*

---

## 0. Assumed Stack

**Godot 4.x, GDScript, 2D.**

Rationale, so it can be argued with:

- **Resource files (`.tres`) are text-based and diffable.** An item is a file, not a code entry. Adding 40 items adds 40 files and touches zero logic. This is the single most important property for "don't overwrite working code."
- **Texture import is drag-and-drop.** Drop a PNG into `assets/`, Godot imports it, a path convention picks it up. No build step, no atlas packing required to start.
- **Scenes are composable nodes**, so systems stay physically separate on disk instead of tangled in one file.
- Everything is plain text, so Claude Code can read and diff the whole project including scenes.

If you'd rather work in TypeScript/Phaser or LÖVE, the whole plan transfers — only the file extensions change. Decide before Milestone 0.

---

## 1. Locked Design Decisions

These are settled. Claude Code should treat them as constraints, not suggestions.

### Stats

Three stats: **POWER**, **SPEED**, **LUCK**.

A run holds a **multiset of values** (e.g. `[9, 5, 1]`) and an **assignment** of those values to the three stats. Rifting **permutes the assignment**. The multiset is conserved.

- **POWER** — damage, knockback, hazard resistance.
- **SPEED** — movement, attack rate, i-frame generosity.
- **LUCK** — *generation input.* Read at the moment of labyrinth generation. Higher LUCK means more branches, more rooms, richer item pools, more rift density, more secret doors. Luck is not a drop-rate modifier; it is a worldgen parameter.

**Spread** (the gap between highest and lowest value) is the risk dial. Items may widen or narrow spread. Wide spread = specialized and volatile across rifts. Narrow spread = stable and rift-proof.

### Rifts

Rifts are the core verb. Entering one regenerates the labyrinth and permutes stats.

**Color grammar — chromatic rifts change you, achromatic rifts take you somewhere.**

| Color | Type | Effect |
|---|---|---|
| Red | Chromatic | Permute; **POWER guaranteed highest**. Other two randomized. |
| Blue | Chromatic | Permute; **SPEED guaranteed highest**. |
| Green | Chromatic | Permute; **LUCK guaranteed highest**. |
| White | Achromatic | Shop. No permutation. |
| Black | Achromatic | Arena. Fight for a reward. No permutation. |
| Prismatic | Rare | Fully random permutation + realm reroll. Reserved for special events. |

Chromatic rifts are **steerable but not deterministic** — you choose which stat tops out, the other two fall where they fall.

### Realms

Six tonal variants of the labyrinth, drawn from the bhavachakra. Each supplies enemy set, palette, music, hazard type, and room-content weighting. **Not** rigidly mapped 1:1 to stat permutations — realm is selected by karma-weighted roll on rift entry.

| Realm | Tone | Design hook |
|---|---|---|
| **Deva** | Serene, abundant | Nothing threatens you. Enemies passive unless struck. Highest karma cost to farm. |
| **Asura** | Contested, martial | Enemies fight each other and you. Combat over resources. |
| **Human** | Mixed, mundane | Baseline. Most shops, most NPC-flavored content. |
| **Animal** | Instinctive, fleeing | Fast enemies, chase pressure, few ranged threats. |
| **Preta** | Craving, scarce | Items visible but locked/unreachable. Resource starvation. |
| **Naraka** | Punishing | Dense hazards, survival pressure, best rewards. |

### Karma

**Karma is causation, not morality.** No good/evil label ever shown to the player.

A scalar `karma_momentum` in `[-1.0, +1.0]`. Violent acts push positive; peaceful traversal and non-lethal resolution pull negative. Acts committed in **peaceful realms weigh more heavily** than the same acts in violent realms.

Karma biases the **realm weight table** on the next rift entry. Positive momentum skews toward Asura/Naraka; negative skews toward Deva/Human. This is the implicit cost of rifting — you cannot reroll blindly toward a god configuration, because how you play steers where you land.

### Items

Items persist across rifts. Stats do not. Fiction: items are attachments the soul refused to put down.

**Authoring template:**

> **[Attachment]** — *While [stat] is [highest / lowest / above N], [effect].*

Conditional items are the point: an item can be dormant in one configuration and broken in another. Aim for roughly **50% conditional / 50% unconditional** so builds still ratchet forward.

Aesthetic: Buddhist/existential core, deliberately muddied with alchemical objects (retorts, sigils, glassware, the peacock's tail). Whimsy over doctrinal rigor.

### Death

Simple. Death animation → game over screen with run tally → Restart / Main Menu. No meta-progression system in v1. Do not over-engineer this.

---

## 2. Repository Structure

```
samsara/
├── CLAUDE.md                  # auto-loaded context for Claude Code
├── docs/
│   ├── ARCHITECTURE.md        # how systems talk; update rarely
│   ├── STATE.md               # CURRENT milestone, locked files, next task
│   ├── BUGS.md                # open bugs w/ repro steps
│   ├── DECISIONS.md           # append-only log of design decisions + rationale
│   └── ITEM_AUTHORING.md      # how to write an item; effect vocabulary
│
├── assets/                    # ── HUMAN-OWNED. CLAUDE CODE IS READ-ONLY HERE ──
│   ├── sprites/
│   │   ├── items/             # {item_id}.png,   32×32
│   │   ├── player/            # spritesheets
│   │   ├── enemies/           # {enemy_id}.png
│   │   ├── tiles/{realm}/     # per-realm tilesets
│   │   └── rifts/             # {color}.png
│   ├── audio/
│   └── fonts/
│
├── data/                      # ── CONTENT AS DATA. Adding content ≠ editing code ──
│   ├── items/*.tres
│   ├── enemies/*.tres
│   ├── realms/*.tres
│   └── rooms/*.tscn           # hand-authored room templates
│
├── src/
│   ├── autoload/              # EventBus, RunState, ItemDB, KarmaTracker
│   ├── systems/               # labyrinth_gen, rift, stats, combat, loot
│   ├── entities/              # player, enemy, pickup, rift_node
│   ├── ui/
│   └── debug/                 # per-system test scenes + debug overlay
│
└── scenes/                    # main, run, menus
```

**The `assets/` boundary is hard.** Claude Code reads paths, never writes files there. Every texture in the game is one you made outside the project and dropped in.

---

## 3. Anti-Overwrite Protocol

This is the part that makes long-horizon Claude Code work survivable.

### `CLAUDE.md` (project root — Claude Code reads this automatically every session)

Contents:

```markdown
# Claude Code Working Rules

## Before doing anything
1. Read docs/STATE.md. Work ONLY on the milestone listed as CURRENT.
2. Read docs/ARCHITECTURE.md if touching more than one system.

## Hard rules
- NEVER create, edit, or delete anything under assets/. Read paths only.
- Files listed under LOCKED in docs/STATE.md are working code.
  Do not rewrite them. Propose a diff and rationale, then wait.
- New content (item, enemy, realm) = a NEW file in data/. Never edit a system to add content.
- Systems communicate through EventBus signals. Do not add direct
  cross-system references.
- One milestone per session. Do not implement future milestones "while you're here."

## Before finishing
- Update docs/STATE.md: what changed, what's newly LOCKED, next task.
- Append any design decision made under duress to docs/DECISIONS.md.
- Never mark a milestone complete without the "Done when" criteria observably passing in-game.
```

### `docs/STATE.md` (the working file — rewritten every session)

```markdown
# STATE

CURRENT MILESTONE: M3 — Stats & Rifts
LAST SESSION: 2026-08-26 — implemented permutation, chromatic rift entry

## LOCKED (working — propose diffs, do not rewrite)
- src/autoload/EventBus.gd
- src/entities/player.gd
- src/systems/labyrinth_gen.gd
- src/autoload/RunState.gd

## IN PROGRESS (safe to edit freely)
- src/systems/rift.gd
- src/ui/stat_display.gd

## NEXT TASK
Achromatic rifts: white → shop scene, black → arena scene.
Chromatic already works.

## KNOWN GOOD
Run `scenes/debug/rift_test.tscn` — should permute stats and regenerate map.
```

### `docs/BUGS.md`

One entry per bug, and **never fix a bug that isn't written here first.** This is what stops speculative refactoring.

```markdown
## BUG-014 [OPEN] Rift permutation drops LUCK to 0
Repro: start run, take green rift twice in a row.
Expected: values conserved as multiset.
Actual: LUCK becomes 0 on second permutation.
Suspect: src/systems/rift.gd — assignment dict mutated in place.
```

### Session cadence

Small sessions, one milestone each, `git commit` at every green state. When Claude Code proposes touching a LOCKED file, that's your signal to check whether the architecture is actually wrong or whether it's just taking a shortcut.

---

## 4. Core Data Schemas

### Item (`data/items/unsent_letter.tres`)

```gdscript
class_name Item extends Resource

@export var id: String                  # "unsent_letter" — also the texture filename
@export var display_name: String        # "The Unsent Letter"
@export var flavor: String              # one line, shown on pickup
@export var rarity: int                 # 0 common … 3 mythic

# Conditional gate — leave condition_stat empty for unconditional items
@export var condition_stat: String      # "" | "POWER" | "SPEED" | "LUCK"
@export var condition_mode: String      # "highest" | "lowest" | "above" | "below"
@export var condition_value: int        # used by above/below only

@export var effects: Array[ItemEffect]  # composable effect atoms
@export var spread_delta: int           # +widens spread, -narrows it, 0 neutral
```

**Texture resolution by convention:** `assets/sprites/items/{id}.png`. No path is ever stored in the resource. If the file is missing, the loader returns a magenta placeholder stamped with the id — missing art looks obviously missing, never broken.

### Realm (`data/realms/preta.tres`)

```gdscript
@export var id: String
@export var display_name: String
@export var palette: Array[Color]
@export var tileset_dir: String          # "assets/sprites/tiles/preta/"
@export var enemy_pool: Array[String]    # enemy ids
@export var enemy_density: float
@export var hazard_type: String
@export var karma_weight_violent: float  # multiplier on karma gained from violence here
@export var room_weights: Dictionary     # {"item":0.2,"combat":0.5,"empty":0.3}
```

### RunState (autoload)

```gdscript
var stat_values: Array[int]              # the conserved multiset, e.g. [9,5,1]
var assignment: Dictionary               # {"POWER":9,"SPEED":5,"LUCK":1}
var inventory: Array[Item]
var karma_momentum: float                # -1.0 .. +1.0
var current_realm: String
var depth: int
var rifts_taken: int
```

### EventBus (autoload — the only cross-system channel)

```gdscript
signal stats_permuted(old_assignment, new_assignment)
signal item_acquired(item)
signal item_activated(item)              # dormant → live after a permutation
signal item_deactivated(item)
signal rift_entered(color, realm)
signal karma_shifted(delta, source)
signal enemy_killed(enemy, realm)
signal player_died(cause)
```

`item_activated` is worth calling out — it exists so the UI can make the "three dormant items just lit up" moment loud. That flash is the game's signature payoff and it deserves a dedicated signal from day one.

---

## 5. Milestones

Each milestone ends with observable in-game criteria and a set of files that become LOCKED.

### M0 — Scaffolding
Repo, git, folder tree, `CLAUDE.md`, all four `docs/` files, empty autoloads, EventBus with signals stubbed. Placeholder texture loader with magenta fallback.
**Done when:** project runs, prints a EventBus signal on keypress.

### M1 — Player & Room
One hand-built room. Player moves, attacks, takes damage, dies. Programmer-art squares only.
**Done when:** you can move around a room and die.
**Locks:** `player.gd`, `EventBus.gd`

### M2 — Labyrinth Generation
Procedural room graph with **branching paths as the core structure** — the player should constantly be choosing between doors, not solving a maze. Rooms drawn from `data/rooms/` templates. Map scale expands with `depth`. LUCK feeds branch count and room richness.
**Done when:** each new floor is a different, readable, branching layout, and cranking LUCK in the debug panel visibly makes the map more generous.
**Locks:** `labyrinth_gen.gd`

### M3 — Stats & Rifts ← *the core novelty. Get here fast.*
Stat triad, multiset conservation, permutation. Chromatic rifts spawn in rooms, are enterable, guarantee their color's stat highest, regenerate the labyrinth. Stat display UI shows the permutation animating.
**Done when:** you can take a red rift, watch POWER rise to the top, and land in a fresh labyrinth.
**Locks:** `rift.gd`, `RunState.gd`

### M4 — Items
Item resource, ItemDB loading all of `data/items/`, pickups, inventory, effect application, conditional gating with `item_activated` / `item_deactivated` firing on permutation. **Author 12 items** — 6 conditional, 6 not.
**Done when:** you hold a dormant item, take the rift that suits it, and see it light up.
**Locks:** `ItemDB.gd`, `item.gd`

> **This is the vertical slice.** M1–M4 is the whole hook. Stop here and play it for a few hours before building anything else. If taking a rift to wake up an item isn't already fun with squares for art, no amount of content fixes it.

### M5 — Combat & Enemies
Enemy resource, 4–5 enemy types, spawning by realm pool, drops.

### M6 — Realms & Karma
Six realms as data. Karma tracking, realm weight table, karma-biased realm selection on rift entry. Peaceful-realm violence weighted heavier.
**Done when:** playing violently for two floors demonstrably shifts realm outcomes toward Asura/Naraka.

### M7 — Achromatic Rifts
White → shop. Black → arena. Prismatic → special event.

### M8 — Art Pipeline & Aesthetic Pass
Swap placeholders for real textures. Per-realm tilesets and palettes. Rift VFX. Item pickup presentation. **Mostly your work, not Claude Code's.**

### M9 — Content Scale-Up
Push to 60+ items. Balance pass. Item synergy hunting. Audio.

---

## 6. Art Pipeline Rules

Set these before you draw anything.

- **Base tile:** 16×16 or 32×32 — pick one now and never change it.
- **Items:** 32×32, transparent PNG, filename = item id exactly.
- **Enemies:** 32×32 or 48×48, spritesheet, uniform frame size, horizontal strip.
- **Player:** one spritesheet, documented frame order in `docs/ARCHITECTURE.md`.
- **Import preset:** filtering OFF, mipmaps OFF for pixel art. Set the Godot import default once so every drop-in is correct automatically.
- **Palette:** define a master palette file early. Per-realm palettes should be *subsets or shifts* of it, so realms feel like the same world in different moods rather than six different games.

Adding art is: draw file → save with correct id → drop in folder → it appears. If it ever requires editing code, the convention broke and that's a bug.

---

## 7. Open Questions

Not blockers for M0–M2, but they'll bite around M4–M6:

1. **Does the player choose the rift color, or is it what spawned?** Currently: what spawned. LUCK controls how many spawn, so high LUCK indirectly grants more choice. Elegant, but verify it doesn't make low-LUCK configurations feel like a trap you can't escape.
2. **Do items ever leave the inventory?** Recommend no in v1 — protect the ratchet.
3. **Is depth persistent across rifts?** If a rift advances depth, rifting is progress. If not, rifting is lateral and karma is the only cost. Recommend: chromatic rifts advance depth, achromatic don't.
4. **Spread manipulation** — items that widen/narrow spread are specced but unscheduled. Fold into M9.
5. **Does the game show the player their multiset?** Showing `[9,5,1]` teaches the conservation rule fast, but makes it feel like a spreadsheet. Consider showing it only after the first rift.

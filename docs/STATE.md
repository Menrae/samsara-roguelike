# STATE

CURRENT MILESTONE: M2 — Labyrinth Generation
LAST SESSION: 2026-08-29 — M2 topology REVISED mid-milestone from a branching tree to concentric
rings, per direct instruction (see DECISIONS.md D-010 for full rationale). labyrinth_gen.gd and
labyrinth_overlay.gd were rewritten; room_manager.gd, room_template.gd, all 6 templates, and the
seed/determinism/headless-verification approach were preserved as instructed. Headless-verified
for correctness (see KNOWN GOOD) but NOT yet eyeballed by the user in a real window — see NEXT
TASK. (Prior session's tree-topology eyeball task never happened before this revision landed —
this is the first real-window check of any M2 layout.)

## LOCKED (working — propose diffs, do not rewrite)
- src/autoload/EventBus.gd

## IN PROGRESS (safe to edit freely)
- src/autoload/RunState.gd (rewritten at M3)
- src/autoload/ItemDB.gd (rewritten at M4)
- src/autoload/Textures.gd
- scenes/debug/m0_smoke.tscn / .gd
- src/entities/player.gd + scenes/entities/player.tscn — untouched this session; M2 adds the
  player to group "player" at runtime (in scenes/debug/m2_gen_test.gd) rather than editing
  player.gd, per instruction not to touch M1 entity code without proposing a diff first.
- src/entities/weapon.gd — the seam M4 items modify; fire_rate/spread/projectile_count
  values are placeholders.
- src/entities/projectile.gd + scenes/entities/projectile.tscn
- src/entities/dummy_enemy.gd + scenes/entities/dummy_enemy.tscn
- scenes/rooms/test_room.tscn — superseded as main scene by scenes/debug/m2_gen_test.tscn;
  left in place, unreferenced, in case it's still wanted as a raw M1 sandbox.
- src/systems/labyrinth_gen.gd — REWRITTEN this session (was a branching tree, now concentric
  rings — DECISIONS.md D-010). Deterministic room-graph generator (seed/depth/luck in, graph
  dict out); nodes carry ring/ring_index/edges (direction-labeled) plus the door_map (physical
  side-labeled) room_manager consumes. **Not locked yet** — only lock once the user's eyeball
  test on scenes/debug/m2_gen_test.tscn confirms the ring layout reads as intentional, per the
  user's explicit instruction this session.
- src/entities/room_template.gd — NEW. Base script shared by every data/rooms/*.tscn. Builds
  floor/walls/doors procedurally in `_ready()` from `room_size` + whichever `active_doors`
  room_manager passes via `setup()` — a template only hand-declares size and which of its 4
  sides CAN host a door; the actual wall/gap geometry is code, not hand-placed nodes.
- src/systems/room_manager.gd — NEW, one-line change this session: reward markers now spawn on
  `node.has_reward` (set by labyrinth_gen — always true for dead ends, probabilistic elsewhere
  based on luck) instead of hardcoding `role == "dead_end"`. Otherwise unchanged: loads/frees the
  current room, tracks visited rooms, handles door transitions. Player node is owned by the
  caller and persists across room swaps.
- src/debug/labyrinth_overlay.gd — REWRITTEN this session for the ring topology. Draws concentric
  rings (ring 0 outermost), nodes placed by ring/ring_index angle, role-colored, current room
  highlighted, radial (IN/OUT) edges drawn distinctly (brighter/thicker) from lateral (CW/CCW)
  ones, reward rooms get a small gold ring, plus seed/depth/luck/room/ring-count readout.
  Designer-facing only.
- data/rooms/*.tscn — NEW, 6 templates (room_deadend, room_corridor, room_corner, room_hub3,
  room_hub4, room_cross_large), sizes 600x500 to 1200x900, 1 to 4 door-capable sides. All
  share room_template.gd; adding a 7th template is a new file here, no system edit needed —
  labyrinth_gen scans this directory rather than hardcoding a template list.
- scenes/debug/m2_gen_test.tscn / .gd — NEW. The main scene (project.godot `run/main_scene`
  now points here instead of scenes/rooms/test_room.tscn). SPACE = new random seed, UP/DOWN =
  luck ±1, LEFT/RIGHT = depth ±1/-1, each regenerating in place.

## NEXT TASK
Run the project in a real window (`make run` or `make editor`) and eyeball the M2 (ring
revision) "Done when" criteria:
- The overlay reads as a legible concentric map: rings visibly nested, current room highlighted,
  radial connections visually distinct from the lateral ring connections.
- Press UP a few times (raise luck) — confirm more radial (orange) shortcut lines appear between
  rings. Press DOWN — confirm they thin back out and you're forced to walk the ring laterally to
  find a way inward.
- Press LEFT/RIGHT — confirm ring count and rooms-per-ring visibly grow/shrink.
- Walk through doors between rooms (player should pass cleanly through the gold door gap and
  land just inside the new room, not stuck on a wall) — confirm you can walk both inward
  (toward the center) and laterally (around a ring).
Report back — if it reads well, labyrinth_gen.gd gets marked LOCKED and M2 is done; if the
ring/radial-count feel is off, the tuning formulas in `LabyrinthGen.generate()` (ring_count,
ring_size, radial_count) and the sever_target line in `_build_rings()` are the place to adjust,
not the graph algorithm itself. Do not start M3 (Stats & Rifts) until that confirmation happens.

## KNOWN GOOD
- `godot --headless --version` → 4.7.1.stable.official.a13da4feb
- `make check` exits 0 (gdlint clean, headless import pass clean) against the current repo.
- `bash scripts/godot.sh --headless --quit` boots scenes/rooms/test_room.tscn (now the main
  scene) with no runtime errors.
- Input map (move_up/down/left/right = WASD, fire = mouse left click) is registered in
  project.godot under [input]; config_version untouched. Physics layers named in
  [layer_names] (walls/player/enemies/projectiles) — see DECISIONS.md D-004.
- Headless SceneTree simulation scripts (written to scratchpad, not part of the repo)
  confirmed, prior session, all mechanically:
  - CharacterBody2D + StaticBody2D wall collision actually stops the player at the wall face.
  - Weapon-fired projectiles travel, hit the dummy enemy, and kill it in 3 shots at default
    damage (10) vs. default health (30).
  - Contact damage: standing on the dummy enemy applies damage on entry and again on each
    ContactTimer tick while overlapping.
  - Player i-frames correctly block a second hit taken immediately after the first, and
    correctly allow damage again once the i-frame window has elapsed.
  - Lethal damage frees the player and emits `EventBus.player_died(cause)` with the given
    cause string.
  - projectile_count=5 / spread=30 fires 5 projectiles in one call without error (the
    multi-shot path works, not just the count=1 default).
- Confirmed in a real window, this session: WASD movement, mouse aim/fire, dummy kill, contact
  damage + death with i-frame flash — the M1 "Done when" criteria, previously only
  headless-verified.
- Headless SceneTree scripts this session (scratchpad, not part of the repo) confirmed:
  - `LabyrinthGen.generate(seed, depth, luck)` is deterministic (same inputs → identical
    graph) and different seeds diverge.
  - Room count and dead-end count both scale up reliably with luck **per individual seed**,
    not just on average (this needed a fix — see DECISIONS.md).
  - Every generated graph has exactly one start and one exit room, every room is reachable
    from start, and each door_map is a consistent bijection (A's door to B always has a
    matching door back from B to A).
  - Driving a real `RoomManager` through a generated graph via a simulated `door_entered`
    signal correctly updates `current_room_id` and `visited` per the graph's door_map.
  - All 6 room templates build the correct wall/door topology: N active doors → N Area2D
    triggers each with a non-degenerate `RectangleShape2D`, and the remaining sides sealed as
    solid `StaticBody2D` walls; zero active doors → exactly 4 solid walls, 0 doors.
- `godot --headless --path . scenes/debug/m2_gen_test.tscn --quit-after 60` boots the new main
  scene for 60 frames with zero errors/warnings.
- `make check` still exits 0 (gdlint clean, headless import pass clean) after the ring rewrite.
- Headless SceneTree scripts this session (scratchpad, not part of the repo) confirmed, across a
  spread of seeds × depths × lucks (including negative luck):
  - `LabyrinthGen.generate(seed, depth, luck)` is still deterministic and different seeds still
    diverge.
  - Every generated graph has exactly one start and one exit room, the exit is always in the
    innermost ring, every room is reachable from start (the sever/repair backfill holds), and
    every ring loses at least one lateral edge (never a guaranteed complete loop).
  - door_map is still a consistent bijection (A's door to B always has a matching door back).
  - Averaged over 60 seeds at depth=2: luck=0 → 3.00 avg radial doors, luck=12 → 15.00 avg —
    luck's primary radial-scarcity lever scales strongly and reliably.
  - depth=0 → 2 rings / 6 rooms vs. depth=5 → 6 rings / 48 rooms — depth's ring-count/room-count
    lever scales as expected.
  - Driving a real `RoomManager` through a full generated graph (every door out of every
    reachable room) via simulated `door_entered` correctly reaches every room and matches the
    graph's door_map at each step.
  - For every node across the seed/depth/luck spread, the chosen template's door_sides is a
    superset of every physical side its door_map actually uses (the OUTWARD=N / INWARD=S /
    CLOCKWISE=E / COUNTERCLOCKWISE=W mapping never picks a template missing a required side).

## OPEN ENVIRONMENT ISSUE
D-002 recurrence noted last session (`/home/vscode/.config/godot` root-owned) appears
resolved: `ls -ld` now shows `vscode:vscode` ownership. Not re-verified by actually opening
the GUI editor this session — if `make editor` still fails, re-apply the D-002 fix.

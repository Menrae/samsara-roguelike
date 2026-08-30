# STATE

CURRENT MILESTONE: M3 — Stats & Rifts
LAST SESSION: 2026-08-30 — Built the conserved-multiset stat system, wired SPEED/POWER/LUCK into
the M1 player/weapon and M2 labyrinth generator, added chromatic rifts (deliberate-interact
entry → permute → regenerate at the same ring), luck-scaled rift spawning in the labyrinth
itself, a persistent animated stat display, and scenes/debug/m3_rift_test.tscn as the new main
scene. Note: M2's ring-topology eyeball check (STATE.md's previous NEXT TASK) was never
confirmed back to me before this session's direct instruction to move straight to M3 — proceeding
per that explicit instruction, but the M2 ring layout is technically still unconfirmed in a real
window on top of M3 now also being unconfirmed. Headless-verified extensively (see KNOWN GOOD)
but NOT yet played in a real window — see NEXT TASK. Per explicit instruction this session,
**nothing is newly locked** — PROJECT_PLAN lists `rift.gd`/`RunState.gd` as M3 locks, but the
session brief said "do not lock anything — this needs tuning," which overrides that.

## LOCKED (working — propose diffs, do not rewrite)
- src/autoload/EventBus.gd

## IN PROGRESS (safe to edit freely)
- src/autoload/ItemDB.gd (rewritten at M4)
- src/autoload/Textures.gd
- scenes/debug/m0_smoke.tscn / .gd
- scenes/rooms/test_room.tscn — unreferenced raw M1 sandbox, untouched.
- src/entities/dummy_enemy.gd + scenes/entities/dummy_enemy.tscn — untouched this session.
- src/entities/projectile.gd + scenes/entities/projectile.tscn — untouched this session.
- src/autoload/RunState.gd — gained one method, `permute(guaranteed_highest="")`: duplicates the
  current assignment, calls `Stats.permute(stat_values, guaranteed_highest)`, stores the result,
  emits `EventBus.stats_permuted(old_assignment, new_assignment)`. Still just data + this one
  method — the multiset math itself lives in stats.gd. **Not locked** — see above.
- src/systems/stats.gd — NEW. `class_name Stats extends RefCounted`, pure/stateless (same split
  as LabyrinthGen vs RoomManager): `Stats.permute(stat_values, guaranteed_highest)` returns a new
  assignment dict (multiset conserved, optional stat forced to the max value); `Stats.scale(value,
  stat_values)` returns value/average — average is recomputed from stat_values every call, not a
  hardcoded baseline, so it stays correct if a future milestone changes the multiset (DECISIONS.md
  D-013).
- src/entities/player.gd — `move_speed` renamed `base_move_speed` (now the M1 constant a stat
  scales, not the actual speed used); `_physics_process` computes `speed_scale =
  Stats.scale(RunState.assignment.get("SPEED",0.0), RunState.stat_values)` fresh every frame (not
  cached) and applies it, so a permutation is felt on the very next frame.
- src/entities/weapon.gd — `fire_rate`/`damage` renamed `base_fire_rate`/`base_damage`.
  `_speed_scale()`/`_power_scale()` helpers wrap `Stats.scale`; fire cooldown and per-shot damage
  both read fresh on every shot, not cached.
- src/entities/rift.gd + scenes/entities/rift.tscn — NEW. Chromatic-only this milestone
  (RED→POWER, BLUE→SPEED, GREEN→LUCK guaranteed highest). An Area2D that tracks player overlap
  but only acts on a deliberate "interact" (E key) press — never on overlap alone. On activation:
  `RunState.permute(color's stat)`, `RunState.rifts_taken += 1`, emits
  `EventBus.rift_entered(color, "none")`. Holds **no reference to RoomManager** — the
  regeneration/ring-preserving handoff is RoomManager's job, reacting to that signal
  (DECISIONS.md D-011). `[E]` prompt label shows only while the player is standing on it.
- src/systems/room_manager.gd — gained: a `_ready()` that connects `EventBus.rift_entered`;
  `_on_rift_entered()` (reads the current room's ring + the just-permuted LUCK, generates a new
  graph at the same `RunState.depth`, calls the below); `regenerate_at_ring(new_graph, ring)`
  (like `start()` but drops the player into a random room on `ring` instead of always
  `start_id`); `_spawn_rift()` (instantiates `scenes/entities/rift.tscn` into a room whose graph
  node has a `rift_color`, mirroring the existing `_spawn_reward_marker` pattern); a small
  `_clear_current_room()` helper factored out of `start()`/`regenerate_at_ring()`. Otherwise
  unchanged.
- src/systems/labyrinth_gen.gd — gained `_assign_rifts()`, called from `generate()` after
  rewards: sets `node["rift_color"]` to `""` or one of RED/BLUE/GREEN for a luck-scaled count of
  non-start rooms (same "findable but not guaranteed" shape as radial_count — see DECISIONS.md
  D-010's rationale, extended). depth/luck/seed contract, ring topology, and everything else from
  the M2 session unchanged; **still not locked** (M2's own eyeball confirmation is still
  outstanding — see LAST SESSION note above).
- src/ui/stat_display.gd + scenes/ui/stat_display.tscn — NEW. Persistent HUD (top-right),
  independent of the debug scenes — meant to be the real in-game stat UI going forward, not a
  debug-only overlay (unlike labyrinth_overlay.gd). On `EventBus.stats_permuted`, each stat's new
  value visibly flies from the row of whichever stat held that value before to the row that holds
  it now (matched by value, not tracked identity — DECISIONS.md D-014), plus a brief scale-pulse
  on whichever stat lands highest.
- scenes/debug/m3_rift_test.tscn / .gd — NEW. The main scene (project.godot `run/main_scene` now
  points here instead of scenes/debug/m2_gen_test.tscn). Sets `RunState.stat_values = [9,5,1]`
  and does an initial unguaranteed permute on boot, generates a real labyrinth via
  LabyrinthGen/RoomManager, and places all three rift colors as fixed-position siblings of
  RoomManager near the room origin so they're always available regardless of which room is
  currently loaded (DECISIONS.md D-015 — exploits D-007's shared-origin room placement). Also
  shows a raw `stat_values`/`assignment`/`ring` debug readout (separate from the polished
  stat_display). No SPACE/UP/DOWN/LEFT/RIGHT controls this time — luck is driven by rifting, not
  a debug key.

## NEXT TASK
Play `scenes/debug/m3_rift_test.tscn` in a real window (`make run` or `make editor`) and check
the M3 "Done when" criteria:
- Walk to the red rift, stand on it, press **E** deliberately (confirm it does NOT trigger just
  from walking over it) — POWER should visibly animate to the highest value in the stat display
  (top-right), with its value flying in from wherever it used to be.
- Confirm the character actually plays differently afterward — movement speed and fire rate
  should feel different depending on which stat is currently highest (SPEED vs POWER vs LUCK).
- Confirm you land in a freshly generated labyrinth, on the same ring you rifted from (check the
  minimap ring highlight before/after, and the raw debug label's `ring=` line).
- Try the blue and green rifts too — SPEED and LUCK should each visibly take the top slot.
- At various points, note whether rifts feel "findable but not guaranteed" while exploring
  further out (not just the 3 guaranteed ones by spawn) — this is luck-scaled and may need
  tuning.
Report back. Tuning knobs if something feels off, all safe to adjust freely (nothing is locked):
- `Stats.scale()` in src/systems/stats.gd — the speed/damage/fire-rate multiplier curve.
- `_assign_rifts()` in src/systems/labyrinth_gen.gd — how many rooms get a rift and how that
  scales with luck (`max_rifts`, the `1 + int(luck/3.0)` formula).
- `ROW_HEIGHT`/`FLIGHT_DURATION`/etc. in src/ui/stat_display.gd — animation pacing.
- `base_move_speed`/`base_fire_rate`/`base_damage` on the Player/Weapon scenes — the M1 baseline
  constants the stats scale.
Also still outstanding from last session: M2's ring-topology eyeball check was never explicitly
confirmed (see LAST SESSION note) — worth a look while in here regardless of M3 feedback.
Do not lock anything and do not start M4 (Items) until this is confirmed.

## KNOWN GOOD
- `godot --headless --version` → 4.7.1.stable.official.a13da4feb
- `make check` exits 0 (gdlint clean, headless import pass clean) against the current repo.
- Input map (move_up/down/left/right = WASD, fire = mouse left click, **interact = E**,
  added this session the same programmatic way as D-004) is registered in project.godot under
  [input]; config_version untouched. Physics layers named in [layer_names]
  (walls/player/enemies/projectiles) — see DECISIONS.md D-004.
- Headless SceneTree simulation scripts (scratchpad, not part of the repo) confirmed, prior
  sessions, all mechanically: wall collision, projectile-kills-dummy in 3 shots, contact damage
  ticking, player i-frames blocking/re-enabling correctly, lethal damage emitting
  `EventBus.player_died`, multi-shot/spread firing, all 6 room templates' wall/door topology,
  ring-topology connectivity/bijection/severing/luck-scaling invariants across a seed/depth/luck
  spread, and a real RoomManager walking a full generated graph via simulated `door_entered`.
- Confirmed in a real window, M1 session: WASD movement, mouse aim/fire, dummy kill, contact
  damage + death with i-frame flash — the M1 "Done when" criteria.
- `godot --headless --path . scenes/debug/m2_gen_test.tscn --quit-after 60` boots with zero
  errors/warnings (M2 session).
- Headless SceneTree scripts this session (temporary scenes under scenes/debug/, deleted before
  finishing — real scenes were needed, not `--script` mode, since autoloads only initialize for
  an actual scene run) confirmed:
  - `Stats.permute()`: multiset conserved (sorted assigned values == sorted input) across 500
    trials mixing all four guarantee options; guaranteed_highest always receives the true max.
  - `Stats.scale()`: scale(average, values) == 1.0 exactly; scale(9, [9,5,1]) == 9/5;
    scale(1, [9,5,1]) == 1/5; scale(anything, []) == 1.0 (safe default pre-run-init).
  - `RunState.permute()`: emits exactly one `stats_permuted(old, new)` per call; `old` is the
    pre-call snapshot (not aliased/mutated after the fact); `RunState.assignment` matches the
    emitted `new`; a second permute's `old` equals the first permute's `new`.
  - `LabyrinthGen._assign_rifts()`: every node has a `rift_color` key (never missing), always ""
    or a real color, never on the start room; averaged over 60 seeds at depth=2, luck=0 → 1.00
    avg rifts/graph vs. luck=15 → 6.00 avg — scales strongly with luck, same shape as
    radial_count.
  - Full rift-entry flow driven through the REAL RoomManager + a REAL spawned Rift node (not a
    mock): walked a BFS path from start to a rift room, confirmed RoomManager actually spawned a
    `Rift` child there with the graph's chosen color; called `rift._enter()`; confirmed
    `RunState.rifts_taken` incremented by exactly 1, the color's stat was left holding the
    multiset's true max, `RoomManager.graph`'s seed changed (real regeneration, not a no-op), the
    new graph's `depth` still equals `RunState.depth` (reused, not altered), and the player's new
    room is on the SAME ring as before entry.
  - SPEED/POWER/fire-rate scaling verified through the REAL Player/Weapon scenes, not just
    Stats math in isolation: SPEED=5 (the multiset's average) reproduces `base_move_speed`
    exactly; SPEED=9 vs SPEED=1 gives velocities of 396 vs 44 (a clean 9x ratio, matching
    value/average); POWER=9 vs POWER=1 gives a 9x damage-scale ratio; SPEED=9 vs SPEED=1 gives
    fire cooldowns of 0.139s vs 1.25s.
  - Re-ran the full M2 connectivity/bijection/template-compatibility invariant suite after this
    session's labyrinth_gen.gd changes (rift assignment added) — still all pass, no regression.
- `godot --headless --path . scenes/debug/m3_rift_test.tscn --quit-after 120` boots the new main
  scene for 120 frames with zero errors/warnings.

## OPEN ENVIRONMENT ISSUE
D-002 recurrence noted two sessions ago (`/home/vscode/.config/godot` root-owned) appeared
resolved as of last session (`ls -ld` showed `vscode:vscode` ownership). Still not re-verified by
actually opening the GUI editor — if `make editor` fails, re-apply the D-002 fix.

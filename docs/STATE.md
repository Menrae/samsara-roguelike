# STATE

CURRENT MILESTONE: M0 — Scaffolding
LAST SESSION: 2026-08-28 — created repo folder tree, CLAUDE.md, and docs/ scaffolding
(ARCHITECTURE.md, STATE.md, BUGS.md, DECISIONS.md, ITEM_AUTHORING.md). No GDScript or
Godot project files yet — that's the rest of M0 / M1.

## LOCKED (working — propose diffs, do not rewrite)
(none yet — no code exists)

## IN PROGRESS (safe to edit freely)
(none yet)

## NEXT TASK
Finish M0: create `project.godot`, empty autoloads (EventBus, RunState, ItemDB,
KarmaTracker) with EventBus signals stubbed per docs/PROJECT_PLAN.md §4, and a placeholder
texture loader with magenta fallback.
**Done when:** project runs, prints an EventBus signal on keypress.

## KNOWN GOOD
No runnable project yet. `make check` / `make run` no-op cleanly (see scripts/check.sh)
until `src/` has content and `project.godot` exists.

# samsara-roguelike

A 2D roguelike about a soul moving through the labyrinth of rebirth.

Three stats — Power, Speed, Luck — whose values are conserved across a run but reshuffled
every time you step through a rift. Items persist; your configuration doesn't. Half of them
lie dormant until the right life comes around.

**Status:** M0 — scaffolding. Not yet playable.

## Getting started

1. Open this folder in VS Code (requires the Dev Containers extension and Docker Desktop
   with WSL2 integration).
2. Command Palette → **Dev Containers: Reopen in Container**. First build takes a few
   minutes.
3. `make check` — should exit 0.

See [docs/DEVCONTAINER.md](docs/DEVCONTAINER.md) for the full toolchain reference.

## Docs

| File | What it's for |
|---|---|
| [PROJECT_PLAN.md](docs/PROJECT_PLAN.md) | Design spec and milestones — source of truth |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the code is wired |
| [STATE.md](docs/STATE.md) | Current milestone, locked files, next task |
| [DECISIONS.md](docs/DECISIONS.md) | Log of decisions and deviations |
| [ITEM_AUTHORING.md](docs/ITEM_AUTHORING.md) | How to write an item |
| [BUGS.md](docs/BUGS.md) | Open bugs with repro steps |
| [DEVCONTAINER.md](docs/DEVCONTAINER.md) | Toolchain setup and commands |

# samsara-roguelike — dev container

This repo's dev container gives every session an identical, reproducible Godot 4 + GDScript
toolchain. This document covers the container only, not the game.

## Pinned versions

- **Godot: 4.7.1** (stable, Linux x86_64), set via `ARG GODOT_VERSION` at the top of
  `.devcontainer/Dockerfile`.
- **gdtoolkit: 4.x** (`gdformat` / `gdlint`), the line compatible with Godot 4 GDScript.

To bump Godot: edit `GODOT_VERSION` in `.devcontainer/Dockerfile`, confirm the matching release
asset exists at
`https://github.com/godotengine/godot/releases/tag/{VERSION}-stable`, then rebuild the container.

## Opening the container

1. Open this folder in VS Code.
2. Command Palette → **Dev Containers: Reopen in Container** (requires the "Dev Containers"
   extension and Docker Desktop with WSL2 integration enabled).
3. First build takes a few minutes — it downloads the Godot editor and export templates.
   `postCreateCommand` prints the resolved Godot / gdtoolkit / Python versions when it's done, so
   you have proof the toolchain is intact before doing anything else.

## Rebuilding

Command Palette → **Dev Containers: Rebuild Container** after changing anything under
`.devcontainer/`.

## Everyday commands

Run these from a terminal inside the container (or `docker exec` in):

```sh
make help     # list targets
make check    # gdlint (if src/ exists) + a headless import/validate pass
make format   # gdformat (if src/ exists)
make editor   # launch the Godot editor GUI via WSLg
make run      # run the project headless
```

`make check` and `make format` are safe to run right now, against the empty repo — they no-op
cleanly until `src/` exists.

## GUI editor via WSLg

`make editor` launches the Godot editor window on your Windows desktop through WSLg
(`/tmp/.X11-unix` and `/mnt/wslg` are mounted into the container, with `DISPLAY`,
`WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, and `PULSE_SERVER` set accordingly). This is optional —
headless (`make check` / `make run`) is the primary workflow and doesn't depend on WSLg at all.

## Persistence across rebuilds

Bash history and Godot editor config live in named Docker volumes
(`samsara-roguelike-bash-history`, `samsara-roguelike-godot-config`), so they survive a container
rebuild.

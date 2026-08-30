.DEFAULT_GOAL := help

.PHONY: help check format editor run

help: ## Show this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

check: ## Lint GDScript (if src/ exists) and run a headless import/validate pass.
	@bash scripts/check.sh

format: ## Format GDScript in src/ (if it exists) with gdformat.
	@bash scripts/format.sh

editor: ## Launch the Godot editor GUI via WSLg.
	@bash scripts/godot.sh --editor

run: ## Run the project with a window
	godot --path .

run-headless: ## Run the project headless (CI / smoke checks)
	godot --headless --path .

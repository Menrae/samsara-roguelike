extends Node
## Per-run state (docs/PROJECT_PLAN.md §4). Stat permutation math lives in
## src/systems/stats.gd, kept pure/stateless — this autoload just owns the
## state and fires the signal so it's still the single source of truth
## anything (player, weapon, labyrinth_gen, UI) reads stats from.

var stat_values: Array[int] = []
var assignment: Dictionary = {}
var inventory: Array = []
var karma_momentum: float = 0.0
var current_realm: String = ""
var depth: int = 0
var rifts_taken: int = 0


## Reassigns the SAME stat_values to POWER/SPEED/LUCK — see Stats.permute.
## guaranteed_highest, if one of the three stat names, gets the largest
## value; the other two land wherever the shuffle puts them.
func permute(guaranteed_highest: String = "") -> void:
	var old_assignment: Dictionary = assignment.duplicate()
	assignment = Stats.permute(stat_values, guaranteed_highest)
	EventBus.stats_permuted.emit(old_assignment, assignment)

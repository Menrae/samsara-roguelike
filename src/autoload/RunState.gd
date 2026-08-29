extends Node
## Per-run state. Declarations only — rewritten at M3 (docs/PROJECT_PLAN.md §4).

var stat_values: Array[int] = []
var assignment: Dictionary = {}
var inventory: Array = []
var karma_momentum: float = 0.0
var current_realm: String = ""
var depth: int = 0
var rifts_taken: int = 0

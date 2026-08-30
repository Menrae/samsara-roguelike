class_name Stats
extends RefCounted
## Pure conserved-multiset stat math. src/autoload/RunState.gd owns the
## actual stat_values/assignment state (docs/PROJECT_PLAN.md §4); this is
## the math kept separate and stateless, the same split M2 uses between
## LabyrinthGen (pure) and RoomManager (stateful owner).

const STAT_NAMES := ["POWER", "SPEED", "LUCK"]


## Returns a NEW assignment mapping each of STAT_NAMES to one of
## stat_values, using every value exactly once — the multiset is conserved,
## only which stat holds which value changes. If guaranteed_highest is one
## of STAT_NAMES, it receives the largest value; the other two values are
## randomly assigned to the other two stats. Not seeded — rifts are meant to
## be steerable but not deterministic (docs/PROJECT_PLAN.md §1).
static func permute(stat_values: Array, guaranteed_highest: String = "") -> Dictionary:
	var values: Array = stat_values.duplicate()
	var assignment: Dictionary = {}

	if guaranteed_highest in STAT_NAMES:
		var highest = values.max()
		values.erase(highest)
		assignment[guaranteed_highest] = highest

	var remaining_stats: Array = STAT_NAMES.filter(func(s): return not assignment.has(s))
	_shuffle(values)
	for i in range(remaining_stats.size()):
		assignment[remaining_stats[i]] = values[i]

	return assignment


## The multiplier a stat value represents relative to the multiset's own
## average. The average is invariant under permutation (the sum is
## conserved), so 1.0 always means "an untouched roll," not a hardcoded
## baseline — gameplay constants scale by this, not by the raw stat value.
static func scale(value: float, stat_values: Array) -> float:
	if stat_values.is_empty():
		return 1.0
	var total: float = 0.0
	for v in stat_values:
		total += v
	var average: float = total / stat_values.size()
	if average <= 0.0:
		return 1.0
	return value / average


static func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

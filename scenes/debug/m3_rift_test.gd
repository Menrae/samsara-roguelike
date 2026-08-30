extends Node2D
## M3 debug harness: all three chromatic rifts are always available near the
## room origin (they're siblings of RoomManager, not children of the transient
## room, so they survive every regeneration — D-007 rooms all share the same
## origin). Also drives the persistent stat display and a raw debug readout.
## See docs/PROJECT_PLAN.md M3 "Done when" criteria.

@export var starting_depth: int = 1

const INITIAL_STAT_VALUES: Array[int] = [9, 5, 1]

@onready var _room_manager: RoomManager = $RoomManager
@onready var _player: Node2D = $Player
@onready var _overlay: Control = $DebugOverlay/Overlay
@onready var _debug_label: Label = $DebugOverlay/DebugLabel


func _ready() -> void:
	_player.add_to_group("player")

	RunState.depth = starting_depth
	RunState.stat_values = INITIAL_STAT_VALUES.duplicate()
	RunState.permute()

	_room_manager.room_changed.connect(_on_room_changed)
	EventBus.stats_permuted.connect(_on_stats_permuted)

	var graph := LabyrinthGen.generate(
		randi(), RunState.depth, int(RunState.assignment.get("LUCK", 0))
	)
	_room_manager.start(graph, _player)


func _on_room_changed(room_id: int) -> void:
	_overlay.set_graph(_room_manager.graph, room_id)
	_refresh_debug_label()


func _on_stats_permuted(_old_assignment: Dictionary, _new_assignment: Dictionary) -> void:
	_refresh_debug_label()


func _refresh_debug_label() -> void:
	var ring := -1
	if not _room_manager.graph.is_empty():
		ring = _room_manager.graph["nodes"][_room_manager.current_room_id]["ring"]
	_debug_label.text = "stat_values=%s\nassignment=%s\nring=%d" % [
		str(RunState.stat_values), str(RunState.assignment), ring
	]

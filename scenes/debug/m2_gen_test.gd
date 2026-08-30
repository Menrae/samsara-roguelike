extends Node2D
## M2 debug harness: regenerates the labyrinth graph on keypress and lets you
## tune luck/depth live so layouts can be eyeballed quickly. See
## docs/PROJECT_PLAN.md M2 "Done when" criteria.

@export var starting_depth: int = 1
@export var starting_luck: int = 3

var _depth: int
var _luck: int
var _seed: int

@onready var _room_manager: RoomManager = $RoomManager
@onready var _player: Node2D = $Player
@onready var _overlay: Control = $DebugOverlay/Overlay


func _ready() -> void:
	_player.add_to_group("player")
	_depth = starting_depth
	_luck = starting_luck
	_seed = randi()
	_room_manager.room_changed.connect(_on_room_changed)
	_regenerate()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_SPACE:
			_seed = randi()
			_regenerate()
		KEY_UP:
			_luck += 1
			_regenerate()
		KEY_DOWN:
			_luck -= 1
			_regenerate()
		KEY_RIGHT:
			_depth += 1
			_regenerate()
		KEY_LEFT:
			_depth = maxi(_depth - 1, 0)
			_regenerate()


func _regenerate() -> void:
	var graph := LabyrinthGen.generate(_seed, _depth, _luck)
	_room_manager.start(graph, _player)
	_overlay.set_graph(graph, _room_manager.current_room_id)


func _on_room_changed(room_id: int) -> void:
	_overlay.set_current_room(room_id)

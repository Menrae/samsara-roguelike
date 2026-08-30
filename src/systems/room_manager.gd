class_name RoomManager
extends Node2D
## Instantiates the current room from a generated labyrinth graph, wires door
## transitions, and tracks which rooms have been visited. The player node is
## owned by the caller and persists across transitions; rooms are loaded and
## freed one at a time as the player walks through doors.
##
## Also owns the M3 rift-regeneration handoff: it listens for
## EventBus.rift_entered (emitted by src/entities/rift.gd, which holds no
## reference back to RoomManager) and regenerates the labyrinth itself,
## dropping the player into a room on the SAME ring they rifted from so
## radial progress survives the transition.

signal room_changed(room_id: int)

const RIFT_SCENE := preload("res://scenes/entities/rift.tscn")

var graph: Dictionary = {}
var current_room_id: int = -1
var visited: Dictionary = {}

var _player: Node2D
var _current_room: RoomTemplate


func _ready() -> void:
	EventBus.rift_entered.connect(_on_rift_entered)


func start(new_graph: Dictionary, player: Node2D) -> void:
	graph = new_graph
	_player = player
	visited.clear()
	_clear_current_room()
	_enter_room(graph["start_id"], "")


## Swaps in a freshly generated labyrinth, keeping the already-owned player,
## and drops them into a room on `ring` instead of always start_id — used
## when a rift regenerates the map but wants radial progress to persist.
func regenerate_at_ring(new_graph: Dictionary, ring: int) -> void:
	graph = new_graph
	visited.clear()
	_clear_current_room()

	var target_id: int = new_graph["start_id"]
	var ring_rooms: Array = []
	for id in (new_graph["nodes"] as Dictionary).keys():
		if new_graph["nodes"][id]["ring"] == ring:
			ring_rooms.append(id)
	if not ring_rooms.is_empty():
		target_id = ring_rooms[randi() % ring_rooms.size()]

	_enter_room(target_id, "")


func _on_rift_entered(_color: String, _realm: String) -> void:
	if graph.is_empty() or not (graph["nodes"] as Dictionary).has(current_room_id):
		return
	var current_ring: int = graph["nodes"][current_room_id]["ring"]
	var luck: int = int(RunState.assignment.get("LUCK", 0))
	var new_graph := LabyrinthGen.generate(randi(), RunState.depth, luck)
	regenerate_at_ring(new_graph, current_ring)


func _clear_current_room() -> void:
	if _current_room != null:
		_current_room.queue_free()
		_current_room = null


func _enter_room(room_id: int, entry_side: String) -> void:
	_clear_current_room()

	var node: Dictionary = graph["nodes"][room_id]
	var packed: PackedScene = load(node["template_path"])
	var room: RoomTemplate = packed.instantiate()
	room.setup((node["door_map"] as Dictionary).keys())
	add_child(room)
	room.door_entered.connect(_on_door_entered)
	_current_room = room

	current_room_id = room_id
	visited[room_id] = true

	var spawn_point := Vector2.ZERO
	if entry_side != "":
		spawn_point = room.get_entry_point(entry_side)
	_player.global_position = room.global_position + spawn_point

	if node.get("has_reward", false):
		_spawn_reward_marker(room)

	var rift_color: String = node.get("rift_color", "")
	if rift_color != "":
		_spawn_rift(room, rift_color)

	room_changed.emit(room_id)


func _on_door_entered(side: String) -> void:
	var node: Dictionary = graph["nodes"][current_room_id]
	var door_map: Dictionary = node["door_map"]
	if not door_map.has(side):
		return

	var neighbor_id: int = door_map[side]
	var neighbor_door_map: Dictionary = graph["nodes"][neighbor_id]["door_map"]

	var entry_side := ""
	for s in neighbor_door_map.keys():
		if neighbor_door_map[s] == current_room_id:
			entry_side = s
			break

	_enter_room(neighbor_id, entry_side)


func _spawn_reward_marker(room: RoomTemplate) -> void:
	var marker := Area2D.new()
	marker.collision_layer = 0
	marker.collision_mask = 2
	marker.position = Vector2(0, -40)
	room.add_child(marker)

	var rect := ColorRect.new()
	rect.color = Color(0.9, 0.75, 0.15, 1)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2(-14, -14)
	rect.size = Vector2(28, 28)
	marker.add_child(rect)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	marker.add_child(shape)

	marker.body_entered.connect(_on_reward_body_entered.bind(marker))


func _on_reward_body_entered(body: Node, marker: Area2D) -> void:
	if body.is_in_group("player"):
		marker.queue_free()


func _spawn_rift(room: RoomTemplate, color: String) -> void:
	var rift: Rift = RIFT_SCENE.instantiate()
	rift.color = color
	rift.position = Vector2(0, 40)
	room.add_child(rift)

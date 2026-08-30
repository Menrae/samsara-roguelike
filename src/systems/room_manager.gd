class_name RoomManager
extends Node2D
## Instantiates the current room from a generated labyrinth graph, wires door
## transitions, and tracks which rooms have been visited. The player node is
## owned by the caller and persists across transitions; rooms are loaded and
## freed one at a time as the player walks through doors.

signal room_changed(room_id: int)

var graph: Dictionary = {}
var current_room_id: int = -1
var visited: Dictionary = {}

var _player: Node2D
var _current_room: RoomTemplate


func start(new_graph: Dictionary, player: Node2D) -> void:
	graph = new_graph
	_player = player
	visited.clear()
	if _current_room != null:
		_current_room.queue_free()
		_current_room = null
	_enter_room(graph["start_id"], "")


func _enter_room(room_id: int, entry_side: String) -> void:
	if _current_room != null:
		_current_room.queue_free()
		_current_room = null

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

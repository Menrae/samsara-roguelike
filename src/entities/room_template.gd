class_name RoomTemplate
extends Node2D
## Base script shared by every data/rooms/*.tscn template. A template only
## declares its size and which of its 4 sides CAN host a door (data); walls,
## floor, and doors are built procedurally in _ready() from whichever sides
## room_manager actually wires up for a given graph node (active_doors), so
## the same template can appear as a 1-door dead end or a 3-door junction.

signal door_entered(side: String)

const SIDES := ["N", "E", "S", "W"]
const WALL_THICKNESS := 32.0
const DOOR_WIDTH := 120.0
const WALL_COLOR := Color(0.4, 0.4, 0.45, 1)
const DOOR_COLOR := Color(0.85, 0.7, 0.2, 1)
const FLOOR_COLOR := Color(0.16, 0.16, 0.18, 1)

@export var room_size: Vector2 = Vector2(800, 600)
@export var door_sides: Array[String] = []

var active_doors: Array = []


func setup(doors: Array) -> void:
	active_doors = doors.duplicate()


func get_entry_point(side: String) -> Vector2:
	var half := room_size / 2.0
	var inset := 80.0
	match side:
		"N":
			return Vector2(0, -half.y + inset)
		"S":
			return Vector2(0, half.y - inset)
		"E":
			return Vector2(half.x - inset, 0)
		"W":
			return Vector2(-half.x + inset, 0)
	return Vector2.ZERO


func _ready() -> void:
	_add_floor()
	for side in SIDES:
		_build_wall_side(side)


func _add_floor() -> void:
	var rect := ColorRect.new()
	rect.color = FLOOR_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = -room_size / 2.0
	rect.size = room_size
	add_child(rect)


func _build_wall_side(side: String) -> void:
	var half := room_size / 2.0
	var has_door: bool = side in active_doors
	match side:
		"N":
			_build_span(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), true, has_door, side)
		"S":
			_build_span(Vector2(-half.x, half.y), Vector2(half.x, half.y), true, has_door, side)
		"W":
			_build_span(Vector2(-half.x, -half.y), Vector2(-half.x, half.y), false, has_door, side)
		"E":
			_build_span(Vector2(half.x, -half.y), Vector2(half.x, half.y), false, has_door, side)


func _build_span(
	from: Vector2, to: Vector2, horizontal: bool, has_door: bool, side: String
) -> void:
	if not has_door:
		_add_wall_segment(from, to, horizontal)
		return

	var gap_half := DOOR_WIDTH / 2.0
	var mid := from.lerp(to, 0.5)

	var seg_a_to := to
	var seg_b_from := from
	if horizontal:
		seg_a_to.x = mid.x - gap_half
		seg_b_from.x = mid.x + gap_half
	else:
		seg_a_to.y = mid.y - gap_half
		seg_b_from.y = mid.y + gap_half

	_add_wall_segment(from, seg_a_to, horizontal)
	_add_wall_segment(seg_b_from, to, horizontal)
	_add_door(mid, side, horizontal)


func _add_wall_segment(from: Vector2, to: Vector2, horizontal: bool) -> void:
	var length: float = absf(to.x - from.x) if horizontal else absf(to.y - from.y)
	if length <= 0.5:
		return

	var center := from.lerp(to, 0.5)
	var size: Vector2 = (
		Vector2(length, WALL_THICKNESS) if horizontal else Vector2(WALL_THICKNESS, length)
	)

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = center
	add_child(body)

	var rect := ColorRect.new()
	rect.color = WALL_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = -size / 2.0
	rect.size = size
	body.add_child(rect)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	shape.shape = rect_shape
	body.add_child(shape)


func _add_door(center: Vector2, side: String, horizontal: bool) -> void:
	var size: Vector2 = (
		Vector2(DOOR_WIDTH, WALL_THICKNESS) if horizontal else Vector2(WALL_THICKNESS, DOOR_WIDTH)
	)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = center
	add_child(area)

	var rect := ColorRect.new()
	rect.color = DOOR_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = -size / 2.0
	rect.size = size
	area.add_child(rect)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	shape.shape = rect_shape
	area.add_child(shape)

	area.body_entered.connect(_on_door_body_entered.bind(side))


func _on_door_body_entered(body: Node, side: String) -> void:
	if body.is_in_group("player"):
		door_entered.emit(side)

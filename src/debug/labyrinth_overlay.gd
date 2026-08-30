extends Control
## Debug-only minimap for M2: draws the generated room graph in POLAR layout —
## concentric rings, colored by role, with the current room highlighted and
## radial (INWARD/OUTWARD) doors visually distinct from lateral (CW/CCW)
## ones. For the designer's eyes, not the player's — see
## docs/PROJECT_PLAN.md M2.

const NODE_RADIUS := 9.0
const RING_SPACING := 24.0
const RING_INNER_PAD := 14.0
const CENTER := Vector2(190, 210)

const ROLE_COLORS := {
	"start": Color(0.3, 0.9, 0.4),
	"normal": Color(0.75, 0.75, 0.8),
	"dead_end": Color(0.9, 0.75, 0.15),
	"exit": Color(0.85, 0.3, 0.9),
}

const RADIAL_DIRECTIONS := ["INWARD", "OUTWARD"]
const RADIAL_EDGE_COLOR := Color(0.95, 0.55, 0.25, 0.95)
const LATERAL_EDGE_COLOR := Color(0.5, 0.5, 0.55, 0.6)
const RING_GUIDE_COLOR := Color(0.35, 0.35, 0.4, 0.35)
const REWARD_RING_COLOR := Color(0.9, 0.75, 0.15, 1)

var _graph: Dictionary = {}
var _current_room_id: int = -1


func set_graph(graph: Dictionary, current_room_id: int) -> void:
	_graph = graph
	_current_room_id = current_room_id
	queue_redraw()


func set_current_room(current_room_id: int) -> void:
	_current_room_id = current_room_id
	queue_redraw()


func _ring_radius(ring: int, ring_count: int) -> float:
	return float(ring_count - ring) * RING_SPACING + RING_INNER_PAD


func _node_pos(node: Dictionary, ring_count: int) -> Vector2:
	var angle: float = TAU * float(node["ring_index"]) / float(node["ring_size"])
	var radius := _ring_radius(int(node["ring"]), ring_count)
	return CENTER + radius * Vector2(cos(angle), sin(angle))


func _draw() -> void:
	if _graph.is_empty():
		return

	var nodes: Dictionary = _graph["nodes"]
	var ring_count: int = _graph.get("ring_count", 1)

	for r in range(ring_count):
		draw_arc(CENTER, _ring_radius(r, ring_count), 0.0, TAU, 48, RING_GUIDE_COLOR, 1.0)

	var positions: Dictionary = {}
	for id in nodes.keys():
		positions[id] = _node_pos(nodes[id], ring_count)

	var drawn_edges: Dictionary = {}
	for id in nodes.keys():
		var edges: Dictionary = nodes[id]["edges"]
		for neighbor_id in edges.keys():
			var edge_key := "%d_%d" % [mini(id, neighbor_id), maxi(id, neighbor_id)]
			if drawn_edges.has(edge_key):
				continue
			drawn_edges[edge_key] = true

			var direction: String = edges[neighbor_id]
			var radial: bool = direction in RADIAL_DIRECTIONS
			var color: Color = RADIAL_EDGE_COLOR if radial else LATERAL_EDGE_COLOR
			var width: float = 2.5 if radial else 1.5
			draw_line(positions[id], positions[neighbor_id], color, width)

	for id in nodes.keys():
		var node: Dictionary = nodes[id]
		var color: Color = ROLE_COLORS.get(node["role"], Color.WHITE)
		var pos: Vector2 = positions[id]
		draw_circle(pos, NODE_RADIUS, color)
		if node.get("has_reward", false):
			draw_arc(pos, NODE_RADIUS + 3.5, 0.0, TAU, 16, REWARD_RING_COLOR, 1.5)
		if id == _current_room_id:
			draw_arc(pos, NODE_RADIUS + 5.5, 0.0, TAU, 24, Color.WHITE, 2.0)

	var outer_radius := _ring_radius(0, ring_count)
	var info_y := CENTER.y + outer_radius + 24.0
	var info := "seed=%d  depth=%d  luck=%d  rooms=%d  rings=%d" % [
		int(_graph.get("seed", 0)),
		int(_graph.get("depth", 0)),
		int(_graph.get("luck", 0)),
		nodes.size(),
		ring_count,
	]
	draw_string(ThemeDB.fallback_font, Vector2(10, info_y), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(10, info_y + 18.0),
		"SPACE=new seed  UP/DOWN=luck  LEFT/RIGHT=depth",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12
	)

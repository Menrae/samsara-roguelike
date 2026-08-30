class_name LabyrinthGen
extends RefCounted
## Generates a room GRAPH (nodes = rooms, edges = doors) from a seed. Pure and
## deterministic: the same seed+depth+luck always produces the same graph.
## depth and luck are passed in explicitly, not read from RunState — callers
## (M3's rift.gd via RoomManager) snapshot RunState.assignment.LUCK at the
## moment of generation and pass it in.
##
## Graph shape: concentric RINGS around a center. Ring 0 is outermost (start),
## the innermost ring holds the exit. Rooms in a ring form a cycle (CLOCKWISE /
## COUNTERCLOCKWISE doors) with some edges severed so a ring is never a
## guaranteed complete loop. Adjacent rings connect via a scarce set of radial
## (INWARD / OUTWARD) doors — luck controls how many. door_sides on the
## existing room templates ("N","E","S","W") are reused unchanged as the
## physical slots for these four logical directions. LUCK also controls how
## many non-start rooms carry a rift (node["rift_color"], "" if none).

const ROOM_TEMPLATE_DIR := "res://data/rooms/"

const DIRECTION_TO_SIDE := {
	"OUTWARD": "N",
	"INWARD": "S",
	"CLOCKWISE": "E",
	"COUNTERCLOCKWISE": "W",
}

const RIFT_COLORS := ["RED", "BLUE", "GREEN"]


static func generate(seed_value: int, depth: int, luck: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var templates := _load_templates()
	if templates.is_empty():
		push_error("LabyrinthGen: no room templates found in %s" % ROOM_TEMPLATE_DIR)
		return {}

	var ring_count: int = clampi(depth + 2, 2, 6)
	var ring_size: int = clampi(3 + depth, 3, 8)
	var radial_count: int = clampi(1 + int(luck / 2.0), 1, ring_size)

	var nodes := _build_rings(rng, ring_count, ring_size, radial_count)
	_assign_roles(rng, nodes, ring_count)
	_assign_rewards(rng, nodes, luck)
	_assign_rifts(rng, nodes, luck)
	_assign_templates(rng, nodes, templates)

	var exit_id := 0
	for id in nodes.keys():
		if nodes[id]["role"] == "exit":
			exit_id = id
			break

	return {
		"seed": seed_value,
		"depth": depth,
		"luck": luck,
		"nodes": nodes,
		"start_id": 0,
		"exit_id": exit_id,
		"room_count": nodes.size(),
		"ring_count": ring_count,
		"ring_size": ring_size,
	}


## Builds the ring cycles, severs some lateral edges per ring so no ring is a
## guaranteed complete loop, punches `radial_count` radial doors between each
## pair of adjacent rings, then repairs any lateral severing that left part of
## a ring unreachable from the start room (mirrors DECISIONS.md D-008: grow
## greedily, then backfill to restore the "everything reachable" invariant).
static func _build_rings(
	rng: RandomNumberGenerator, ring_count: int, ring_size: int, radial_count: int
) -> Dictionary:
	var nodes: Dictionary = {}
	var ring_ids: Array = []
	var next_id := 0
	for r in range(ring_count):
		var ids: Array = []
		for i in range(ring_size):
			var id := next_id
			next_id += 1
			nodes[id] = {
				"id": id,
				"ring": r,
				"ring_index": i,
				"ring_size": ring_size,
				"neighbors": [],
				"edges": {},
				"role": "normal",
			}
			ids.append(id)
		ring_ids.append(ids)

	nodes[ring_ids[0][0]]["role"] = "start"

	var severed: Array = []
	for r in range(ring_count):
		var ids: Array = ring_ids[r]
		var n: int = ids.size()
		var sever_target: int = rng.randi_range(1, maxi(1, n / 2))
		var sever_set: Dictionary = {}
		while sever_set.size() < sever_target:
			sever_set[rng.randi_range(0, n - 1)] = true
		severed.append(sever_set)
		for i in range(n):
			if sever_set.has(i):
				continue
			_link(nodes, ids[i], ids[(i + 1) % n], "CLOCKWISE", "COUNTERCLOCKWISE")

	for r in range(ring_count - 1):
		var from_ids: Array = ring_ids[r]
		var to_ids: Array = ring_ids[r + 1]
		var n: int = from_ids.size()
		var indices: Array = []
		for i in range(n):
			indices.append(i)
		_seeded_shuffle(indices, rng)
		for k in range(mini(radial_count, n)):
			var idx: int = indices[k]
			_link(nodes, from_ids[idx], to_ids[idx], "INWARD", "OUTWARD")

	_repair_connectivity(nodes, ring_ids, severed)

	return nodes


static func _link(
	nodes: Dictionary, a_id: int, b_id: int, a_to_b_dir: String, b_to_a_dir: String
) -> void:
	var a_edges: Dictionary = nodes[a_id]["edges"]
	if not a_edges.has(b_id):
		a_edges[b_id] = a_to_b_dir
		(nodes[a_id]["neighbors"] as Array).append(b_id)
	var b_edges: Dictionary = nodes[b_id]["edges"]
	if not b_edges.has(a_id):
		b_edges[a_id] = b_to_a_dir
		(nodes[b_id]["neighbors"] as Array).append(a_id)


static func _repair_connectivity(nodes: Dictionary, ring_ids: Array, severed: Array) -> void:
	var start_id: int = ring_ids[0][0]
	var reached := _bfs_reachable(nodes, start_id)
	while reached.size() < nodes.size():
		var fixed := false
		for id in nodes.keys():
			if reached.has(id):
				continue
			var node: Dictionary = nodes[id]
			var r: int = node["ring"]
			var i: int = node["ring_index"]
			var ids: Array = ring_ids[r]
			var n: int = ids.size()
			var next_i := (i + 1) % n
			var prev_i := (i - 1 + n) % n
			var sever_set: Dictionary = severed[r]
			if sever_set.has(i):
				_link(nodes, ids[i], ids[next_i], "CLOCKWISE", "COUNTERCLOCKWISE")
				sever_set.erase(i)
				fixed = true
			elif sever_set.has(prev_i):
				_link(nodes, ids[prev_i], ids[i], "CLOCKWISE", "COUNTERCLOCKWISE")
				sever_set.erase(prev_i)
				fixed = true
			if fixed:
				break
		if not fixed:
			break
		reached = _bfs_reachable(nodes, start_id)


static func _bfs_reachable(nodes: Dictionary, start_id: int) -> Dictionary:
	var reached := {start_id: true}
	var queue: Array = [start_id]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		for neighbor_id in (nodes[current]["neighbors"] as Array):
			if not reached.has(neighbor_id):
				reached[neighbor_id] = true
				queue.append(neighbor_id)
	return reached


## The exit is a single room, chosen per-seed, in the innermost ring. Any
## other room left with only one door (after severing/repair) reads as a
## dead end regardless of which ring it's in.
static func _assign_roles(rng: RandomNumberGenerator, nodes: Dictionary, ring_count: int) -> void:
	var innermost: Array = []
	for id in nodes.keys():
		if nodes[id]["ring"] == ring_count - 1:
			innermost.append(id)
	var exit_id: int = innermost[rng.randi_range(0, innermost.size() - 1)]
	nodes[exit_id]["role"] = "exit"

	for id in nodes.keys():
		var node: Dictionary = nodes[id]
		if node["role"] != "normal":
			continue
		if (node["neighbors"] as Array).size() <= 1:
			node["role"] = "dead_end"


## Luck's secondary lever: dead ends always hold a reward; other rooms get an
## increasing chance of one too as luck rises.
static func _assign_rewards(rng: RandomNumberGenerator, nodes: Dictionary, luck: int) -> void:
	var reward_chance: float = clampf(float(luck) * 0.03, 0.0, 0.3)
	for id in nodes.keys():
		var node: Dictionary = nodes[id]
		if node["role"] == "dead_end":
			node["has_reward"] = true
		else:
			node["has_reward"] = node["role"] == "normal" and rng.randf() < reward_chance


## LUCK's third lever (alongside radial_count and reward density): how many
## non-start rooms carry a rift, and which color. Scaled the same way as
## radial doors — findable but not guaranteed, capped well under "every
## room" so rifts stay a deliberate detour rather than wallpaper.
static func _assign_rifts(rng: RandomNumberGenerator, nodes: Dictionary, luck: int) -> void:
	var eligible: Array = []
	for id in nodes.keys():
		var node: Dictionary = nodes[id]
		node["rift_color"] = ""
		if node["role"] != "start":
			eligible.append(id)

	var max_rifts: int = maxi(1, eligible.size() / 3)
	var rift_count: int = clampi(1 + int(luck / 3.0), 0, mini(max_rifts, eligible.size()))

	_seeded_shuffle(eligible, rng)
	for i in range(rift_count):
		var id: int = eligible[i]
		nodes[id]["rift_color"] = RIFT_COLORS[rng.randi_range(0, RIFT_COLORS.size() - 1)]


static func _assign_templates(
	rng: RandomNumberGenerator, nodes: Dictionary, templates: Array
) -> void:
	for id in nodes.keys():
		var node: Dictionary = nodes[id]
		var edges: Dictionary = node["edges"]

		var required_sides: Dictionary = {}
		for neighbor_id in edges.keys():
			var direction: String = edges[neighbor_id]
			required_sides[DIRECTION_TO_SIDE[direction]] = true

		var candidates: Array = templates.filter(func(t):
			var sides: Array = t["door_sides"]
			for side in required_sides.keys():
				if not sides.has(side):
					return false
			return true
		)
		if candidates.is_empty():
			candidates = templates
		var chosen: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		node["template_path"] = chosen["path"]

		var door_map: Dictionary = {}
		for neighbor_id in edges.keys():
			var direction: String = edges[neighbor_id]
			door_map[DIRECTION_TO_SIDE[direction]] = neighbor_id
		node["door_map"] = door_map


static func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _load_templates() -> Array:
	var templates: Array = []
	var dir := DirAccess.open(ROOM_TEMPLATE_DIR)
	if dir == null:
		return templates

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			var path := ROOM_TEMPLATE_DIR + file_name
			var packed: PackedScene = load(path)
			var instance: RoomTemplate = packed.instantiate()
			templates.append({
				"path": path,
				"room_size": instance.room_size,
				"door_sides": instance.door_sides.duplicate(),
			})
			instance.free()
		file_name = dir.get_next()
	dir.list_dir_end()

	templates.sort_custom(func(a, b): return a["path"] < b["path"])
	return templates

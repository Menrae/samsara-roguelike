extends Node2D
## Player weapon component — a child of the player, not logic inside player.gd.
## This is the seam items modify at M4, so it stays separate. Fires toward the
## mouse position on click or hold. base_fire_rate/base_damage are the M1
## constants; SPEED/POWER scale them via Stats.scale, read fresh on every
## shot (not cached) — see docs/PROJECT_PLAN.md §1.

@export var projectile_scene: PackedScene
@export var base_fire_rate: float = 4.0  # shots per second, before SPEED scaling
@export var projectile_speed: float = 600.0
@export var base_damage: float = 10.0  # before POWER scaling
@export var projectile_count: int = 1
@export var spread: float = 0.0  # degrees, full spread across all projectiles

var _cooldown: float = 0.0


func _process(delta: float) -> void:
	_cooldown = max(_cooldown - delta, 0.0)
	if Input.is_action_pressed("fire") and _cooldown <= 0.0:
		_fire()
		_cooldown = 1.0 / (base_fire_rate * _speed_scale())


func _fire() -> void:
	if projectile_scene == null:
		return

	var base_angle := global_position.direction_to(get_global_mouse_position()).angle()
	var spread_rad := deg_to_rad(spread)

	for i in range(projectile_count):
		var offset := 0.0
		if projectile_count > 1:
			offset = spread_rad * (float(i) / float(projectile_count - 1) - 0.5)
		_spawn_projectile(base_angle + offset)


func _spawn_projectile(angle: float) -> void:
	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = Vector2.from_angle(angle)
	projectile.speed = projectile_speed
	projectile.damage = base_damage * _power_scale()


func _speed_scale() -> float:
	return Stats.scale(RunState.assignment.get("SPEED", 0.0), RunState.stat_values)


func _power_scale() -> float:
	return Stats.scale(RunState.assignment.get("POWER", 0.0), RunState.stat_values)

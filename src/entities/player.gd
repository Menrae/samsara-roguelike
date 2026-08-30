extends CharacterBody2D
## Player entity: 8-directional WASD movement, takes damage, flashes through
## brief i-frames, and emits EventBus.player_died(cause) at 0 HP. Firing
## lives in weapon.gd (a sibling component), not here. base_move_speed is
## the M1 constant; SPEED scales it via Stats.scale, read every physics
## frame (not cached) so a permutation is felt immediately — see
## docs/PROJECT_PLAN.md §1.

@export var base_move_speed: float = 220.0
@export var max_health: float = 100.0
@export var iframe_duration: float = 0.6
@export var flash_interval: float = 0.08

var health: float

var _invincible: bool = false
var _flash_timer: float = 0.0
var _flash_on: bool = true

@onready var _visual: ColorRect = $ColorRect


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	var speed_scale := Stats.scale(RunState.assignment.get("SPEED", 0.0), RunState.stat_values)
	velocity = input_dir * base_move_speed * speed_scale
	move_and_slide()

	if _invincible:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_timer = flash_interval
			_flash_on = not _flash_on
			_visual.visible = _flash_on


func take_damage(amount: float, source: String = "unknown") -> void:
	if _invincible or health <= 0.0:
		return

	health -= amount
	if health <= 0.0:
		_die(source)
		return

	_invincible = true
	_flash_timer = flash_interval
	get_tree().create_timer(iframe_duration).timeout.connect(_end_iframes)


func _end_iframes() -> void:
	_invincible = false
	_visual.visible = true


func _die(cause: String) -> void:
	EventBus.player_died.emit(cause)
	queue_free()

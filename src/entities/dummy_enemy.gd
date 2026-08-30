extends Area2D
## Stationary target: has health, takes projectile damage, deals contact damage
## on overlap, frees itself on death. No AI, no movement, no pathfinding — it
## exists to shoot at.

@export var max_health: float = 30.0
@export var contact_damage: float = 10.0
@export var contact_tick_interval: float = 0.5

var health: float

@onready var _contact_timer: Timer = $ContactTimer


func _ready() -> void:
	health = max_health
	_contact_timer.wait_time = contact_tick_interval
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_contact_timer.timeout.connect(_on_contact_tick)


func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_contact_timer.start()
		_on_contact_tick()


func _on_body_exited(_body: Node) -> void:
	if get_overlapping_bodies().is_empty():
		_contact_timer.stop()


func _on_contact_tick() -> void:
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(contact_damage, "dummy_enemy")

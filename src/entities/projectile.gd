extends Area2D
## Player projectile: travels in a straight line, damages the first thing it
## hits, and frees itself on wall contact or lifetime expiry. Its own scene so
## items can modify or replace it later.

const LIFETIME := 2.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 10.0

var _age: float = 0.0


func _ready() -> void:
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	queue_free()


func _on_body_entered(_body: Node) -> void:
	queue_free()

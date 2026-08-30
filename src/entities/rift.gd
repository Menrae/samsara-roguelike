class_name Rift
extends Area2D
## An enterable chromatic rift. Never triggers on overlap alone — requires a
## deliberate "interact" press while the player is standing on it. On
## activation it permutes RunState's stat assignment (this color's stat
## guaranteed highest) and emits EventBus.rift_entered; the labyrinth
## regeneration / ring-preserving handoff is RoomManager's job, reacting to
## that signal, not this node's — rift.gd holds no reference to RoomManager
## (CLAUDE.md: systems talk through EventBus, not direct references).

const COLOR_TO_STAT := {
	"RED": "POWER",
	"BLUE": "SPEED",
	"GREEN": "LUCK",
}
const COLOR_VALUES := {
	"RED": Color(0.85, 0.2, 0.2),
	"BLUE": Color(0.25, 0.45, 0.9),
	"GREEN": Color(0.25, 0.8, 0.35),
}

@export var color: String = "RED"  # RED | BLUE | GREEN

var _player_inside: bool = false

@onready var _visual: ColorRect = $ColorRect
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	_visual.color = COLOR_VALUES.get(color, Color.WHITE)
	_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		_enter()
		get_viewport().set_input_as_handled()


func _enter() -> void:
	RunState.permute(COLOR_TO_STAT.get(color, ""))
	RunState.rifts_taken += 1
	EventBus.rift_entered.emit(color, "none")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_prompt.visible = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_prompt.visible = false

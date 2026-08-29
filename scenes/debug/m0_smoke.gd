extends Node
## M0 smoke test: keypress emits EventBus.karma_shifted, a listener in this scene
## prints it, and the missing-texture placeholder path is exercised on ready.


func _ready() -> void:
	EventBus.karma_shifted.connect(_on_karma_shifted)
	Textures.item_texture("does_not_exist")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		EventBus.karma_shifted.emit(1.0, "m0_smoke_keypress")


func _on_karma_shifted(delta: float, source: String) -> void:
	print("karma_shifted: delta=%s source=%s" % [delta, source])

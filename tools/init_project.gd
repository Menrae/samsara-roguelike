extends SceneTree

func _init():
	ProjectSettings.set_setting("application/config/name", "samsara-roguelike")
	ProjectSettings.save()
	quit()

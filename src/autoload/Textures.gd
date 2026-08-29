extends Node
## Resolves texture paths by convention from an id — no path is ever stored in a
## Resource. Missing art returns a magenta placeholder, never broken/blank (D-001).

const PLACEHOLDER_SIZE := 32

var _cache: Dictionary = {}


func item_texture(id: String) -> Texture2D:
	return _resolve("res://assets/sprites/items/%s.png" % id)


func enemy_texture(id: String) -> Texture2D:
	return _resolve("res://assets/sprites/enemies/%s.png" % id)


func rift_texture(color: String) -> Texture2D:
	return _resolve("res://assets/sprites/rifts/%s.png" % color)


func _resolve(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]

	var texture: Texture2D
	if ResourceLoader.exists(path):
		texture = load(path)
	else:
		push_warning("Missing texture: %s" % path)
		texture = _placeholder()

	_cache[path] = texture
	return texture


func _placeholder() -> Texture2D:
	var image := Image.create(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.MAGENTA)
	return ImageTexture.create_from_image(image)

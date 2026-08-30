extends Control
## Persistent HUD showing the current stat assignment. This is M3's signature
## moment (docs/PROJECT_PLAN.md §1): on EventBus.stats_permuted, each value
## visibly FLIES from the row of the stat that used to hold it to the row of
## the stat that holds it now, instead of just snapping numbers — plus a
## brief pulse on whichever stat lands highest.

const STAT_NAMES := ["POWER", "SPEED", "LUCK"]
const STAT_COLORS := {
	"POWER": Color(0.85, 0.3, 0.3),
	"SPEED": Color(0.35, 0.55, 0.9),
	"LUCK": Color(0.4, 0.8, 0.45),
}
const ROW_HEIGHT := 40.0
const ROW_SPACING := 10.0
const BAR_MAX_WIDTH := 220.0
const NAME_WIDTH := 60.0
const FLIGHT_DURATION := 0.6

var _rows: Dictionary = {}  # stat_name -> {row, bar, value_label}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_rows()
	_refresh(RunState.assignment)
	EventBus.stats_permuted.connect(_on_stats_permuted)


func _build_rows() -> void:
	var title := Label.new()
	title.text = "STATS"
	title.position = Vector2(0, -28)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	for i in range(STAT_NAMES.size()):
		var stat_name: String = STAT_NAMES[i]
		var row := Control.new()
		row.position = Vector2(0, i * (ROW_HEIGHT + ROW_SPACING))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)

		var name_label := Label.new()
		name_label.text = stat_name
		name_label.position = Vector2(0, 8)
		name_label.custom_minimum_size = Vector2(NAME_WIDTH, ROW_HEIGHT)
		name_label.add_theme_color_override("font_color", STAT_COLORS[stat_name])
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_label)

		var bar_bg := ColorRect.new()
		bar_bg.color = Color(1, 1, 1, 0.08)
		bar_bg.position = Vector2(NAME_WIDTH, 8)
		bar_bg.size = Vector2(BAR_MAX_WIDTH, ROW_HEIGHT - 16)
		bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar_bg)

		var bar := ColorRect.new()
		bar.color = STAT_COLORS[stat_name]
		bar.position = Vector2(NAME_WIDTH, 8)
		bar.size = Vector2(0, ROW_HEIGHT - 16)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)

		var value_label := Label.new()
		value_label.position = Vector2(NAME_WIDTH + BAR_MAX_WIDTH + 12, 8)
		value_label.custom_minimum_size = Vector2(40, ROW_HEIGHT)
		value_label.visible = false
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(value_label)

		_rows[stat_name] = {"row": row, "bar": bar, "value_label": value_label}


func _on_stats_permuted(old_assignment: Dictionary, new_assignment: Dictionary) -> void:
	_animate_permutation(old_assignment, new_assignment)
	_pulse_highest(new_assignment)


## Static, non-animated refresh — used once on boot before any permutation
## has happened yet.
func _refresh(assignment: Dictionary) -> void:
	for stat_name in STAT_NAMES:
		_set_row_value(stat_name, float(assignment.get(stat_name, 0.0)))


func _animate_permutation(old_assignment: Dictionary, new_assignment: Dictionary) -> void:
	var pool: Array = STAT_NAMES.filter(func(s): return old_assignment.has(s))
	for target_stat in STAT_NAMES:
		var new_value: float = float(new_assignment.get(target_stat, 0.0))
		var source_stat := _pop_matching_source(pool, old_assignment, new_value, target_stat)
		if source_stat == "":
			source_stat = target_stat
		_fly_value(source_stat, target_stat, new_value)


## Prefers "this stat kept its own value" (no visible movement needed) before
## searching the rest of the pool, and removes whatever it matches so two
## target stats never claim the same source when values repeat.
func _pop_matching_source(
	pool: Array, old_assignment: Dictionary, value: float, prefer: String
) -> String:
	if pool.has(prefer) and is_equal_approx(float(old_assignment.get(prefer, -1.0)), value):
		pool.erase(prefer)
		return prefer
	for stat_name in pool:
		if is_equal_approx(float(old_assignment.get(stat_name, -1.0)), value):
			pool.erase(stat_name)
			return stat_name
	return ""


func _fly_value(source_stat: String, target_stat: String, value: float) -> void:
	var source_row: Dictionary = _rows[source_stat]
	var target_row: Dictionary = _rows[target_stat]
	var target_bar: ColorRect = target_row["bar"]
	var target_label: Label = target_row["value_label"]

	target_label.visible = false

	var chip := Label.new()
	chip.text = str(int(value))
	chip.add_theme_font_size_override("font_size", 20)
	chip.add_theme_color_override("font_color", STAT_COLORS[target_stat])
	chip.z_index = 10
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chip)
	chip.global_position = (source_row["value_label"] as Label).global_position
	chip.modulate.a = 0.0

	var target_width: float = _bar_width(value)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(chip, "modulate:a", 1.0, 0.15)
	(
		tween.tween_property(chip, "global_position", target_label.global_position, FLIGHT_DURATION)
		.set_trans(Tween.TRANS_CUBIC)
		.set_ease(Tween.EASE_OUT)
	)
	(
		tween.tween_property(target_bar, "size:x", target_width, FLIGHT_DURATION)
		.set_trans(Tween.TRANS_CUBIC)
		.set_ease(Tween.EASE_OUT)
	)
	tween.set_parallel(false)
	tween.tween_callback(func():
		target_label.text = str(int(value))
		target_label.visible = true
		chip.queue_free()
	)


func _pulse_highest(new_assignment: Dictionary) -> void:
	var highest_stat := ""
	var highest_value := -INF
	for stat_name in STAT_NAMES:
		var value: float = float(new_assignment.get(stat_name, 0.0))
		if value > highest_value:
			highest_value = value
			highest_stat = stat_name
	if highest_stat == "":
		return

	var row: Control = _rows[highest_stat]["row"]
	row.pivot_offset = Vector2(0, ROW_HEIGHT / 2.0)
	var tween := create_tween()
	tween.tween_interval(FLIGHT_DURATION * 0.7)
	tween.tween_property(row, "scale", Vector2(1.08, 1.08), 0.15)
	tween.tween_property(row, "scale", Vector2.ONE, 0.2)


func _set_row_value(stat_name: String, value: float) -> void:
	var row: Dictionary = _rows[stat_name]
	var value_label: Label = row["value_label"]
	value_label.text = str(int(value))
	value_label.visible = true
	(row["bar"] as ColorRect).size.x = _bar_width(value)


func _bar_width(value: float) -> float:
	var total := _total_stat_value()
	if total <= 0.0:
		return 0.0
	return BAR_MAX_WIDTH * value / total


func _total_stat_value() -> float:
	var total := 0.0
	for v in RunState.stat_values:
		total += v
	return total

class_name DebugOverlay
extends Control

# Per-cell axis debug view: toggled with "d", draws each cell's axis values
# (see GridCell.get_debug_values()) as single-letter-labelled text over the cell.

const AXIS_ORDER := ["T", "P", "E", "A", "S", "C", "I"]
const AXIS_COLORS := {
	"T": Color(0.95, 0.35, 0.10),
	"P": Color(0.40, 0.65, 1.00),
	"E": Color(0.95, 0.90, 0.25),
	"A": Color(0.75, 0.35, 0.95),
	"S": Color(0.70, 0.70, 0.70),
	"C": Color(0.30, 0.85, 0.55),
	"I": Color(0.90, 0.87, 0.78),
}
const LINE_HEIGHT := 14.0
const FONT_SIZE := 12

@export var world_simulation: WorldSimulation
@export var camera: Camera3D

var _enabled := false
var _font: Font
var _mode_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = ThemeDB.fallback_font
	set_process(false)
	_create_mode_label()


func _create_mode_label() -> void:
	_mode_label = Label.new()
	_mode_label.text = "DEBUG MODE"
	_mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.10))
	_mode_label.add_theme_font_size_override("font_size", 20)
	_mode_label.anchor_left = 0.0
	_mode_label.anchor_right = 1.0
	_mode_label.offset_left = 0.0
	_mode_label.offset_right = 0.0
	_mode_label.offset_top = 0.0
	_mode_label.offset_bottom = 28.0
	_mode_label.visible = false
	add_child(_mode_label)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_D and event.pressed and not event.echo:
		_enabled = not _enabled
		_mode_label.visible = _enabled
		set_process(_enabled)
		queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not _enabled or not world_simulation or not camera:
		return
	for index in world_simulation.get_cell_indices():
		var cell := world_simulation.get_cell(index)
		if not cell:
			continue
		var world_pos: Vector3 = world_simulation.grid.to_global(world_simulation.grid.map_to_local(index))
		if camera.is_position_behind(world_pos):
			continue
		var screen_pos := camera.unproject_position(world_pos)
		_draw_cell_values(screen_pos, cell.get_debug_values())


func _draw_cell_values(screen_pos: Vector2, values: Dictionary) -> void:
	var rows: Array[String] = []
	for label in AXIS_ORDER:
		if values.has(label) and not is_zero_approx(values[label]):
			rows.append(label)

	var start_y := screen_pos.y - (LINE_HEIGHT * rows.size()) * 0.5
	for row in rows.size():
		var label: String = rows[row]
		var text := "%s %.2f" % [label, values[label]]
		var pos := Vector2(screen_pos.x - 16.0, start_y + row * LINE_HEIGHT)
		draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, AXIS_COLORS.get(label, Color.WHITE))

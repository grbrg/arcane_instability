class_name BuildSelectionScreen
extends Control

const CONFIG_PATH := "res://ui/modifier_availability.json"
const SAVE_PATH := "user://build_selections.cfg"
const EXPERIMENTAL_STATION_SCENE := "res://levels/experimental/experimental_station.tscn"
const TITLE_MENU_SCENE := "res://ui/TitleMenu.tscn"

const CAST_NAMES := ["Energy", "Conduction", "Impulse", "Structure"]
const MODIFIER_TYPES := ["area", "distance", "energy_type", "extension"]

const MODIFIER_LABELS := {
	"area": "Area",
	"distance": "Distance",
	"energy_type": "Type",
	"extension": "Extension",
}

const MODIFIER_VALUES := {
	"area":        ["POINT", "PROJECTILE", "BEAM", "AREA"],
	"distance":    ["AROUND_PLAYER", "SHORT", "MIDDLE", "FAR"],
	"energy_type": ["THERMAL", "ELECTRICAL", "ARCANE"],
	"extension":   ["BOUNCING", "PIERCING", "EXPLOSION"],
}

const MODIFIER_DISPLAY := {
	"area": {
		"POINT": "Point", "PROJECTILE": "Projectile", "BEAM": "Beam", "AREA": "Area",
	},
	"distance": {
		"AROUND_PLAYER": "Around", "SHORT": "Short", "MIDDLE": "Middle", "FAR": "Far",
	},
	"energy_type": {
		"THERMAL": "Thermal", "ELECTRICAL": "Electric", "ARCANE": "Arcane",
	},
	"extension": {
		"BOUNCING": "Bouncing", "PIERCING": "Piercing", "EXPLOSION": "Explode",
	},
}

const PLAYER_COLORS := [
	Color(1.0,  0.13, 0.13),  # Red
	Color(0.13, 0.40, 1.0),   # Blue
	Color(0.00, 0.87, 0.27),  # Green
	Color(1.0,  0.93, 0.00),  # Yellow
	Color(0.73, 0.13, 1.0),   # Purple
	Color(1.0,  0.53, 0.00),  # Orange
	Color(0.00, 0.93, 0.93),  # Cyan
	Color(1.0,  0.40, 0.67),  # Pink
	Color(0.94, 0.94, 0.94),  # White
	Color(0.53, 1.0,  0.00),  # Lime
	Color(0.00, 0.73, 0.67),  # Teal
	Color(0.67, 0.33, 0.00),  # Brown
	Color(1.0,  0.40, 0.27),  # Coral
	Color(0.27, 0.67, 1.0),   # Sky Blue
	Color(0.47, 0.13, 0.80),  # Violet
	Color(1.0,  0.84, 0.00),  # Gold
]

const NUM_PLAYERS := 4

const C_BG         := Color(0.03, 0.02, 0.01)
const C_PANEL      := Color(0.07, 0.06, 0.04, 0.93)
const C_SECTION_BG := Color(0.10, 0.09, 0.06)
const C_BORDER     := Color(0.75, 0.55, 0.10)
const C_BORDER_DIM := Color(0.35, 0.26, 0.06)
const C_TEXT       := Color(0.90, 0.87, 0.78)
const C_TEXT_DIM   := Color(0.52, 0.48, 0.36)
const C_TITLE      := Color(0.88, 0.70, 0.20)
const C_HOVER      := Color(0.13, 0.11, 0.07)
const C_PRESSED    := Color(0.22, 0.16, 0.05)
const C_WARNING    := Color(0.95, 0.35, 0.10)
const C_BTN_NORMAL := Color(0.08, 0.07, 0.04)

const _Validator := preload("res://spells/modifiers/modifier_validator.gd")
const _Registry := preload("res://core/build_registry.gd")

var _availability: Dictionary = {}
var _invalid_rules: Array = []
var _player_data: Array = []
var _player_ui: Array = []

var _back_btn: Button = null
var _start_btn: Button = null
var _navs: Array = []         # per-player nav state dicts
var _joy_cooldown: Array = [] # per-player axis cooldown (seconds)


func _ready() -> void:
	_load_config()
	_init_player_data()
	_load_saved()
	_build_ui()
	await get_tree().process_frame
	_setup_navigation()


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		push_warning("BuildSelection: cannot open config '%s', using defaults" % CONFIG_PATH)
		_use_default_availability()
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("BuildSelection: invalid JSON in config, using defaults")
		_use_default_availability()
		return
	var data: Dictionary = json.get_data()
	_availability = data.get("availability", {})
	_invalid_rules = data.get("invalid_combinations", [])
	for mod_type in MODIFIER_TYPES:
		if not _availability.has(mod_type):
			_availability[mod_type] = {}
		for val in MODIFIER_VALUES[mod_type]:
			if not _availability[mod_type].has(val):
				_availability[mod_type][val] = true


func _use_default_availability() -> void:
	for mod_type in MODIFIER_TYPES:
		_availability[mod_type] = {}
		for val in MODIFIER_VALUES[mod_type]:
			_availability[mod_type][val] = true


func _init_player_data() -> void:
	_player_data.clear()
	for i in NUM_PLAYERS:
		var casts: Dictionary = {}
		for cast in CAST_NAMES:
			casts[cast] = {
				"area": "POINT",
				"distance": "SHORT",
				"energy_type": "THERMAL",
				"extension": "PIERCING",
			}
		_player_data.append({
			"name": "Player %d" % (i + 1),
			"color_index": i % PLAYER_COLORS.size(),
			"casts": casts,
		})


func _load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for i in NUM_PLAYERS:
		var section := "player%d" % i
		if not cfg.has_section(section):
			continue
		_player_data[i]["name"] = cfg.get_value(section, "name", _player_data[i]["name"])
		var saved_color: int = cfg.get_value(section, "color_index", _player_data[i]["color_index"])
		_player_data[i]["color_index"] = clampi(saved_color, 0, PLAYER_COLORS.size() - 1)
		for cast in CAST_NAMES:
			for mod in MODIFIER_TYPES:
				var key := "%s_%s" % [cast.to_lower(), mod]
				var saved: String = cfg.get_value(section, key, "")
				if saved in MODIFIER_VALUES[mod]:
					_player_data[i]["casts"][cast][mod] = saved


func _save() -> void:
	var cfg := ConfigFile.new()
	for i in NUM_PLAYERS:
		var section := "player%d" % i
		cfg.set_value(section, "name", _player_data[i]["name"])
		cfg.set_value(section, "color_index", _player_data[i]["color_index"])
		for cast in CAST_NAMES:
			for mod in MODIFIER_TYPES:
				cfg.set_value(section, "%s_%s" % [cast.to_lower(), mod], _player_data[i]["casts"][cast][mod])
	cfg.save(SAVE_PATH)


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	theme = preload("res://ui/theme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	_add_header(root_vbox)
	root_vbox.add_child(_make_h_separator())

	var cards_margin := MarginContainer.new()
	cards_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_margin.add_theme_constant_override("margin_left", 16)
	cards_margin.add_theme_constant_override("margin_right", 16)
	cards_margin.add_theme_constant_override("margin_top", 10)
	cards_margin.add_theme_constant_override("margin_bottom", 10)
	root_vbox.add_child(cards_margin)

	var cards_hbox := HBoxContainer.new()
	cards_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_hbox.add_theme_constant_override("separation", 12)
	cards_margin.add_child(cards_hbox)

	_player_ui.clear()
	for i in NUM_PLAYERS:
		_create_player_card(i, cards_hbox)

	root_vbox.add_child(_make_h_separator())
	_add_bottom_bar(root_vbox)


func _add_header(parent: Control) -> void:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var label := Label.new()
	label.text = "BUILD SELECTION"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", C_TITLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)


func _add_bottom_bar(parent: Control) -> void:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_l)

	_back_btn = Button.new()
	_back_btn.text = "Back"
	_back_btn.custom_minimum_size = Vector2(140, 44)
	_back_btn.pressed.connect(_on_back_pressed)
	hbox.add_child(_back_btn)

	_start_btn = Button.new()
	_start_btn.text = "Start"
	_start_btn.custom_minimum_size = Vector2(140, 44)
	_start_btn.pressed.connect(_on_start_pressed)
	hbox.add_child(_start_btn)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_r)


func _make_h_separator() -> HSeparator:
	return HSeparator.new()


func _create_player_card(player_idx: int, parent: Control) -> void:
	var player_color: Color = PLAYER_COLORS[_player_data[player_idx]["color_index"]]

	var card_panel := PanelContainer.new()
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = C_PANEL
	card_style.set_border_width_all(1)
	card_style.border_color = player_color
	card_style.set_corner_radius_all(0)
	card_style.set_content_margin_all(10.0)
	card_panel.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	var ui: Dictionary = {
		"card_style": card_style,
		"scroll": scroll,
		"name_edit": null,
		"color_buttons": [],
		"options": {},
		"warnings": {},
		"cooldown_labels": {},
	}

	# --- Player name ---
	var name_edit := LineEdit.new()
	name_edit.text = _player_data[player_idx]["name"]
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.add_theme_font_size_override("font_size", 20)
	name_edit.add_theme_color_override("font_color", player_color)
	name_edit.custom_minimum_size.y = 36
	name_edit.text_changed.connect(_on_name_changed.bind(player_idx))
	vbox.add_child(name_edit)
	ui["name_edit"] = name_edit

	vbox.add_child(_make_h_separator())

	# --- Color picker ---
	var color_row := HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 8)
	vbox.add_child(color_row)

	var color_label := Label.new()
	color_label.text = "Color"
	color_label.add_theme_font_size_override("font_size", 13)
	color_label.add_theme_color_override("font_color", C_TEXT_DIM)
	color_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	color_row.add_child(color_label)

	var color_grid := GridContainer.new()
	color_grid.columns = 8
	color_grid.add_theme_constant_override("h_separation", 4)
	color_grid.add_theme_constant_override("v_separation", 4)
	color_row.add_child(color_grid)

	for ci in PLAYER_COLORS.size():
		var cbtn := Button.new()
		cbtn.custom_minimum_size = Vector2(26, 26)
		cbtn.focus_mode = Control.FOCUS_NONE
		_style_color_button(cbtn, ci, ci == _player_data[player_idx]["color_index"])
		cbtn.pressed.connect(_on_color_selected.bind(ci, player_idx))
		color_grid.add_child(cbtn)
		ui["color_buttons"].append(cbtn)

	vbox.add_child(_make_h_separator())

	# --- Cast sections ---
	for cast in CAST_NAMES:
		ui["options"][cast] = {}
		_create_cast_section(player_idx, cast, vbox, ui)

	# --- Load / Save buttons ---
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var load_btn := Button.new()
	load_btn.text = "Load Build"
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_btn.custom_minimum_size.y = 34
	load_btn.pressed.connect(_on_load_build.bind(player_idx))
	btn_row.add_child(load_btn)
	ui["load_btn"] = load_btn

	var save_btn := Button.new()
	save_btn.text = "Save Build"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.custom_minimum_size.y = 34
	save_btn.pressed.connect(_on_save_build.bind(player_idx))
	btn_row.add_child(save_btn)
	ui["save_btn"] = save_btn

	_player_ui.append(ui)

	for cast in CAST_NAMES:
		_validate_cast(player_idx, cast)


func _create_cast_section(player_idx: int, cast_name: String, parent: VBoxContainer, ui: Dictionary) -> void:
	var section_panel := PanelContainer.new()
	var section_style := StyleBoxFlat.new()
	section_style.bg_color = C_SECTION_BG
	section_style.set_border_width_all(1)
	section_style.border_color = C_BORDER_DIM
	section_style.set_corner_radius_all(0)
	section_style.set_content_margin_all(6.0)
	section_panel.add_theme_stylebox_override("panel", section_style)
	parent.add_child(section_panel)

	var section_vbox := VBoxContainer.new()
	section_vbox.add_theme_constant_override("separation", 4)
	section_panel.add_child(section_vbox)

	# Header: cast name + warning indicator
	var header_hbox := HBoxContainer.new()
	section_vbox.add_child(header_hbox)

	var cast_label := Label.new()
	cast_label.text = cast_name
	cast_label.add_theme_font_size_override("font_size", 15)
	cast_label.add_theme_color_override("font_color", C_TITLE)
	cast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(cast_label)

	var cooldown_label := Label.new()
	cooldown_label.add_theme_font_size_override("font_size", 13)
	cooldown_label.add_theme_color_override("font_color", C_TEXT_DIM)
	header_hbox.add_child(cooldown_label)
	ui["cooldown_labels"][cast_name] = cooldown_label

	var warn_label := Label.new()
	warn_label.text = "Invalid combo"
	warn_label.add_theme_font_size_override("font_size", 11)
	warn_label.add_theme_color_override("font_color", C_WARNING)
	warn_label.visible = false
	header_hbox.add_child(warn_label)
	ui["warnings"][cast_name] = warn_label

	# 2x2 modifier grid
	var mod_grid := GridContainer.new()
	mod_grid.columns = 2
	mod_grid.add_theme_constant_override("h_separation", 6)
	mod_grid.add_theme_constant_override("v_separation", 4)
	section_vbox.add_child(mod_grid)

	for mod_type in MODIFIER_TYPES:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 1)
		mod_grid.add_child(cell)

		var mod_label := Label.new()
		mod_label.text = MODIFIER_LABELS[mod_type]
		mod_label.add_theme_font_size_override("font_size", 11)
		mod_label.add_theme_color_override("font_color", C_TEXT_DIM)
		cell.add_child(mod_label)

		var opt := OptionButton.new()
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt.custom_minimum_size.y = 28
		opt.clip_text = true
		opt.add_theme_font_size_override("font_size", 13)

		var item_values: Array = []
		var current_val: String = _player_data[player_idx]["casts"][cast_name][mod_type]
		var current_idx := 0

		for val in MODIFIER_VALUES[mod_type]:
			if _availability[mod_type].get(val, true):
				if val == current_val:
					current_idx = item_values.size()
				opt.add_item(MODIFIER_DISPLAY[mod_type].get(val, val))
				item_values.append(val)

		# If the saved value was disabled in config, still show it (greyed out) so state is visible
		if current_val not in item_values:
			current_idx = item_values.size()
			opt.add_item(MODIFIER_DISPLAY[mod_type].get(current_val, current_val))
			item_values.append(current_val)
			opt.set_item_disabled(current_idx, true)

		opt.selected = current_idx
		opt.item_selected.connect(_on_modifier_changed.bind(player_idx, cast_name, mod_type, item_values))
		cell.add_child(opt)

		ui["options"][cast_name][mod_type] = {"btn": opt, "values": item_values}


func _style_color_button(btn: Button, color_idx: int, selected: bool) -> void:
	var col: Color = PLAYER_COLORS[color_idx]

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = col
	style_normal.set_corner_radius_all(3)
	if selected:
		style_normal.set_border_width_all(3)
		style_normal.border_color = Color.WHITE
	else:
		style_normal.set_border_width_all(1)
		style_normal.border_color = Color(0.0, 0.0, 0.0, 0.5)

	var style_hover := style_normal.duplicate() as StyleBoxFlat
	style_hover.set_border_width_all(3)
	style_hover.border_color = Color.WHITE

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("pressed", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("focus", style_normal)


# ---------------------------------------------------------------------------
# Event handlers
# ---------------------------------------------------------------------------

func _on_name_changed(text: String, player_idx: int) -> void:
	_player_data[player_idx]["name"] = text
	_save()


func _on_color_selected(color_idx: int, player_idx: int) -> void:
	_player_data[player_idx]["color_index"] = color_idx
	_save()
	var new_color: Color = PLAYER_COLORS[color_idx]
	var ui: Dictionary = _player_ui[player_idx]
	for i in (ui["color_buttons"] as Array).size():
		_style_color_button(ui["color_buttons"][i], i, i == color_idx)
	(ui["card_style"] as StyleBoxFlat).border_color = new_color
	(ui["name_edit"] as LineEdit).add_theme_color_override("font_color", new_color)


func _on_modifier_changed(item_idx: int, player_idx: int, cast_name: String, mod_type: String, item_values: Array) -> void:
	if item_idx < 0 or item_idx >= item_values.size():
		return
	_player_data[player_idx]["casts"][cast_name][mod_type] = item_values[item_idx]
	_save()
	_validate_cast(player_idx, cast_name)


func _validate_cast(player_idx: int, cast_name: String) -> void:
	var selection: Dictionary = _player_data[player_idx]["casts"][cast_name]
	var disallowed: Dictionary = _Validator.get_disallowed(selection, _invalid_rules)
	var valid: bool = _Validator.is_valid(selection, _invalid_rules)

	var ui: Dictionary = _player_ui[player_idx]
	(ui["warnings"][cast_name] as Label).visible = not valid
	(ui["cooldown_labels"][cast_name] as Label).text = "%.1fs" % _calc_cast_cooldown(cast_name, selection)

	for mod_type in MODIFIER_TYPES:
		var info: Dictionary = ui["options"][cast_name][mod_type]
		var opt := info["btn"] as OptionButton
		var values: Array = info["values"]
		var bad: Array = disallowed.get(mod_type, [])
		for i in values.size():
			opt.set_item_disabled(i, values[i] in bad)


func _calc_cast_cooldown(cast_name: String, mods: Dictionary) -> float:
	var cast: Cast
	match cast_name:
		"Energy":     cast = EnergyCast.new()
		"Conduction": cast = ConductionCast.new()
		"Impulse":    cast = ImpulseCast.new()
		"Structure":  cast = StructureCast.new()
		_: return 0.0
	for mod_type in MODIFIER_TYPES:
		var val: String = mods.get(mod_type, "")
		var idx: int = MODIFIER_VALUES[mod_type].find(val)
		if idx < 0:
			continue
		match mod_type:
			"area":
				if cast.area_modifier == null:
					cast.area_modifier = AreaModifier.new()
				cast.area_modifier.target_area = idx as AreaModifier.TargetArea
			"distance":
				if cast.distance_modifier == null:
					cast.distance_modifier = DistanceModifier.new()
				cast.distance_modifier.distance = idx as DistanceModifier.Distance
			"energy_type":
				if cast.energy_type_modifier == null:
					cast.energy_type_modifier = EnergyTypeModifier.new()
				cast.energy_type_modifier.type = idx as EnergyTypeModifier.Type
			"extension":
				if cast.extension_modifier == null:
					cast.extension_modifier = ExtensionModifier.new()
				cast.extension_modifier.extension = idx as ExtensionModifier.Extension
	var result := cast.cooldown
	cast.free()
	return result


func _on_load_build(_player_idx: int) -> void:
	pass  # TODO: load a named build from file


func _on_save_build(_player_idx: int) -> void:
	pass  # TODO: save a named build to file


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_MENU_SCENE)


func _on_start_pressed() -> void:
	_write_to_registry()
	get_tree().change_scene_to_file(EXPERIMENTAL_STATION_SCENE)


func _write_to_registry() -> void:
	_Registry.builds.clear()
	for i in NUM_PLAYERS:
		_Registry.builds.append({
			"name": _player_data[i]["name"],
			"color": PLAYER_COLORS[_player_data[i]["color_index"]],
			"casts": (_player_data[i]["casts"] as Dictionary).duplicate(true),
		})


# ---------------------------------------------------------------------------
# Controller navigation
# ---------------------------------------------------------------------------

func _setup_navigation() -> void:
	_navs.clear()
	_joy_cooldown.clear()
	# Remove any old cursors from a previous setup
	for child in get_children():
		if child.get_meta("nav_cursor", false):
			child.queue_free()

	for i in NUM_PLAYERS:
		var ui: Dictionary = _player_ui[i]
		var color: Color = PLAYER_COLORS[_player_data[i]["color_index"]]
		var cbtns: Array = ui["color_buttons"]

		var rows: Array = []
		rows.append([ui["name_edit"]])
		rows.append(cbtns.slice(0, 8))
		rows.append(cbtns.slice(8, 16))
		for cast_name in CAST_NAMES:
			var opts: Dictionary = ui["options"][cast_name]
			rows.append([opts["area"]["btn"],        opts["distance"]["btn"]])
			rows.append([opts["energy_type"]["btn"], opts["extension"]["btn"]])
		rows.append([ui["load_btn"], ui["save_btn"]])
		if i == 0:
			rows.append([_back_btn, _start_btn])

		var cursor := _make_nav_cursor(color)
		_navs.append({"rows": rows, "row": 0, "col": 0, "cursor": cursor,
				"scroll": ui["scroll"]})
		_joy_cooldown.append(0.0)

	_nav_update_all_cursors()


func _make_nav_cursor(color: Color) -> Panel:
	var cursor := Panel.new()
	cursor.set_meta("nav_cursor", true)
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor.z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(2)
	style.border_color = color
	style.set_corner_radius_all(0)
	cursor.add_theme_stylebox_override("panel", style)
	add_child(cursor)
	return cursor


func _process(delta: float) -> void:
	_nav_update_all_cursors()
	for i in _navs.size():
		if _joy_cooldown[i] > 0.0:
			_joy_cooldown[i] -= delta
			continue
		var ax := Input.get_joy_axis(i, JOY_AXIS_LEFT_X)
		var ay := Input.get_joy_axis(i, JOY_AXIS_LEFT_Y)
		const DZ := 0.5
		var dx := 1 if ax > DZ else (-1 if ax < -DZ else 0)
		var dy := 1 if ay > DZ else (-1 if ay < -DZ else 0)
		if dx != 0 or dy != 0:
			_nav_move(i, dy, dx)
			_joy_cooldown[i] = 0.18


func _input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton or not (event as InputEventJoypadButton).pressed:
		return
	var dev := (event as InputEventJoypadButton).device
	if dev < 0 or dev >= _navs.size():
		return
	match (event as InputEventJoypadButton).button_index:
		JOY_BUTTON_DPAD_UP:    _nav_move(dev, -1,  0)
		JOY_BUTTON_DPAD_DOWN:  _nav_move(dev,  1,  0)
		JOY_BUTTON_DPAD_LEFT:  _nav_move(dev,  0, -1)
		JOY_BUTTON_DPAD_RIGHT: _nav_move(dev,  0,  1)
		JOY_BUTTON_A:          _nav_activate(dev)


func _nav_move(player_idx: int, dy: int, dx: int) -> void:
	var nav: Dictionary = _navs[player_idx]
	var rows: Array = nav["rows"]

	if dy != 0:
		var new_row: int = clampi(nav["row"] + dy, 0, rows.size() - 1)
		var row_size: int = (rows[new_row] as Array).size()
		nav["row"] = new_row
		nav["col"] = clampi(nav["col"], 0, row_size - 1)
		var scroll := nav["scroll"] as ScrollContainer
		if scroll:
			var target := (rows[new_row] as Array)[nav["col"]] as Control
			scroll.ensure_control_visible(target)
	else:
		var row_size: int = (rows[nav["row"]] as Array).size()
		nav["col"] = clampi(nav["col"] + dx, 0, row_size - 1)

	_nav_update_all_cursors()


func _nav_activate(player_idx: int) -> void:
	var nav: Dictionary = _navs[player_idx]
	var rows: Array = nav["rows"]
	var row: int = nav["row"]
	var col: int = nav["col"]
	if row >= rows.size():
		return
	var r: Array = rows[row]
	if col >= r.size():
		return
	var target: Control = r[col]
	if target is OptionButton:
		_cycle_option(target as OptionButton, 1)
	elif target is Button:
		(target as Button).pressed.emit()
	elif target is LineEdit:
		(target as LineEdit).grab_focus()


func _cycle_option(opt: OptionButton, direction: int) -> void:
	var count := opt.get_item_count()
	if count < 2:
		return
	var current := opt.get_selected()
	var next := current
	for _i in count:
		next = (next + direction + count) % count
		if not opt.is_item_disabled(next):
			break
	if next != current:
		opt.select(next)
		opt.item_selected.emit(next)


func _nav_update_all_cursors() -> void:
	for nav in _navs:
		_nav_update_cursor(nav)


func _nav_update_cursor(nav: Dictionary) -> void:
	var cursor := nav["cursor"] as Panel
	var rows: Array = nav["rows"]
	var row: int = nav["row"]
	var col: int = nav["col"]
	if row >= rows.size():
		cursor.visible = false
		return
	var r: Array = rows[row]
	if col >= r.size():
		cursor.visible = false
		return
	var target := r[col] as Control
	if not is_instance_valid(target) or not target.is_visible_in_tree():
		cursor.visible = false
		return
	var rect := target.get_global_rect()
	var origin := get_global_rect().position
	cursor.position = rect.position - origin - Vector2(2.0, 2.0)
	cursor.size = rect.size + Vector2(4.0, 4.0)
	cursor.visible = true



class_name TitleMenu
extends Control

const C_PANEL      := Color(0.07, 0.06, 0.04, 0.80)
const C_BORDER     := Color(0.75, 0.55, 0.10)
const C_TEXT_DIM   := Color(0.52, 0.48, 0.36)
const C_TITLE      := Color(0.88, 0.70, 0.20)
const C_HOVER      := Color(0.13, 0.11, 0.07, 0.90)
const C_PRESSED    := Color(0.22, 0.16, 0.05, 0.90)
const C_BTN_NORMAL := Color(0.05, 0.04, 0.02, 0.75)

const BUILD_SELECTION_SCENE := "res://ui/BuildSelection.tscn"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	theme = preload("res://ui/theme.tres")
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg_color := ColorRect.new()
	bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_color.color = Color.BLACK
	bg_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_color)

	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = preload("res://ui/ArcaneInstabilityMenu.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_top", 60)
	title_margin.add_theme_constant_override("margin_left", 40)
	title_margin.add_theme_constant_override("margin_right", 40)
	root_vbox.add_child(title_margin)

	var title_label := Label.new()
	title_label.text = "Arcane Instability"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", C_TITLE)
	title_margin.add_child(title_label)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(spacer_top)

	var btn_center := HBoxContainer.new()
	btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(btn_center)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 12)
	btn_vbox.custom_minimum_size = Vector2(300, 0)
	btn_center.add_child(btn_vbox)

	_add_menu_button(btn_vbox, "New", _on_new_pressed)
	_add_menu_button(btn_vbox, "Arena", _on_arena_pressed)
	_add_menu_button(btn_vbox, "Settings", _on_settings_pressed)
	_add_menu_button(btn_vbox, "Exit", _on_exit_pressed)

	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(spacer_bottom)

	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_bottom", 16)
	bottom_margin.add_theme_constant_override("margin_left", 20)
	bottom_margin.add_theme_constant_override("margin_right", 20)
	root_vbox.add_child(bottom_margin)

	var bottom_hbox := HBoxContainer.new()
	bottom_margin.add_child(bottom_hbox)

	var copyright := Label.new()
	copyright.text = "(c) Copyright Gruber Games 2026"
	copyright.add_theme_font_size_override("font_size", 14)
	copyright.add_theme_color_override("font_color", C_TEXT_DIM)
	copyright.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(copyright)

	var ver: String = ProjectSettings.get_setting("application/config/version", "0.1")
	var version_label := Label.new()
	version_label.text = "v%s" % ver
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", C_TEXT_DIM)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_hbox.add_child(version_label)


func _add_menu_button(parent: Control, label: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(300, 56)
	btn.add_theme_font_size_override("font_size", 24)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = C_BTN_NORMAL
	style_normal.set_border_width_all(1)
	style_normal.border_color = C_BORDER
	style_normal.set_corner_radius_all(0)
	style_normal.set_content_margin_all(10.0)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = C_HOVER
	style_hover.set_border_width_all(1)
	style_hover.border_color = C_BORDER
	style_hover.set_corner_radius_all(0)
	style_hover.set_content_margin_all(10.0)

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = C_PRESSED
	style_pressed.set_border_width_all(1)
	style_pressed.border_color = C_BORDER
	style_pressed.set_corner_radius_all(0)
	style_pressed.set_content_margin_all(10.0)

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_normal)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _on_new_pressed() -> void:
	get_tree().change_scene_to_file(BUILD_SELECTION_SCENE)


func _on_arena_pressed() -> void:
	get_tree().change_scene_to_file(BUILD_SELECTION_SCENE)


func _on_settings_pressed() -> void:
	pass  # TODO: navigate to settings scene


func _on_exit_pressed() -> void:
	get_tree().quit()

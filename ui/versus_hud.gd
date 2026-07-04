class_name VersusHUD
extends CanvasLayer


var _player_spawner: PlayerSpawner

var _player_deaths: int = 0
var _enemy_deaths: int = 0

var _player_deaths_label: Label
var _enemy_deaths_label: Label
var _player_cards_container: HBoxContainer

var _respawn_timers: Dictionary = {}
var _player_cards: Dictionary = {}


func _ready() -> void:
	_build_ui()


func setup(player_spawner: PlayerSpawner, enemy_spawner: EnemySpawner) -> void:
	_player_spawner = player_spawner
	player_spawner.player_spawned.connect(_on_player_spawned)
	player_spawner.player_died.connect(_on_player_died)
	enemy_spawner.enemy_died.connect(_on_enemy_died)
	for i in player_spawner.number_of_players:
		_ensure_player_card(i)


func _process(delta: float) -> void:
	for device_id in _respawn_timers.keys():
		_respawn_timers[device_id] -= delta
		if _respawn_timers[device_id] <= 0.0:
			_respawn_timers.erase(device_id)
		else:
			_set_status_text(device_id, "Respawn %.1fs" % _respawn_timers[device_id])


func _on_player_spawned(player: Player) -> void:
	_ensure_player_card(player.device_id)
	_respawn_timers.erase(player.device_id)
	_set_status_text(player.device_id, "Alive")


func _on_player_died(device_id: int) -> void:
	_player_deaths += 1
	_player_deaths_label.text = "Players  %d" % _player_deaths
	if _player_spawner:
		_respawn_timers[device_id] = _player_spawner.respawn_delay
		_set_status_text(device_id, "Respawn %.1fs" % _player_spawner.respawn_delay)


func _on_enemy_died() -> void:
	_enemy_deaths += 1
	_enemy_deaths_label.text = "Enemies  %d" % _enemy_deaths


func _set_status_text(device_id: int, text: String) -> void:
	if device_id in _player_cards:
		_player_cards[device_id].status_label.text = text


func _ensure_player_card(device_id: int) -> void:
	if device_id in _player_cards:
		return
	var color := Color.WHITE
	if _player_spawner and device_id < _player_spawner.player_colors.size():
		color = _player_spawner.player_colors[device_id]
	_create_player_card(device_id, color)


func _create_player_card(device_id: int, color: Color) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(130, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var name_label := Label.new()
	name_label.text = "Player %d" % (device_id + 1)
	name_label.add_theme_color_override("font_color", color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var status_label := Label.new()
	status_label.text = "Alive"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	_player_cards_container.add_child(card)
	_player_cards[device_id] = {name_label = name_label, status_label = status_label}


func _build_ui() -> void:
	var theme := _create_theme()

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme
	add_child(root)

	_build_score_panel(root)
	_build_player_panel(root)


func _build_score_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -155.0
	panel.offset_right = 155.0
	panel.offset_top = 10.0
	panel.offset_bottom = 85.0
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "DEATHS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vbox.add_child(row)

	_player_deaths_label = Label.new()
	_player_deaths_label.text = "Players  0"
	row.add_child(_player_deaths_label)

	var sep := VSeparator.new()
	row.add_child(sep)

	_enemy_deaths_label = Label.new()
	_enemy_deaths_label.text = "Enemies  0"
	row.add_child(_enemy_deaths_label)


func _build_player_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -75.0
	panel.offset_bottom = -10.0
	root.add_child(panel)

	_player_cards_container = HBoxContainer.new()
	_player_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_player_cards_container.add_theme_constant_override("separation", 12)
	panel.add_child(_player_cards_container)


func _create_theme() -> Theme:
	var theme := Theme.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.03, 0.12, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.55, 0.25, 0.95, 1.0)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10.0)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	theme.set_color("font_color", "Label", Color(0.92, 0.88, 1.0))
	theme.set_font_size("font_size", "Label", 15)

	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.55, 0.25, 0.95, 0.5)
	theme.set_stylebox("separator", "VSeparator", sep_style)

	return theme

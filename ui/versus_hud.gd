class_name VersusHUD
extends CanvasLayer


class CooldownIndicator extends Control:
	const RADIUS := 18.0
	const SIZE := Vector2(44.0, 44.0)

	var _fraction: float = 0.0
	var _tint: Color = Color.WHITE

	func _init(tint: Color) -> void:
		_tint = tint
		custom_minimum_size = SIZE

	func set_fraction(f: float) -> void:
		_fraction = clampf(f, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var center := SIZE * 0.5
		var bg := Color(_tint.r, _tint.g, _tint.b, 0.25)
		draw_arc(center, RADIUS, 0.0, TAU, 48, bg, 3.0)
		if _fraction > 0.001:
			draw_arc(center, RADIUS, -PI * 0.5, -PI * 0.5 + _fraction * TAU, 48, _tint, 5.0)


var _player_spawner: PlayerSpawner

var _player_deaths: int = 0
var _enemy_deaths: int = 0

var _player_deaths_label: Label
var _enemy_deaths_label: Label
var _player_cards_container: HBoxContainer

var _respawn_timers: Dictionary = {}
var _player_cards: Dictionary = {}
var _live_players: Dictionary = {}


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

	for device_id in _live_players.keys():
		var player: Player = _live_players[device_id]
		if not is_instance_valid(player):
			_live_players.erase(device_id)
			continue
		if device_id not in _player_cards:
			continue
		var indicators: Array = _player_cards[device_id].cooldown_indicators
		var player_casts: Array[Cast] = player.casts
		for i in player_casts.size():
			if i < indicators.size() and player_casts[i] != null:
				indicators[i].set_fraction(player_casts[i].cooldown_fraction)


func _on_player_spawned(player: Player) -> void:
	_ensure_player_card(player.device_id)
	_respawn_timers.erase(player.device_id)
	_set_status_text(player.device_id, "Alive")
	_live_players[player.device_id] = player
	if player.device_id in _player_cards:
		for indicator in _player_cards[player.device_id].cooldown_indicators:
			indicator.set_fraction(0.0)


func _on_player_died(device_id: int) -> void:
	_player_deaths += 1
	_player_deaths_label.text = "Players  %d" % _player_deaths
	if _player_spawner:
		_respawn_timers[device_id] = _player_spawner.respawn_delay
		_set_status_text(device_id, "Respawn %.1fs" % _player_spawner.respawn_delay)
	_live_players.erase(device_id)
	if device_id in _player_cards:
		for indicator in _player_cards[device_id].cooldown_indicators:
			indicator.set_fraction(0.0)


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
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var name_label := Label.new()
	name_label.text = "Player %d" % (device_id + 1)
	name_label.add_theme_color_override("font_color", color)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var spell_row := HBoxContainer.new()
	spell_row.alignment = BoxContainer.ALIGNMENT_CENTER
	spell_row.add_theme_constant_override("separation", 16)
	vbox.add_child(spell_row)

	var spell_names := ["E", "I", "S", "C"]
	var cooldown_indicators: Array = []
	for i in 4:
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 4)
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		spell_row.add_child(slot)

		var spell_label := Label.new()
		spell_label.text = spell_names[i]
		spell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		spell_label.add_theme_font_size_override("font_size", 14)
		slot.add_child(spell_label)

		var indicator := CooldownIndicator.new(color)
		slot.add_child(indicator)
		cooldown_indicators.append(indicator)

	var status_label := Label.new()
	status_label.text = "Alive"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(status_label)

	_player_cards_container.add_child(card)
	_player_cards[device_id] = {
		name_label = name_label,
		status_label = status_label,
		cooldown_indicators = cooldown_indicators,
	}


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = preload("res://ui/theme.tres")
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
	title.add_theme_font_size_override("font_size", 24)
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
	panel.offset_top = -170.0
	panel.offset_bottom = -10.0
	root.add_child(panel)

	_player_cards_container = HBoxContainer.new()
	_player_cards_container.add_theme_constant_override("separation", 8)
	panel.add_child(_player_cards_container)



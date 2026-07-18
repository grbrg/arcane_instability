class_name Player
extends Character

const CAST_PROJECTILE_SCENE = preload("res://spells/cast_projectile.tscn")
const _Registry := preload("res://core/build_registry.gd")

@export var device_id: int = -1
@export var level: Level

# Slot indices match Cast.Axis enum — fixed to shoulder buttons:
# R2=ENERGY, R1=PRESSURE, L2=STRUCTURE, L1=CONDUCTION
const SLOT_ENERGY     = 0
const SLOT_PRESSURE   = 1
const SLOT_STRUCTURE  = 2
const SLOT_CONDUCTION = 3

var _casts: Array[Cast] = []
var casts: Array[Cast]:
	get: return _casts
var _active_cast: Cast = null
var _controller: PlayerController

var _player_color: Color = Color.WHITE
var _has_highlights: bool = false

@onready var _cast_marker: SpellMarker = $SpellMarker
@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	super._ready()

	_casts.resize(4)
	_assign_cast(SLOT_ENERGY, EnergyCast.new())
	_assign_cast(SLOT_PRESSURE, PressureCast.new())
	_assign_cast(SLOT_STRUCTURE, StructureCast.new())
	_assign_cast(SLOT_CONDUCTION, ConductionCast.new())

	_apply_build()

	_controller = TwinstickPlayerController.new(self)

	var snaps := _controller.snaps_cast_to_distance()
	var shows_marker := _controller.uses_cast_marker()
	for cast in _casts:
		if cast != null:
			cast.snap_to_distance = snaps
			cast.show_marker = shows_marker


func _assign_cast(slot: int, cast: Cast) -> void:
	_casts[slot] = cast
	cast.marker = _cast_marker


func set_player_color(color: Color) -> void:
	_player_color = color
	if not mesh.material_override:
		mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_color = color
	_cast_marker.set_color(color)


func set_move_input(dir: Vector3) -> void:
	_controller.set_move_input(dir)


func handle_joypad_button(event: InputEventJoypadButton) -> void:
	_controller.handle_joypad_button(event)


func poll_joypad(joypad_id: int, camera: Camera3D) -> void:
	_controller.poll_joypad(joypad_id, camera)


func request_jump() -> void:
	_controller.request_jump()


func redirect_active_cast(dir: Vector3, magnitude: float = -1.0) -> void:
	if _active_cast != null:
		_active_cast.redirect(dir, magnitude)


func set_cast_marker_position(world_pos: Vector3) -> void:
	_cast_marker.global_position = world_pos
	if _active_cast != null:
		var to := world_pos - global_position
		if to.length() > 0.001:
			_active_cast.redirect(to.normalized(), to.length() / _active_cast.max_dist)
		else:
			_active_cast.redirect(_controller.get_facing_dir(), 0.0)


func set_cast_marker_visible(marker_visible: bool) -> void:
	_cast_marker.visible = marker_visible


func request_cast(slot: int) -> void:
	if _active_cast != null or slot >= _casts.size():
		return
	var cast := _casts[slot]
	if cast != null and not cast.is_on_cooldown:
		cast.activate_marker(global_position, _controller.get_facing_dir())
		_active_cast = cast


func release_cast(slot: int) -> void:
	if slot >= _casts.size():
		return
	var cast := _casts[slot]
	if cast != null and cast == _active_cast:
		var world_sim := level.world_simulation
		var grid := world_sim.grid
		var player_cell := grid.local_to_map(grid.to_local(global_position))

		cast.player_cell = player_cell

		if cast.distance_modifier != null \
				and cast.distance_modifier.distance == DistanceModifier.Distance.AROUND_PLAYER \
				and cast.area_modifier.target_area == AreaModifier.TargetArea.AREA:
			cast.deactivate_marker(world_sim, player_cell)
			_resolve_around_player(cast, player_cell, world_sim)
		else:
			var target_pos: Vector3
			if cast.show_marker:
				target_pos = _cast_marker.global_position
			else:
				target_pos = global_position + cast._cast_dir * cast.max_dist
			var index := grid.local_to_map(grid.to_local(target_pos))
			cast.deactivate_marker(world_sim, index)

			var projectile := CAST_PROJECTILE_SCENE.instantiate()
			level.add_child(projectile)
			projectile.global_position = global_position + Vector3(0.0, 0.5, 0.0)
			projectile.setup(cast, target_pos, world_sim)

		_active_cast = null


func _resolve_around_player(cast: Cast, player_cell: Vector3i, world_sim: WorldSimulation) -> void:
	var center := world_sim.get_cell(player_cell)
	if center == null:
		return
	for neighbour in center.neighbours:
		cast.apply_to_cell(world_sim, neighbour.index, cast.strength)
	world_sim.force_tick()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		apply_gravity(delta)
	_controller.physics_process(delta, _active_cast != null)
	_process_casts(delta)


func _process_casts(delta: float) -> void:
	var facing := _controller.get_facing_dir()
	if _active_cast != null and facing != Vector3.ZERO and not _active_cast._manual_dist:
		_active_cast.redirect(facing)
	for cast in _casts:
		if cast != null:
			cast.process(delta, global_position, facing)
	if _active_cast != null and not _active_cast.is_active:
		_active_cast = null

	if _active_cast != null:
		level.world_simulation.set_player_highlights(self, _get_cast_affected_cells(_active_cast), _player_color)
		_has_highlights = true
	elif _has_highlights:
		level.world_simulation.clear_player_highlights(self)
		_has_highlights = false


func _get_cast_affected_cells(cast: Cast) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var world_sim := level.world_simulation
	var grid := world_sim.grid

	var is_around_player := cast.distance_modifier != null \
		and cast.distance_modifier.distance == DistanceModifier.Distance.AROUND_PLAYER
	var is_area := cast.area_modifier != null \
		and cast.area_modifier.target_area == AreaModifier.TargetArea.AREA
	var is_beam := cast.area_modifier != null \
		and cast.area_modifier.target_area == AreaModifier.TargetArea.BEAM

	var player_cell := grid.local_to_map(grid.to_local(global_position))

	if is_around_player and is_area:
		var center := world_sim.get_cell(player_cell)
		if center != null:
			for n in center.neighbours:
				cells.append(n.index)
		return cells

	var target_pos: Vector3
	if cast.show_marker:
		target_pos = _cast_marker.global_position
	else:
		target_pos = global_position + cast._cast_dir * cast.max_dist

	var target_cell := grid.local_to_map(grid.to_local(target_pos))

	if is_beam:
		var line: Array[Vector3i] = _get_cells_along_line(player_cell, target_cell)
		if not line.is_empty() and line[0] == player_cell:
			line.remove_at(0)
		return line

	if target_cell != player_cell:
		cells.append(target_cell)
	if is_area:
		var cell := world_sim.get_cell(target_cell)
		if cell != null:
			for n in cell.neighbours:
				if n.index != player_cell:
					cells.append(n.index)
	return cells


func _get_cells_along_line(from: Vector3i, to: Vector3i) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var dx := to.x - from.x
	var dz := to.z - from.z
	var steps := maxi(absi(dx), absi(dz))
	if steps == 0:
		cells.append(from)
		return cells
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var idx := Vector3i(from.x + roundi(t * dx), from.y, from.z + roundi(t * dz))
		if cells.is_empty() or cells[-1] != idx:
			cells.append(idx)
	return cells


func _apply_build() -> void:
	if device_id < 0 or device_id >= _Registry.builds.size():
		return
	var build: Dictionary = _Registry.builds[device_id]
	var cast_mods: Dictionary = build.get("casts", {})
	var cast_map := {
		"Energy": SLOT_ENERGY,
		"Conduction": SLOT_CONDUCTION,
		"Pressure": SLOT_PRESSURE,
		"Structure": SLOT_STRUCTURE,
	}
	for cast_name: String in cast_map:
		var cast: Cast = _casts[cast_map[cast_name]]
		if cast == null or not cast_mods.has(cast_name):
			continue
		_apply_cast_modifiers(cast, cast_mods[cast_name])


func _apply_cast_modifiers(cast: Cast, mods: Dictionary) -> void:
	if mods.has("area"):
		if cast.area_modifier == null:
			cast.area_modifier = AreaModifier.new()
		cast.area_modifier.target_area = _area_val(mods["area"])
	if mods.has("distance"):
		if cast.distance_modifier == null:
			cast.distance_modifier = DistanceModifier.new()
		cast.distance_modifier.distance = _distance_val(mods["distance"])
	if mods.has("energy_type"):
		if cast.energy_type_modifier == null:
			cast.energy_type_modifier = EnergyTypeModifier.new()
		cast.energy_type_modifier.type = _energy_type_val(mods["energy_type"])
	if mods.has("extension"):
		if cast.extension_modifier == null:
			cast.extension_modifier = ExtensionModifier.new()
		cast.extension_modifier.extension = _extension_val(mods["extension"])
		# invert always has negative effect
		if cast.extension_modifier.extension == ExtensionModifier.Extension.INVERT:
			cast.strength = -abs(cast.strength)


static func _area_val(s: String) -> AreaModifier.TargetArea:
	match s:
		"PROJECTILE": return AreaModifier.TargetArea.PROJECTILE
		"BEAM":       return AreaModifier.TargetArea.BEAM
		"AREA":       return AreaModifier.TargetArea.AREA
	return AreaModifier.TargetArea.POINT


static func _distance_val(s: String) -> DistanceModifier.Distance:
	match s:
		"SHORT":  return DistanceModifier.Distance.SHORT
		"MIDDLE": return DistanceModifier.Distance.MIDDLE
		"FAR":    return DistanceModifier.Distance.FAR
	return DistanceModifier.Distance.AROUND_PLAYER


static func _energy_type_val(s: String) -> EnergyTypeModifier.Type:
	match s:
		"ELECTRICAL": return EnergyTypeModifier.Type.ELECTRICAL
		"ARCANE":     return EnergyTypeModifier.Type.ARCANE
	return EnergyTypeModifier.Type.THERMAL


static func _extension_val(s: String) -> ExtensionModifier.Extension:
	match s:
		"BOUNCING":  return ExtensionModifier.Extension.BOUNCING
		"INVERT":    return ExtensionModifier.Extension.INVERT
		"EXPLOSION": return ExtensionModifier.Extension.EXPLOSION
	return ExtensionModifier.Extension.NONE

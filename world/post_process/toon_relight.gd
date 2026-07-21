class_name ToonRelight
extends RefCounted

const RELIGHT_SHADER := preload("res://world/post_process/toon_relight.gdshader")
const OUTLINE_SHADER := preload("res://world/post_process/toon_outline.gdshader")

## Group tag for anything that should never get the toon treatment: the property-view
## overlays (thermal/pressure/impulse), the cast-range marker, and per-cell AOE
## highlights. Add to a node (or its MeshInstance3D) with add_to_group / groups=[...].
const EXCLUDED_GROUP := "no_toon"

static var _chain_material: ShaderMaterial


static func _get_chain_material() -> ShaderMaterial:
	if _chain_material == null:
		var outline := ShaderMaterial.new()
		outline.shader = OUTLINE_SHADER
		var relight := ShaderMaterial.new()
		relight.shader = RELIGHT_SHADER
		relight.next_pass = outline
		_chain_material = relight
	return _chain_material


## Chains the toon relight+outline passes onto every material surface of `mesh_instance`,
## unless it's tagged as a property view. Existing materials (albedo, textures, custom
## shader logic) are left untouched -- this only appends a next_pass.
static func apply_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.is_in_group(EXCLUDED_GROUP):
		return
	if not mesh_instance.mesh:
		return
	var chain := _get_chain_material()
	for i in mesh_instance.mesh.get_surface_count():
		var mat := mesh_instance.get_active_material(i)
		if mat and mat.next_pass == null:
			mat.next_pass = chain


## GridMap doesn't expose per-cell MeshInstance3D nodes -- tiles are drawn straight from
## the MeshLibrary's meshes -- so this chains onto each library item's mesh surfaces
## directly instead. Affects every cell using that item at once, which is correct here
## since GridMap has no per-cell material override anyway.
static func apply_to_gridmap(grid_map: GridMap) -> void:
	var lib := grid_map.mesh_library
	if not lib:
		return
	var chain := _get_chain_material()
	for item_id in lib.get_item_list():
		var mesh := lib.get_item_mesh(item_id)
		if not mesh:
			continue
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i)
			if mat and mat.next_pass == null:
				mat.next_pass = chain


## CSGShape3D (the walls) isn't a MeshInstance3D either. Chains onto whichever material
## is actually rendering (material_override, else material), creating an explicit default
## material first if neither is set so there's something to chain onto.
static func apply_to_csg(shape: CSGShape3D) -> void:
	var mat: Material = shape.material_override
	if not mat:
		mat = shape.material
	if not mat:
		mat = StandardMaterial3D.new()
		shape.material_override = mat
	if mat.next_pass == null:
		mat.next_pass = _get_chain_material()


## Dispatches to the right apply_to_* based on node type; no-ops for anything else.
static func apply_to_node(node: Node) -> void:
	if node is SpellMarker:
		return

	if node is MeshInstance3D:
		apply_to_mesh(node)
	elif node is GridMap:
		apply_to_gridmap(node)
	elif node is CSGShape3D:
		apply_to_csg(node)


## Recursively applies apply_to_node to root and every descendant.
static func apply_to_subtree(root: Node) -> void:
	apply_to_node(root)
	for child in root.get_children():
		apply_to_subtree(child)

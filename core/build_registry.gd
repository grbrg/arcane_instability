class_name BuildRegistry
extends RefCounted

# Static storage — persists across scene changes without needing an autoload.
# Populated by BuildSelectionScreen before transitioning to the game.
# Indexed by device_id / player index. A null entry means no controller was
# connected to that slot on the build screen, so no player should be spawned there.
# Each entry: { name: String, color: Color, buttons: Array[Dictionary] } where
# buttons has 4 entries indexed by physical button slot (0=R2, 1=R1, 2=L2, 3=L1),
# each { axis, area, distance, energy_type, extension }.
static var builds: Array = []

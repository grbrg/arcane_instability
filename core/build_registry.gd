class_name BuildRegistry
extends RefCounted

# Static storage — persists across scene changes without needing an autoload.
# Populated by BuildSelectionScreen before transitioning to the game.
# Indexed by device_id / player index.
# Each entry: { name: String, color: Color, casts: { cast_name: { area, distance, energy_type, extension } } }
static var builds: Array = []

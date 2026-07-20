class_name PressureProperty
extends EnergyProperty
# Pressure: scalar magnitude stored per world object.
# Diffuses and decays like other energy channels.
# Impulse vectors are derived per-cell by comparing neighbouring pressures.


# Pressure used to get its own diffuse pass each tick (on top of the shared energy-channel
# pass), so it spread at double the rate implied by pressure_conductivity alone. Keep that
# feel now that diffusion is unified into a single pass.
func get_diffusion_rate() -> float:
	return 2.0

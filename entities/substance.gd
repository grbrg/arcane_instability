class_name Substance
extends Node


@export_category("Thermal Energy")
@export var thermal_capacity: float = 0.9
@export var thermal_conductivity: float = 0.9
@export var thermal_decay: float = 0.01
@export var burning_temperature: float = 999999.9

@export_category("Electrical Energy")
@export var electrical_capacity: float = 0.5
@export var electrical_conductivity: float = 0.5
@export var electrical_decay: float = 0.01

@export_category("Arcane Energy")
@export var arcane_capacity: float = 0.5
@export var arcane_conductivity: float = 0.9
@export var arcane_decay: float = 0.01

@export_category("Pressure")
@export var pressure_conductivity: float = 0.5
@export var pressure_decay: float = 0.5

@export_category("Structure")
@export var structure_value: float = 50.0
@export var structure_recovery: float = 0.05
## Total energy (across all channels) this object can withstand before taking structural damage.
@export var energy_tolerance: float = 0.5
## Multiplier applied to excess energy before dealing structural damage.
@export var energy_damage_scale: float = 20.0

@export_category("Conduction")
@export var conduction_value: float = 0.5


## List of substances this substance can morph into (water -> steam or ice)
var _successor_substances = []


##
func create_properties() -> Dictionary:
	var properties = {}

	properties["thermal"] = ThermalEnergy.new(0.0, thermal_capacity, thermal_conductivity, thermal_decay)
	properties["electrical"] = ElectricalEnergy.new(0.0, electrical_capacity, electrical_conductivity, electrical_decay)
	properties["arcane"] = ArcaneEnergy.new(0.0, arcane_capacity, arcane_conductivity, arcane_decay)
	properties["pressure"] = PressureProperty.new(0.0, 1.0, pressure_conductivity, pressure_decay)
	properties["structure"] = StructureProperty.new(structure_value, structure_recovery)
	properties["conduction"] = ConductionProperty.new(conduction_value)

	return properties

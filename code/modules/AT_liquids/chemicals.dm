


#define CHEMICAL_UNIVERSAL_NAME(name)\
	liquid_name = name;\
	solid_name = name;\
	gas_name = name;

#define GAS_PHASE (1<<0)
#define LIQUID_PHASE (1<<1)
#define SOLID_PHASE (1<<2)

/datum/chemical
	var/name = "unnamedium"
	///usually just the molecular name
	var/scientific_name = ""

	var/liquid_name = ""
	var/liquid_adjective = "liquid"

	var/solid_name = ""
	var/solid_adjective = "solid"

	///if overidden, replaces our universal name when in the gas phase
	var/gas_name = ""
	///goes before the name of this chemical, usually overridden to "vapor"
	var/gas_adjective = "gas"

	var/allowed_phases = LIQUID_PHASE

	var/liquid_icon = 'icons/turf/liquids/liquids.dmi'
	var/liquid_icon_state = "water"

	var/solid_icon = 'icons/turf/solids/solids.dmi'
	var/solid_icon_state = "ice_wall"

	var/gas_icon = 'icons/effects/atmospherics.dmi'
	var/gas_icon_state = "water_vapor"

	///temperature below which a liquid or gas will freeze and above which a solid will try to change.
	/// if this is NONE the chemical cannot be solid.
	/// if this is INFINITY this chemical can only be a solid
	var/solid_max_temp = T0C
	///temperature above which a liquid will evaporate and below which a gas will condense.
	///if this is NONE then a solid beyond its max temp will sublimate.
	///if this is INFINITY this chemical can never be a gas
	var/liquid_max_temp = T0C+100

	/// kg/mole
	var/molar_mass = 0.01802

	//molar_volume = molar_mass / [phase]_density
	/// kg/m^3
	var/solid_density = 917
	/// kg/m^3
	var/liquid_density = 997

	/// centipoise. use the dynamic viscosity at 20C if you can find it.
	/// DONT confuse this with kinematic viscosity
	var/viscosity = 1.0016

	///J/(mol * kelvin)
	var/molar_heat_capacity = 75.385

	/// microsiemens / cm
	var/electrical_conductivity = 0

	/// watts / kelvin
	var/liquid_thermal_conductivity = 600
	var/gas_thermal_conductivity = 600
	var/solid_thermal_conductivity = 600

	/// J / m^2
	/// only applies to liquids
	var/surface_tension = 0.07275

/datum/chemical/water
	name = "water"
	scientific_name = "h2o"
	liquid_adjective = ""
	solid_adjective = ""
	solid_name = "ice"
	gas_adjective = "vapor"

	///salt water conductivity because i dont want to simulate impurities
	electrical_conductivity = 55000

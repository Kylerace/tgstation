/datum/liquid
	var/name = "AHHH"
	var/icon = 'icons/turf/liquids/liquids.dmi'
	var/icon_state = "water"

	//make the parent type has the properties of water, if you add a new physical property make the default water's value for it.
	//that way liquids dont have to define everything

	/// kg / mole
	var/molar_mass = 0.01802
	/// kg / m^3
	var/density = 997
	/// m^3 / mole = molar_mass * 1/density
	var/molar_volume = 0.00001807
	///mega pascal seconds
	var/viscosity = 1.0016
	///J/(mol * kelvin)
	var/molar_heat_capacity = 75.385
	/// microsiemens / cm
	var/electrical_conductivity = 55000
	/// watts / kelvin
	var/thermal_conductivity = 600
	/// J / m^2
	var/surface_tension = 0.07275

	//right now just used for spawning
	var/minimum_temperature_to_exist = -INFINITY
	var/maximum_temperature_to_exist = INFINITY

/datum/liquid/water
	name = "water"
	icon = 'icons/turf/liquids/liquids.dmi'
	icon_state = "water"
	// kg / mole
	molar_mass = 0.01802
	// kg / m^3
	density = 997
	// m^3 / mole
	molar_volume = 0.00001807
	// mega pascal seconds = 1000 * s * N/m^2
	viscosity = 1.0016
	// J / (mole * kelvin)
	molar_heat_capacity = 75.385
	//conductivity of salt water because if i used pure water id have to figure out how to lower it when contacting a dirty floor
	electrical_conductivity = 55000
	// watts / millikelvin
	thermal_conductivity = 600
	// J / m^2 or N/m
	surface_tension = 0.07275

/datum/liquid/lava
	name = "lava"
	icon = 'icons/turf/floors/lava.dmi'
	icon_state = "lava-255"

	viscosity = 1000000

	minimum_temperature_to_exist = T0C + 1000

/datum/liquid/blood
	name = "blood"
	icon_state = "blood"

/datum/liquid/pitch //specifically bitumen, since pitch is a family of materials. but pitch is more recognizable
	name = "pitch"
	icon_state = "pitch"
	viscosity = 23000000000//~230 billion times that of water

/datum/liquid/helium
	name = "liquid helium"
	icon_state = "helium"
	viscosity = 0

	maximum_temperature_to_exist = 4.15

/datum/liquid/gasoline
	name = "gasoline"
	icon_state = "gasoline"

	density = 750

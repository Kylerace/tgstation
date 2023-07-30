GLOBAL_VAR_INIT(liquid_enter_exit_effects, init_liquid_enter_effects())

/proc/init_liquid_enter_effects()
	. = list()
	for(var/datum/liquid/liquid_type as anything in subtypesof(/datum/liquid))
		if(!initial(liquid_type.effect_on_enter_exit))
			.[liquid_type] = FALSE
			continue

		var/datum/liquid/instance = new liquid_type
		.[liquid_type] = instance

var/static/mutable_appearance/permafrost_overlay = mutable_appearance('icons/effects/water.dmi', "ice_floor")
var/static/mutable_appearance/ice_overlay = mutable_appearance('icons/turf/overlays.dmi', "snowfloor")

var/static/mutable_appearance/generic_turf_overlay = mutable_appearance('icons/effects/water.dmi', "wet_static")

///called when anything has been added to or removed from us
/datum/liquid_mix/proc/on_mix_changed(turf/holder, list/datum/liquid/new_liquids, list/datum/liquid/old_liquids)
	var/static/mutable_appearance/water_overlay = mutable_appearance('icons/effects/water.dmi', "wet_floor_static")

	for(var/datum/liquid/new_liquid as anything in new_liquids)
		switch(new_liquid)
			if(/datum/liquid/water)
				holder.overlays += water_overlay

	for(var/datum/liquid/old_liquid as anything in old_liquids)
		continue

/turf/open/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(!isliving(arrived))
		return

	if(HAS_TRAIT(src, TRAIT_TURF_IGNORE_SLIPPERY))
		return

	var/mob/living/victim = arrived
	if(victim.movement_type & (FLYING | FLOATING))
		return

	var/knockdown_time = 0
	var/paralyze_time = 0
	var/flags = 0

	var/list/cached_liquids = liquids?.liquids
	if(!cached_liquids)
		return

	for(var/datum/liquid/liquid as anything in cached_liquids[LIQUID_CURRENT])
		var/moles = cached_liquids[LIQUID_CURRENT][liquid]
		var/slip_power = initial(liquid.slip_knockdown)
		if(max(moles, 5) * slip_power < 10)
			continue

		knockdown_time = max(knockdown_time, slip_power)
		paralyze_time = max(paralyze_time, initial(liquid.slip_paralyze))
		flags |= initial(liquid.slip_flags)//TODOKYLER: this sucks and /component/slippery needs to be refactored

	if(knockdown_time || paralyze_time)
		victim.slip(knockdown_time, src, flags, paralyze_time)

/datum/liquid_mix/proc/on_removed()


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

	var/effect_on_enter_exit = FALSE

	// these are different from water's values because we dont want to make all liquids slippery by default
	var/slip_knockdown = 0
	var/slip_paralyze = 0
	var/slip_flags = NONE


/datum/liquid/proc/on_enter_turf(turf/entered_turf)
	return

/datum/liquid/proc/on_exit_turf(turf/exited_turf)
	return


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

	slip_knockdown = 60
	slip_flags = NO_SLIP_WHEN_WALKING


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
	molar_heat_capacity = 228

/datum/liquid/honey
	name = "honey"
	icon_state = "gasoline"

	viscosity = 10000


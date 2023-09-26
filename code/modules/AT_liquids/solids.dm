#define SOLID_CYCLE_ARCHIVE(turf)\
	turf.solids.archive();\
	turf.solid_archived_cycle = SSsolids.times_fired;\
	turf.solids.temperature_archived = turf.solids.temperature;

/*
/turf
	var/datum/solid_mix/solids

	var/solid_archived_cycle = 0
	var/solid_current_cycle = 0

/turf/open/Initialize(mapload)
	. = ..()
	solids = new()
	solids.temperature = temperature
	solids.temperature_archived = temperature_archived

/turf/proc/process_solids(fire_count)
	SSsolids.remove_active_turf(src)

/turf/open/process_solids(fire_count)
	if(solid_archived_cycle < fire_count)
		SOLID_CYCLE_ARCHIVE(src)

/turf/proc/update_solid_visuals()
	//if(solids[SOLID_NEXT][/datum/solid/ice])
*/

/datum/solid_mix
	var/list/solids = list(list(), list())

	var/volume = 0
	var/volume_archived = 0

	var/temperature = TCMB
	var/temperature_archived = TCMB

/datum/solid_mix/proc/archive()
	solids[LIQUID_CURRENT] = solids[LIQUID_NEXT].Copy()
	volume_archived = volume
	temperature_archived = temperature


/datum/solid
	var/name = "AHHH"
	var/floor_icon = 'icons/turf/solids/solids.dmi'
	var/floor_icon_state = "ice_wall"

	var/barrier_icon = 'icons/turf/solids/solids.dmi'
	var/barrier_icon_state = "ice_wall"

	//make the parent type has the properties of ice, if you add a new physical property make the default water's value for it.
	//that way liquids dont have to define everything

	/// kg / mole
	var/molar_mass = 0.01802
	/// kg / m^3
	var/density = 917
	/// m^3 / mole = molar_mass * 1/density
	var/molar_volume = 0.0000196
	///J/(mol * kelvin)
	var/molar_heat_capacity = 75.385
	/// microsiemens / cm
	var/electrical_conductivity = 55000
	/// watts / kelvin
	var/thermal_conductivity = 600

	//right now just used for spawning
	var/minimum_temperature_to_exist = -INFINITY
	var/maximum_temperature_to_exist = INFINITY

/datum/solid/ice
	name = "ice"

//molten metal?
/datum/solid/iron
	name = "iron"

/datum/material/ice
	name = "ice"
	desc = "Solid ice"
	color = "#6e9eb8"
	greyscale_colors = "#6e9eb8"
	strength_modifier = 0.5
	categories = list(MAT_CATEGORY_RIGID = TRUE)
	//sheet_type = /obj/item/stack/sheet/mineral/titanium
	value_per_unit = 0
	texture_layer_icon_state = "ice"
	beauty_modifier = 0
	armor_modifiers = list(MELEE = 0.5, BULLET = 0.5, LASER = 0.3, ENERGY = 0.25, BOMB = 0.25, BIO = 1, FIRE = 0.1, ACID = 1)

/datum/material/ice/on_applied_turf(turf/open/T, amount, material_flags)
	. = ..()
	T.MakeDry(wet_setting = TURF_WET_ICE, amount = INFINITY)

/datum/material/ice/on_removed_turf(turf/open/T, amount, material_flags)
	. = ..()
	T.MakeDry(wet_setting = TURF_WET_ICE, amount = INFINITY)

/*
SUBSYSTEM_DEF(solids)
	name = "Solids"
	can_fire = TRUE
	init_order = INIT_ORDER_LIQUIDS
	priority = FIRE_PRIORITY_FLUIDS
	wait = 0.5 SECONDS
	flags = SS_BACKGROUND|SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/reactions_by_pressure_by_temperature = list()
	var/allow_reactions = TRUE

	var/list/active_turfs = list()
	var/list/currentrun

/datum/controller/subsystem/solids/fire(resumed)
	var/fire_count = times_fired
	if (!resumed)
		src.currentrun = active_turfs.Copy()
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/turf/open/T = currentrun[currentrun.len]
		currentrun.len--
		if (T)
			T.process_solids(fire_count)
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/solids/proc/add_active_turf(turf/open/active_turf)
	if(!istype(active_turf))
		return

	active_turfs |= active_turf

/datum/controller/subsystem/solids/proc/remove_active_turf(turf/active_turf)
	active_turfs -= active_turf
	currentrun -= active_turf

*/

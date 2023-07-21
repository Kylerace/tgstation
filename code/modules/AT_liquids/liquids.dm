///liquids list index containing the list of the moles of every liquid that existed the last SSliquids fire
#define LIQUID_CURRENT 1
///liquids list index containing the list of the moles of every liquid that's being processed in the current SSliquids fire, and will become LIQUID_CURRENT at the end
#define LIQUID_NEXT 2

///CELL_VOLUME = 2500 liters, this is 2.5 m^3
#define LIQUID_CELL_VOLUME 2.5

GLOBAL_VAR_INIT(liquids_display_moles, TRUE)

#define TOTAL_LIQUID_MOLES(cached_liquids, out_var)\
	out_var = 0;\
	for(var/liquid_path in cached_liquids) {\
		out_var += cached_liquids[liquid_path];\
	}

#define LIQUID_CYCLE_ARCHIVE(turf)\
	turf.liquids.archive();\
	turf.liquid_archived_cycle = SSliquids.times_fired;\
	turf.liquids.temperature_archived = turf.liquids.temperature;

/turf
	var/datum/liquid_mix/liquids

	var/liquid_archived_cycle = 0
	var/liquid_current_cycle = 0

	var/obj/effect/overlay/liquid/liquid_overlay

/turf/open/Initialize(mapload)
	. = ..()
	liquids = new
	liquids.temperature = temperature
	liquids.temperature_archived = temperature

/turf/proc/assert_liquid(amount = 1000, liquid_type = /datum/liquid/water)
	if(amount < 0 || !(liquid_type in subtypesof(/datum/liquid)))
		return
	var/list/cached_liquid_list = liquids.liquids

	var/total_moles = 0
	TOTAL_LIQUID_MOLES(cached_liquid_list[LIQUID_NEXT], total_moles)

	if(total_moles > 0)

		if(amount > 0)
			cached_liquid_list[LIQUID_NEXT][liquid_type] = amount
		else
			cached_liquid_list[LIQUID_NEXT] -= liquid_type
			TOTAL_LIQUID_MOLES(cached_liquid_list[LIQUID_NEXT], total_moles)
			if(total_moles == 0)
				SSliquids.remove_active_turf(src)

	else if(amount > 0)
		liquids.liquids[LIQUID_CURRENT][liquid_type] = amount
		liquids.liquids[LIQUID_NEXT][liquid_type] = amount
		liquids.temperature = temperature
		liquids.temperature_archived = temperature_archived
		SSliquids.add_active_turf(src)

/turf/proc/set_liquid_temp(new_temp)
	liquids.temperature = new_temp

/turf/proc/process_liquids(fire_count)
	SSliquids.remove_active_turf(src)

/turf/open/process_liquids(fire_count)
	if(liquid_archived_cycle < fire_count)
		LIQUID_CYCLE_ARCHIVE(src)

	//this makes it so if process_liquids is called on any of our neighbors in the same atmos cycle after us, they wont share with us
	//because we already shared with them
	liquid_current_cycle = fire_count

	var/has_gravity = has_gravity(src)

	var/list/atmos_adjacent_turfs = src.atmos_adjacent_turfs

	var/datum/liquid_mix/our_liquids = liquids

	var/our_share_coeff = 0

	var/list/us_all_deltas = list()

	var/our_z = z

	if(has_gravity)
		var/horizontal_neighbors = 0

		for(var/turf/open/adjacent_turf as anything in atmos_adjacent_turfs)
			if(our_z == adjacent_turf.z)
				horizontal_neighbors++

		our_share_coeff = 1/(horizontal_neighbors + 1)

		for(var/turf/open/adjacent_turf as anything in atmos_adjacent_turfs)
			if(fire_count <= adjacent_turf.liquid_current_cycle)
				continue
			LIQUID_CYCLE_ARCHIVE(adjacent_turf)

			SSliquids.add_active_turf(adjacent_turf)
			var/datum/liquid_mix/their_liquids = adjacent_turf.liquids
			var/their_z = adjacent_turf.z

			if(our_z != their_z)
				var/datum/liquid_mix/top_turf_liquids = our_liquids
				var/datum/liquid_mix/bottom_turf_liquids = their_liquids
				if(their_z > our_z)
					top_turf_liquids = their_liquids
					bottom_turf_liquids = our_liquids

				top_turf_liquids.uni_flow(bottom_turf_liquids)//i think this might work, though it will definitely allow liquids to be in the air for a cycle
				//we want everything in top_turf_liquids[LIQUID_CURRENT] to be moved to bottom_turf_liquids[LIQUID_NEXT]
				//if we dont archive after this, our_liquids.flow(horizontal_neighbor_liquids) will use liquids that shouldve gone down or shouldnt
				//be shareable until next cycle

				LIQUID_CYCLE_ARCHIVE(src)

				continue

			var/their_horizontal_neighbors = 0
			for(var/turf/open/their_adjacent_turf as anything in adjacent_turf.atmos_adjacent_turfs)
				if(their_z == their_adjacent_turf.z)
					their_horizontal_neighbors++

			var/their_share_coeff = 1/(their_horizontal_neighbors + 1)

			var/difference = our_liquids.flow(their_liquids, our_share_coeff, their_share_coeff, us_all_deltas)

	else
		//just equalize with neighbors that already have liquids, dont spread to new cells
		var/neighbors_with_liquids = 0
		for(var/turf/open/adjacent_turf as anything in atmos_adjacent_turfs)
			if(adjacent_turf.liquids.volume > 0)
				neighbors_with_liquids++

		our_share_coeff = 1/(neighbors_with_liquids + 1)

		for(var/turf/open/adjacent_turf as anything in atmos_adjacent_turfs)
			if(fire_count <= adjacent_turf.liquid_current_cycle)
				continue
			LIQUID_CYCLE_ARCHIVE(adjacent_turf)

			var/datum/liquid_mix/their_liquids = adjacent_turf.liquids
			if(their_liquids.volume <= 0)
				continue

			SSliquids.add_active_turf(adjacent_turf)

			var/their_neighbors_with_liquids = 0
			for(var/turf/open/their_adjacent_turf as anything in adjacent_turf.atmos_adjacent_turfs)
				if(their_adjacent_turf.liquids.volume > 0)
					their_neighbors_with_liquids++

			var/their_share_coeff = 1/(their_neighbors_with_liquids + 1)

			our_liquids.flow(their_liquids, our_share_coeff, their_share_coeff)

	our_liquids.react()

	update_liquid_visuals()


/obj/effect/overlay/liquid
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = FLY_LAYER
	plane = GAME_PLANE
	appearance_flags = TILE_BOUND
	vis_flags = NONE
	var/plane_offset = 0

/obj/effect/overlay/liquid/New(loc, list/overlays = list(), alph, plane_offset)
	. = ..()
	src.overlays = overlays
	alpha = alph
	src.plane_offset = plane_offset

/obj/effect/overlay/liquid/Initialize(mapload)
	. = ..()
	SET_PLANE_W_SCALAR(src, initial(plane), plane_offset)

/proc/sigmoid_ease(k, t)
	if(k == 0)
		k = 10 ** -7 //discontinuity patch
	t = clamp(t, 0, 1)

	#define EULERS_CONSTANT 2.718281828459
	#define BASE(_t) (1 / (1 + (EULERS_CONSTANT ** (-k * (_t))))) - 0.5

	return (0.5 / BASE(1)) * BASE(2 * t - 1) + 0.5
	#undef BASE
	#undef EULERS_CONSTANT

/turf/proc/update_liquid_visuals()
	var/datum/liquid_mix/our_liquids = liquids
	var/total_moles = 0

	TOTAL_LIQUID_MOLES(our_liquids?.liquids[LIQUID_NEXT], total_moles)

	if(GLOB.liquids_display_moles == FALSE)
		maptext = null

	if(length(our_liquids?.liquids[LIQUID_NEXT]))//add liquid overlay to ourselves if it doesnt exist already
		var/liquids_string = ""
		var/list/overlays = list()
		for(var/datum/liquid/liquid_path as anything in our_liquids.liquids[LIQUID_NEXT])
			liquids_string += initial(liquid_path.name)[1]
			overlays += mutable_appearance(initial(liquid_path.icon), initial(liquid_path.icon_state), alpha = 150)
		if(GLOB.liquids_display_moles == TRUE)
			maptext = "[round(total_moles, 0.1)]-[liquids_string]"

		vis_contents -= liquid_overlay
		//liquid_image = mutable_appearance('icons/turf/beach.dmi', "water", plane = offset)
		liquid_overlay = new(null, overlays, 150, GET_TURF_PLANE_OFFSET(src) + 1)
		vis_contents |= liquid_overlay

	else//remove the liquid image from ourselves if its there
		if(!liquid_overlay)
			return
		if(GLOB.liquids_display_moles == TRUE)
			maptext = null
		vis_contents -= liquid_overlay
		qdel(liquid_overlay)
		liquid_overlay = null

/datum/liquid_mix
	///nested list of the form: list(LIQUID_CURRENT moles list, LIQUID_NEXT moles list), where each sublist is of the form: list(/datum/liquid subtype path = number_of_moles_of_that_liquid)
	var/list/liquids = list(list(), list())
	var/temperature = TCMB
	var/temperature_archived = TCMB
	//can exceed CELL_VOLUME, if it does then the remainder increases pressure which can flow against gravity
	var/volume = 0
	var/volume_archived = 0

	//pascals, for now only used if volume > CELL_VOLUME
	var/pressure = 0
	var/pressure_archived = 0

	///the difference between the pressure towards our center on the +z face
	var/pz = 0
	var/pz_archived = 0
	var/py = 0
	var/py_archived = 0
	var/px = 0
	var/px_archived = 0

	var/last_diffuse = 0

	var/list/solutes

	var/vel_x = 0
	var/vel_y = 0
	var/vel_z = 0

/datum/liquid_phases //probably wont do this, for now definitely assume all liquids are perfectly soluable to all other liquids

/datum/liquid_mix/proc/archive()
	//var/list/cached_liquids = liquids
	liquids[LIQUID_CURRENT] = liquids[LIQUID_NEXT].Copy()
	volume_archived = volume
	temperature_archived = temperature

/datum/liquid_mix/proc/flow(datum/liquid_mix/sharer, our_coeff, their_coeff, list/us_all_deltas)
	var/our_volume = volume_archived
	var/their_volume = sharer.volume_archived

	var/list/our_liquids = liquids
	var/list/their_liquids = sharer.liquids

	var/list/only_in_us = our_liquids[LIQUID_CURRENT] - their_liquids[LIQUID_CURRENT]
	var/list/only_in_them = their_liquids[LIQUID_CURRENT] - our_liquids[LIQUID_CURRENT]

	var/temperature_delta = temperature_archived - sharer.temperature_archived
	var/abs_temperature_delta = abs(temperature_delta)

	var/moved_moles = 0
	var/abs_moved_moles = 0

	var/heat_capacity_self_to_sharer = 0
	var/heat_capacity_sharer_to_self = 0

	var/our_old_heat_capacity = 0
	var/sharer_old_heat_capacity = 0

	for(var/new_to_us in only_in_them)
		our_liquids[LIQUID_NEXT][new_to_us] = 0
		our_liquids[LIQUID_CURRENT][new_to_us] = 0
	for(var/new_to_them in only_in_us)
		their_liquids[LIQUID_NEXT][new_to_them] = 0
		their_liquids[LIQUID_CURRENT][new_to_them] = 0

	for(var/datum/liquid/liquid_path as anything in our_liquids[LIQUID_CURRENT])
		var/our_moles = our_liquids[LIQUID_CURRENT][liquid_path]
		var/their_moles = their_liquids[LIQUID_CURRENT][liquid_path]

		var/delta = QUANTIZE(our_moles - their_moles)//TODOKYLER: need to make this work off of volume
		if(!delta)
			continue

		var/liquid_capacity = initial(liquid_path.specific_heat_capacity)

		our_old_heat_capacity += our_moles * liquid_capacity
		sharer_old_heat_capacity += their_moles * liquid_capacity

		if(delta > 0)
			delta *= our_coeff
			heat_capacity_self_to_sharer += delta * liquid_capacity
		else
			delta *= their_coeff
			heat_capacity_sharer_to_self -= delta * liquid_capacity

		//us_all_deltas += -delta

		var/old_us = our_liquids[LIQUID_NEXT][liquid_path]
		var/old_them = their_liquids[LIQUID_NEXT][liquid_path]

		our_liquids[LIQUID_NEXT][liquid_path] -= delta
		their_liquids[LIQUID_NEXT][liquid_path] += delta

		var/volume_delta = delta * initial(liquid_path.molar_volume)
		volume -= volume_delta
		sharer.volume += volume_delta

		if(our_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1
		if(their_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1

		moved_moles += delta
		abs_moved_moles += abs(delta)

	if(heat_capacity_self_to_sharer || heat_capacity_sharer_to_self)
		var/our_new_heat_capacity = our_old_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
		var/sharer_new_heat_capacity = sharer_old_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self

		temperature = (our_old_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / our_new_heat_capacity
		sharer.temperature = (sharer_old_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / sharer_new_heat_capacity

	if(length(only_in_them) || length(only_in_us))
		garbage_collect()
		sharer.garbage_collect()

	return moved_moles

///tries to move as many of our moles into the target mix as possible, stopping if their volume exceeds CELL_VOLUME
/datum/liquid_mix/proc/uni_flow(datum/liquid_mix/sharer)
	var/our_volume = volume_archived
	if(!our_volume)
		return
	var/their_volume = sharer.volume_archived

	var/their_volume_to_fill = LIQUID_CELL_VOLUME - their_volume
	if(their_volume_to_fill <= 0)
		return

	///how much volume can be moved from us to them / how much volume we have. scales the number of moles we move into them from each liquid in us
	var/volume_ratio = min(their_volume_to_fill, our_volume) / our_volume

	var/list/our_liquids = liquids
	var/list/their_liquids = sharer.liquids

	var/list/only_in_us = our_liquids[LIQUID_CURRENT] - their_liquids[LIQUID_CURRENT]

	var/temperature_delta = temperature_archived - sharer.temperature_archived
	var/abs_temperature_delta = abs(temperature_delta)

	var/heat_capacity_self_to_sharer = 0
	var/heat_capacity_sharer_to_self = 0

	var/our_old_heat_capacity = 0
	var/sharer_old_heat_capacity = 0

	var/moved_moles = 0
	var/abs_moved_moles = 0

	for(var/new_to_them in only_in_us)
		their_liquids[LIQUID_NEXT][new_to_them] = 0

	for(var/datum/liquid/liquid_path as anything in our_liquids[LIQUID_CURRENT])
		var/our_moles = our_liquids[LIQUID_CURRENT][liquid_path]
		var/their_moles = their_liquids[LIQUID_CURRENT][liquid_path]

		var/liquid_capacity = initial(liquid_path.specific_heat_capacity)

		our_old_heat_capacity += our_moles * liquid_capacity
		sharer_old_heat_capacity += their_moles * liquid_capacity

		var/delta = QUANTIZE(our_moles * volume_ratio)//this effectively squares the quantization threshold in some cases when moving liquids down
		if(!delta)
			continue

		var/old_us = our_liquids[LIQUID_NEXT][liquid_path]
		var/old_them = their_liquids[LIQUID_NEXT][liquid_path]

		our_liquids[LIQUID_NEXT][liquid_path] -= delta
		their_liquids[LIQUID_NEXT][liquid_path] += delta

		heat_capacity_self_to_sharer += delta * liquid_capacity

		var/volume_delta = delta * initial(liquid_path.molar_volume)
		volume -= volume_delta
		sharer.volume += volume_delta


		if(our_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1
		if(their_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1

		moved_moles += delta
		abs_moved_moles += abs(delta)

	if(heat_capacity_self_to_sharer || heat_capacity_sharer_to_self)
		var/our_new_heat_capacity = our_old_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
		var/sharer_new_heat_capacity = sharer_old_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self

		temperature = (our_old_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / our_new_heat_capacity
		sharer.temperature = (sharer_old_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / sharer_new_heat_capacity

	garbage_collect()

	return moved_moles

/datum/liquid_mix/proc/garbage_collect()
	var/list/cached_liquids = liquids
	for(var/liquid_path in cached_liquids[LIQUID_NEXT])
		if(QUANTIZE(cached_liquids[LIQUID_NEXT][liquid_path]) <= 0)
			cached_liquids[LIQUID_NEXT] -= liquid_path

/datum/liquid_mix/proc/react()
	return

/datum/liquid
	var/name = "AHHH"
	var/icon
	var/icon_state

	/// kg / mole
	var/molar_mass = 0
	/// kg / m^3
	var/density = 0
	/// m^3 / mole = molar_mass * 1/density
	var/molar_volume = 0
	///mega pascal seconds
	var/viscosity = 0
	///J/(mol * kelvin)
	var/specific_heat_capacity = 0
	/// J / m^2
	var/surface_tension = 0



/datum/liquid/water
	name = "water"
	icon = 'icons/turf/beach.dmi'
	icon_state = "water"
	// kg / mole
	molar_mass = 0.01802
	// kg / m^3
	density = 997
	// m^3 / mole
	molar_volume = 0.00001807
	//mega pascal seconds
	viscosity = 1.0016
	// J / (mole * kelvin)
	specific_heat_capacity = 75.385
	// J / m^2
	surface_tension = 0.07275

/datum/liquid/lava
	name = "lava"
	icon = 'icons/turf/floors/lava.dmi'
	icon_state = "lava-255"

/datum/liquid/blood
	name = "blood"
	icon = 'icons/turf/liquids/blood.dmi'
	icon_state = "blood"

/datum/liquid_reaction
	var/name = "AAAAA"
/datum/liquid_reaction/proc/react()
	return

SUBSYSTEM_DEF(liquids)
	name = "Liquids"
	can_fire = TRUE
	init_order = INIT_ORDER_LIQUIDS
	priority = FIRE_PRIORITY_FLUIDS
	wait = 0.5 SECONDS
	flags = SS_BACKGROUND|SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/active_turfs = list()
	var/list/currentrun

/datum/controller/subsystem/liquids/fire(resumed)
	var/fire_count = times_fired
	if (!resumed)
		src.currentrun = active_turfs.Copy()
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/turf/open/T = currentrun[currentrun.len]
		currentrun.len--
		if (T)
			T.process_liquids(fire_count)
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/liquids/proc/add_active_turf(turf/open/new_turf)
	if(!istype(new_turf))
		stack_trace("wrong turf type! [new_turf]")
	active_turfs |= new_turf

/datum/controller/subsystem/liquids/proc/remove_active_turf(turf/old_turf)
	active_turfs -= old_turf

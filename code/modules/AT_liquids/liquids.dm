
/// Molar accuracy to round to
#define LIQUID_MOLAR_ACCURACY  0.1
#define LIQUID_QUANTIZE(variable) (round((variable), (LIQUID_MOLAR_ACCURACY)))

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

///holy based
//turf/proc/cell_react(datum/gas_mixture/gas_interface, datum/liquid_mix/liquid_interface, datum/solid_mix/solid_interface, temperature, pressure)

/turf/proc/assert_liquid(amount = 10000, datum/liquid/liquid_type = /datum/liquid/water, set_temp = TRUE)
	if(amount < 0 || !(liquid_type in subtypesof(/datum/liquid)))
		return
	var/list/cached_liquid_list = liquids.liquids

	var/minimum_temp = initial(liquid_type.minimum_temperature_to_exist)//we dont want
	var/maximum_temp = initial(liquid_type.maximum_temperature_to_exist)
	if(set_temp != TRUE)
		minimum_temp = -INFINITY//make it temp isnt set to whatever the liquid needs to exist at
		maximum_temp = INFINITY

	var/total_moles = 0
	TOTAL_LIQUID_MOLES(cached_liquid_list[LIQUID_NEXT], total_moles)

	if(total_moles > 0)

		if(amount > 0)
			cached_liquid_list[LIQUID_NEXT][liquid_type] = amount

			if(minimum_temp > -INFINITY)
				liquids.temperature = max(liquids.temperature, minimum_temp)
			else if(maximum_temp < INFINITY)
				liquids.temperature = min(liquids.temperature, maximum_temp)
		else
			cached_liquid_list[LIQUID_NEXT] -= liquid_type
			TOTAL_LIQUID_MOLES(cached_liquid_list[LIQUID_NEXT], total_moles)
			if(total_moles == 0)
				SSliquids.remove_active_turf(src)

	else if(amount > 0)
		liquids.liquids[LIQUID_CURRENT][liquid_type] = amount
		liquids.liquids[LIQUID_NEXT][liquid_type] = amount

		if(minimum_temp > -INFINITY)
			liquids.temperature = max(liquids.temperature, minimum_temp)
		else if(maximum_temp < INFINITY)
			liquids.temperature = min(liquids.temperature, maximum_temp)

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

	var/list/differences

	if(has_gravity)
		var/horizontal_neighbors = 0

		var/turf/open/above_turf
		var/list/adjacent_turfs_to_exclude

		for(var/turf/open/adjacent_turf as anything in atmos_adjacent_turfs)
			if(our_z == adjacent_turf.z)
				horizontal_neighbors++

			else
				adjacent_turfs_to_exclude ||= list()

				if(our_z > adjacent_turf.z)//we are above, carry out the operation since it has priority over their_z > our_z
					adjacent_turfs_to_exclude += adjacent_turf
					if(fire_count <= adjacent_turf.liquid_current_cycle)
						continue
					LIQUID_CYCLE_ARCHIVE(adjacent_turf)

					our_liquids.uni_flow(adjacent_turf.liquids)

					LIQUID_CYCLE_ARCHIVE(src)
					SSliquids.add_active_turf(adjacent_turf)

					if(our_liquids.volume_archived == 0)
						SSliquids.remove_active_turf(src)
						return

				else //they are above, this has to be done after we dump onto a below turf if it exists, so we set above_turf to it
					if(adjacent_turf.liquids.volume_archived)
						above_turf = adjacent_turf
					adjacent_turfs_to_exclude += adjacent_turf

		if(above_turf && fire_count > above_turf.liquid_current_cycle)
			LIQUID_CYCLE_ARCHIVE(above_turf)
			above_turf.liquid_current_cycle = fire_count //pretend that process_liquids() was called on them but they only share with us

			above_turf.liquids.uni_flow(our_liquids)//i think this might work, though it will definitely allow liquids to be in the air for a cycle
			//we want everything in top_turf_liquids[LIQUID_CURRENT] to be moved to bottom_turf_liquids[LIQUID_NEXT]
			//if we dont archive after this, our_liquids.flow(horizontal_neighbor_liquids) will use liquids that shouldve gone down or shouldnt
			//be shareable until next cycle

			LIQUID_CYCLE_ARCHIVE(src)
			SSliquids.add_active_turf(above_turf)


		our_share_coeff = 1/(horizontal_neighbors + 1)

		for(var/turf/open/adjacent_turf as anything in atmos_adjacent_turfs - adjacent_turfs_to_exclude)
			if(fire_count <= adjacent_turf.liquid_current_cycle)
				continue
			LIQUID_CYCLE_ARCHIVE(adjacent_turf)

			SSliquids.add_active_turf(adjacent_turf)
			var/datum/liquid_mix/their_liquids = adjacent_turf.liquids
			var/their_z = adjacent_turf.z

			/*
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
				*/

			var/their_horizontal_neighbors = 0
			for(var/turf/open/their_adjacent_turf as anything in adjacent_turf.atmos_adjacent_turfs)
				if(their_z == their_adjacent_turf.z)
					their_horizontal_neighbors++

			var/their_share_coeff = 1/(their_horizontal_neighbors + 1)


			//list(mole net flow (to us - from us), our new chemicals, our removed chemicals, their new chemicals, their removed chemicals)
			differences = our_liquids.flow(their_liquids, our_share_coeff, their_share_coeff, us_all_deltas, src, adjacent_turf)

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

			differences = our_liquids.flow(their_liquids, our_share_coeff, their_share_coeff, list(), src, adjacent_turf)

	if(differences)
		var/list/our_new_chemicals = differences[2]
		var/list/our_removed_chemicals = differences[3]

		var/list/their_new_chemicals = differences[4]
		var/list/their_removed_chemicals = differences[5]

		//if(length(our_new_chemicals) || length(our_removed_chemicals) || length(their_new_chemicals) || length(their_removed_chemicals))
			//for(var/datum/liquid/new_liquid as anything in our_new_chemicals)

	if(SSliquids.allow_reactions)
		our_liquids.react(src)

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
			maptext = "[round(total_moles, 0.1)]\n[liquids_string]"

		vis_contents -= liquid_overlay
		//liquid_image = mutable_appearance('icons/turf/beach.dmi', "water", plane = offset)
		liquid_overlay = new(null, overlays, 150, SSmapping.z_level_to_plane_offset[z])
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

/datum/liquid_mix/proc/archive()
	//var/list/cached_liquids = liquids
	liquids[LIQUID_CURRENT] = liquids[LIQUID_NEXT].Copy()
	volume_archived = volume
	temperature_archived = temperature

#define MINIMUM_VOLUME_DELTA_TO_ACTIVATE 500
///cant make turf gas mixes have less volume than this
#define MINIMUM_AIR_VOLUME 0.01

/datum/liquid_mix/proc/flow(datum/liquid_mix/sharer, our_coeff, their_coeff, list/us_all_deltas, turf/open/us, turf/open/them)
	var/our_volume = volume_archived
	var/their_volume = sharer.volume_archived

	var/list/our_liquids = liquids
	var/list/their_liquids = sharer.liquids

	var/list/only_in_us = our_liquids[LIQUID_CURRENT] - their_liquids[LIQUID_CURRENT]
	var/list/only_in_them = their_liquids[LIQUID_CURRENT] - our_liquids[LIQUID_CURRENT]

	var/list/removed_from_us = list()
	var/list/removed_from_them = list()

	var/temperature_delta = temperature_archived - sharer.temperature_archived
	var/abs_temperature_delta = abs(temperature_delta)

	var/moved_moles = 0
	var/abs_moved_moles = 0

	var/heat_capacity_self_to_sharer = 0
	var/heat_capacity_sharer_to_self = 0

	var/our_old_heat_capacity = 0
	var/sharer_old_heat_capacity = 0

	var/total_volume_delta = 0

	for(var/new_to_us in only_in_them)
		our_liquids[LIQUID_NEXT][new_to_us] = 0
		our_liquids[LIQUID_CURRENT][new_to_us] = 0
	for(var/new_to_them in only_in_us)
		their_liquids[LIQUID_NEXT][new_to_them] = 0
		their_liquids[LIQUID_CURRENT][new_to_them] = 0

	for(var/datum/liquid/liquid_path as anything in our_liquids[LIQUID_CURRENT])
		var/our_moles = our_liquids[LIQUID_CURRENT][liquid_path]
		var/their_moles = their_liquids[LIQUID_CURRENT][liquid_path]

		var/molar_difference = (our_moles - their_moles)

		var/spreading_parameter = -1// <0 means partial wetting, > 0 means full wetting (infinitely spreading)

		var/viscosity = initial(liquid_path.viscosity)
		if(initial(liquid_path.surface_tension) == 0)
			spreading_parameter = 1//no internal forces to try to minimize surface area

		var/delta = 0
		if(viscosity > 0)//this isnt at all accurate to how it works
			delta = LIQUID_QUANTIZE(molar_difference * 1 / clamp(sqrt(viscosity), 1, 100))
		else
			delta = round(molar_difference, MOLAR_ACCURACY)//lower molar count
		if(!delta)
			continue

		var/liquid_capacity = initial(liquid_path.molar_heat_capacity)

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
		total_volume_delta += volume_delta

		volume -= volume_delta
		sharer.volume += volume_delta

		if(our_liquids[LIQUID_NEXT][liquid_path] < 0)
			removed_from_us += liquid_path
		if(their_liquids[LIQUID_NEXT][liquid_path] < 0)
			removed_from_them += liquid_path

		moved_moles += delta
		abs_moved_moles += abs(delta)

	var/our_old_gas_volume = us.air.volume
	var/their_old_gas_volume = them.air.volume

	us.air.volume = max(our_old_gas_volume + total_volume_delta * 1000, MINIMUM_AIR_VOLUME)
	them.air.volume = max(their_old_gas_volume - total_volume_delta * 1000, MINIMUM_AIR_VOLUME)

	if(abs(our_old_gas_volume - us.air.volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !us.excited)
		SSair.add_to_active(src)
	if(abs(their_old_gas_volume - them.air.volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !them.excited)
		SSair.add_to_active(them)

	var/our_new_heat_capacity = our_old_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
	var/sharer_new_heat_capacity = sharer_old_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self
	if(our_new_heat_capacity)
		temperature = (our_old_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / our_new_heat_capacity
	if(sharer_new_heat_capacity)
		sharer.temperature = (sharer_old_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / sharer_new_heat_capacity
		if(abs(sharer_old_heat_capacity) > MINIMUM_HEAT_CAPACITY)
			if(abs(sharer_new_heat_capacity/sharer_old_heat_capacity - 1) < 0.1) // <10% change in sharer heat capacity
				temperature_share(sharer, LIQUID_HEAT_TRANSFER_COEFFICIENT)

	if(length(only_in_them) || length(only_in_us))
		garbage_collect()
		sharer.garbage_collect()

	//list(mole net flow (to us - from us), our new chemicals, our removed chemicals, their new chemicals, their removed chemicals)
	return list(moved_moles, only_in_them, removed_from_us, only_in_us, removed_from_them)

///tries to move as many of our moles into the target mix as possible, stopping if their volume exceeds CELL_VOLUME
/datum/liquid_mix/proc/uni_flow(datum/liquid_mix/sharer, turf/open/us, turf/open/them)//TODOKYLER: make this diffuse if sharer cant be given all of our contents
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

	var/total_volume_delta = 0

	for(var/new_to_them in only_in_us)
		their_liquids[LIQUID_NEXT][new_to_them] = 0

	for(var/datum/liquid/liquid_path as anything in our_liquids[LIQUID_CURRENT])
		our_liquids[LIQUID_CURRENT][liquid_path] = LIQUID_QUANTIZE(our_liquids[LIQUID_CURRENT][liquid_path])

		var/our_moles = our_liquids[LIQUID_CURRENT][liquid_path]
		var/their_moles = their_liquids[LIQUID_CURRENT][liquid_path]

		var/liquid_capacity = initial(liquid_path.molar_heat_capacity)

		our_old_heat_capacity += our_moles * liquid_capacity
		sharer_old_heat_capacity += their_moles * liquid_capacity

		var/delta = LIQUID_QUANTIZE(our_moles * volume_ratio)//this effectively squares the quantization threshold in some cases when moving liquids down
		if(!delta)
			continue

		var/old_us = our_liquids[LIQUID_NEXT][liquid_path]
		var/old_them = their_liquids[LIQUID_NEXT][liquid_path]

		our_liquids[LIQUID_NEXT][liquid_path] -= delta
		their_liquids[LIQUID_NEXT][liquid_path] += delta

		heat_capacity_self_to_sharer += delta * liquid_capacity

		var/volume_delta = delta * initial(liquid_path.molar_volume)
		total_volume_delta += volume_delta

		volume -= volume_delta
		sharer.volume += volume_delta


		if(our_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1
		if(their_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1

		moved_moles += delta
		abs_moved_moles += abs(delta)

	var/our_old_gas_volume = us.air.volume
	var/their_old_gas_volume = them.air.volume

	us.air.volume = clamp(our_old_gas_volume + total_volume_delta * 1000, MINIMUM_AIR_VOLUME, CELL_VOLUME)
	them.air.volume = clamp(their_old_gas_volume - total_volume_delta * 1000, MINIMUM_AIR_VOLUME, CELL_VOLUME)

	if(abs(our_old_gas_volume - us.air.volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !us.excited)
		SSair.add_to_active(src)
	if(abs(their_old_gas_volume - them.air.volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !them.excited)
		SSair.add_to_active(them)

	var/our_new_heat_capacity = our_old_heat_capacity - heat_capacity_self_to_sharer// + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
	var/sharer_new_heat_capacity = sharer_old_heat_capacity + heat_capacity_self_to_sharer// - heat_capacity_sharer_to_self //dont need this since its 0
	if(our_new_heat_capacity)
		temperature = (our_old_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / our_new_heat_capacity
	if(sharer_new_heat_capacity)
		sharer.temperature = (sharer_old_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / sharer_new_heat_capacity

	garbage_collect()

	//list(mole net flow (to us - from us), our old chemicals, our new chemicals, their old chemicals, their new chemicals)
	//return list(moved_moles, original_us, only_in_them, original_them, only_in_us)

/datum/liquid_mix/proc/garbage_collect()
	var/list/cached_liquids = liquids
	for(var/liquid_path in cached_liquids[LIQUID_NEXT])
		if(LIQUID_QUANTIZE(cached_liquids[LIQUID_NEXT][liquid_path]) <= 0)
			cached_liquids[LIQUID_NEXT] -= liquid_path
			cached_liquids[LIQUID_CURRENT] -= liquid_path

///Performs temperature sharing calculations (via conduction) between two gas_mixtures assuming only 1 boundary length
///Returns: new temperature of the sharer
/datum/liquid_mix/proc/temperature_share(datum/liquid_mix/sharer, conduction_coefficient, sharer_temperature, sharer_heat_capacity)
	//transfer of thermal energy (via conduction) between self and sharer
	if(sharer)
		sharer_temperature = sharer.temperature_archived
	var/temperature_delta = temperature_archived - sharer_temperature
	if(abs(temperature_delta) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = 0
		for(var/datum/liquid/liquid_path as anything in liquids[LIQUID_CURRENT])
			var/moles = liquids[LIQUID_CURRENT][liquid_path]
			self_heat_capacity += moles * initial(liquid_path.molar_heat_capacity)

		sharer_heat_capacity = sharer_heat_capacity
		if(sharer_heat_capacity <= 0)
			sharer_heat_capacity = 0
			for(var/datum/liquid/liquid_path as anything in sharer.liquids[LIQUID_CURRENT])
				var/moles = sharer.liquids[LIQUID_CURRENT][liquid_path]
				sharer_heat_capacity += moles * initial(liquid_path.molar_heat_capacity)

		if((sharer_heat_capacity > MINIMUM_HEAT_CAPACITY) && (self_heat_capacity > MINIMUM_HEAT_CAPACITY))
			// coefficient applied first because some turfs have very big heat caps.
			var/heat = CALCULATE_CONDUCTION_ENERGY(conduction_coefficient * temperature_delta, sharer_heat_capacity, self_heat_capacity)

			temperature = max(temperature - heat/self_heat_capacity, TCMB)
			sharer_temperature = max(sharer_temperature + heat/sharer_heat_capacity, TCMB)
			if(sharer)
				sharer.temperature = sharer_temperature
	return sharer_temperature

/datum/liquid_mix/proc/react(turf/open/holder)
	if(!istype(holder))
		return

	var/temperature = src.temperature
	var/pressure = 0//TODOKYLER: figure this out
	var/list/solid_interfaces = list(holder.material_interface)
	var/datum/gas_mixture/gas_interface = holder.air

	//turf/holder, datum/liquid_mix/liquids, temperature, pressure, list/solid_interfaces, datum/gas_mixture/gas_interface
	for(var/datum/liquid_reaction/reaction as anything in GLOB.liquid_reactions)
		reaction.react(holder, src, temperature, pressure, holder.solids, gas_interface)

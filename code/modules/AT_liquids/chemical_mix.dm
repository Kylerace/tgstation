#define CHEMICAL_GASES 1
#define CHEMICAL_LIQUIDS 2
#define CHEMICAL_SOLIDS 3

#define CHEMICAL_NEXT 1
#define CHEMICAL_CURRENT 2
#define CHEMICAL_META 3

#define GAS_ACTIVE (1<<0)
#define LIQUID_ACTIVE (1<<1)
#define SOLID_ACTIVE (1<<2)

#define CHEMICAL_CYCLE_ARCHIVE(turf)\
	turf.chemicals.archive();\
	turf.archived_chemical_cycle = SSchemicals.times_fired;

/turf/proc/assert_chemical(amount = 10000, datum/chemical/chemical_type = /datum/chemical/water, temperature = null)
	if(amount < 0 || !(chemical_type in subtypesof(/datum/chemical)) || (temperature != null && temperature < TCMB))
		return

	var/datum/chemical_mix/chemicals = src.chemicals

	if(temperature == null)
		temperature = chemicals.temperature

	var/list/phase_list_to_use = chemicals.solids
	var/phase_prefix = "SOLID"

	var/solid_max_temp = initial(chemical_type.solid_max_temp)
	var/liquid_max_temp = initial(chemical_type.liquid_max_temp)

	if(liquid_max_temp && temperature > liquid_max_temp)
		phase_list_to_use = chemicals.gases
		phase_prefix = "GAS"

	else if(solid_max_temp && temperature > solid_max_temp)
		phase_list_to_use = chemicals.liquids
		phase_prefix = "LIQUID"

	if(phase_list_to_use[chemical_type])
		phase_list_to_use[chemical_type][CHEMICAL_NEXT] += amount
	else
		phase_list_to_use[chemical_type] = list(amount, amount, SSchemicals.chemical_metas["[phase_prefix][chemical_type]"])

	switch(phase_prefix)
		if("SOLID")
			SSchemicals.add_solid_turf(src)
		if("LIQUID")
			SSchemicals.add_liquid_turf(src)
		if("GAS")
			SSchemicals.add_gas_turf(src)

	chemicals.temperature = temperature

/turf // /atom

	var/chemical_cycle = 0
	var/archived_chemical_cycle = 0

	var/list/reacting

	var/datum/chemical_mix/turf/chemicals

	var/active_phases = NONE

/turf/open/Initialize(mapload)
	. = ..()
	chemicals = new

/datum/chemical_mix

	var/vv_tag = 0

	/**
	 * chemical list format is list(/datum/chemical/subtype = list(MOLES, ARCHIVE, META))
	 * we need the meta list for things that
	 */

	var/list/gases = list()
	///chemicals that diffuse and flow
	///[ARCHIVE, MOLES]
	var/list/liquids = list()
	///[ARCHIVE, MOLES]. separated from fluids for grouping purposes
	var/list/solids = list()

	///atoms with solid surfaces (i dont know how i want to do this)
	var/list/solid_objects

	var/reaction_hash = ""
	var/list/inactive_reactions = list()
	///list of all reactions that are doing something
	var/list/active_reactions = list()

	var/max_volume = CELL_VOLUME

	var/gas_volume = CELL_VOLUME
	var/gas_volume_archived = CELL_VOLUME

	var/liquid_volume = 0
	var/liquid_volume_archived = 0

	var/solid_volume = 0
	var/solid_volume_archived = 0

	/// pressure
	var/gas_pressure = 0
	var/liquid_pressure = 0

	var/temperature = TCMB
	var/temperature_archived = TCMB

/datum/chemical_mix/turf

/turf/proc/process_chemicals(fire_count)
	//SSchemicals.remove_active_turf(src)
	SSchemicals.remove_gas_turf(src)
	SSchemicals.remove_liquid_turf(src)
	SSchemicals.remove_solid_turf(src)

/turf/open/process_chemicals(fire_count)
	if(archived_chemical_cycle < fire_count)
		CHEMICAL_CYCLE_ARCHIVE(src)

	chemical_cycle = fire_count

	var/active_phases = src.active_phases

	var/datum/chemical_mix/our_chemicals = chemicals

	//1st step: fluid diffusion

	if(active_phases & GAS_ACTIVE)
		var/list/adjacent_turfs = atmos_adjacent_turfs
		//var/datum/excited_group/our_excited_group = excited_group
		var/our_share_coeff = 1/(LAZYLEN(adjacent_turfs) + 1)

		var/list/share_end

		for(var/turf/open/adjacent_turf as anything in adjacent_turfs)
			if(adjacent_turf.run_later)
				LAZYADD(share_end, adjacent_turf)

			if(fire_count <= adjacent_turf.chemical_cycle)
				continue
			CHEMICAL_CYCLE_ARCHIVE(adjacent_turf)

			var/should_share_air = FALSE
			var/datum/chemical_mix/their_chemicals = adjacent_turf.chemicals
			our_chemicals.share_gas(their_chemicals, our_share_coeff, 1 / (length(adjacent_turf.atmos_adjacent_turfs) + 1))

			/*
			//cache for sanic speed
			var/datum/excited_group/enemy_excited_group = adjacent_turf.excited_group

			//If we are both in an excited group, and they aren't the same, merge.
			//If we are both in an excited group, and you're active, share
			//If we pass compare, and if we're not already both in a group, lets join up
			//If we both pass compare, add to active and share

			if(our_excited_group && enemy_excited_group)
				if(our_excited_group != enemy_excited_group)
					//combine groups (this also handles updating the excited_group var of all involved turfs)
					our_excited_group.merge_groups(enemy_excited_group)
					our_excited_group = excited_group //update our cache
			if(our_excited_group && enemy_excited_group && enemy_tile.excited) //If you're both excited, no need to compare right?
				should_share_air = TRUE
			else if(our_air.compare(enemy_air)) //Lets see if you're up for it
				SSchemicals.add_gas_turf(enemy_tile) //Add yourself young man
				var/datum/excited_group/existing_group = our_excited_group || enemy_excited_group || new
				if(!our_excited_group)
					existing_group.add_turf(src)
				if(!enemy_excited_group)
					existing_group.add_turf(enemy_tile)
				our_excited_group = excited_group
				should_share_air = TRUE

			//air sharing
			if(should_share_air)
				var/difference = our_air.share(enemy_air, our_share_coeff, 1 / (LAZYLEN(enemy_tile.atmos_adjacent_turfs) + 1))
				if(difference)
					if(difference > 0)
						consider_pressure_difference(enemy_tile, difference)
					else
						enemy_tile.consider_pressure_difference(src, -difference)
				//This acts effectivly as a very slow timer, the max deltas of the group will slowly lower until it breaksdown, they then pop up a bit, and fall back down until irrelevant
				LAST_SHARE_CHECK
			*/



	if(active_phases & LIQUID_ACTIVE)
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

					if(our_z > adjacent_turf.z)
						adjacent_turfs_to_exclude += adjacent_turf
						if(fire_count <= adjacent_turf.chemical_cycle)
							continue

						CHEMICAL_CYCLE_ARCHIVE(adjacent_turf)

						our_chemicals.uni_flow(adjacent_turf.chemicals, 1, src, adjacent_turf)

						CHEMICAL_CYCLE_ARCHIVE(src)
						SSchemicals.add_liquid_turf(adjacent_turf)

						if(our_chemicals.liquid_volume_archived == 0)
							SSchemicals.remove_liquid_turf(src)
							break

					else
						if(adjacent_turf.chemicals.liquid_volume_archived > 0)
							above_turf = adjacent_turf
						adjacent_turfs_to_exclude += adjacent_turf

			if(above_turf && fire_count > above_turf.chemical_cycle)
				CHEMICAL_CYCLE_ARCHIVE(above_turf)
				above_turf.chemical_cycle = fire_count

				above_turf.chemicals.uni_flow(our_liquids, 1, above_turf, src)

				CHEMICAL_CYCLE_ARCHIVE(src)
				SSchemicals.add_liquid_turf(above_turf)

			our_share_coeff = 1/(horizontal_neighbors + 1)

			for(var/turf/open/adjacent_turf as anything in atmos_adjacent_turfs)
				if(fire_count <= adjacent_turf.chemical_cycle)
					continue

				CHEMICAL_CYCLE_ARCHIVE(adjacent_turf)

				SSchemicals.add_liquid_turf(adjacent_turf)
				var/datum/chemical_mix/their_chemicals = adjacent_turf.chemicals
				var/their_z = adjacent_turf.z


				var/their_horizontal_neighbors = 0
				for(var/turf/open/their_adjacent_turf as anything in adjacent_turf.atmos_adjacent_turfs)
					if(their_z == their_adjacent_turf.z)
						their_horizontal_neighbors++

				var/their_share_coeff = 1/(their_horizontal_neighbors + 1)

				differences = our_chemicals.flow(their_chemicals, our_share_coeff, their_share_coeff, null, src, adjacent_turf)



	//2nd step: reactions
	chemicals.handle_phase_changes(src)
	chemicals.react(src)

	//3rd step: visuals
	update_chemical_visuals()


GLOBAL_VAR_INIT(chemicals_display_moles, TRUE)

/turf/proc/update_chemical_visuals()
	var/datum/chemical_mix/chemicals = src.chemicals
	if(GLOB.chemicals_display_moles == FALSE)
		return

	var/gas_moles = 0
	var/liquid_moles = 0
	var/solid_moles = 0
	var/temperature = chemicals.temperature

	for(var/datum/chemical/chemical as anything in chemicals.gases)
		gas_moles += chemicals.gases[chemical][CHEMICAL_CURRENT]
	for(var/datum/chemical/chemical as anything in chemicals.liquids)
		liquid_moles += chemicals.liquids[chemical][CHEMICAL_CURRENT]
	for(var/datum/chemical/chemical as anything in chemicals.solids)
		solid_moles += chemicals.solids[chemical][CHEMICAL_CURRENT]

	maptext = "<span style='font-size: 6px'>G: [round(gas_moles, 0.1)]\nL: [round(liquid_moles, 0.1)]\nS: [round(solid_moles, 0.1)]</span>"

/datum/chemical_mix/proc/garbage_collect()
	for(var/datum/chemical/chemical in gases)
		if(QUANTIZE(gases[chemical][CHEMICAL_CURRENT]) <= 0)
			gases -= chemical
	for(var/datum/chemical/chemical in liquids)
		if(QUANTIZE(liquids[chemical][CHEMICAL_CURRENT]) <= 0)
			liquids -= chemical
	for(var/datum/chemical/chemical in solids)
		if(QUANTIZE(solids[chemical][CHEMICAL_CURRENT]) <= 0)
			solids -= chemical

/datum/chemical_mix/proc/share_gas(datum/chemical_mix/sharer, our_coeff, sharer_coeff)
	var/list/cached_gases = gases
	var/list/sharer_gases = sharer.gases

	var/list/only_in_sharer = sharer_gases - cached_gases
	var/list/only_in_cached = cached_gases - sharer_gases

	var/temperature_delta = temperature_archived - sharer.temperature_archived
	var/abs_temperature_delta = abs(temperature_delta)

	var/old_self_heat_capacity = 0
	var/old_sharer_heat_capacity = 0
	if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		old_self_heat_capacity = heat_capacity(CHEMICAL_GASES)
		old_sharer_heat_capacity = sharer.heat_capacity(CHEMICAL_GASES)

	var/heat_capacity_self_to_sharer = 0 //heat capacity of the moles transferred from us to the sharer
	var/heat_capacity_sharer_to_self = 0 //heat capacity of the moles transferred from the sharer to us

	var/moved_moles = 0
	var/abs_moved_moles = 0

	//GAS TRANSFER

	//Prep
	for(var/id in only_in_sharer) //create gases not in our cache
		//ADD_GAS(id, cached_gases)
		cached_gases[id] = list(0,0,null)
	for(var/id in only_in_cached) //create gases not in the sharing mix
		//ADD_GAS(id, sharer_gases)
		sharer_gases[id] = list(0,0,null)

	var/our_pressure_coeff = 1 / gas_volume
	var/their_pressure_coeff = 1 / sharer.gas_volume

	for(var/datum/chemical/id as anything in cached_gases) //transfer gases
		var/gas = cached_gases[id]
		var/sharergas = sharer_gases[id]

		var/delta = QUANTIZE(our_pressure_coeff * gas[CHEMICAL_CURRENT] - their_pressure_coeff * sharergas[CHEMICAL_CURRENT])
		//delta = QUANTIZE((gas[ARCHIVE]/sharer.volume - sharergas[ARCHIVE]/volume) * CELL_VOLUME) //the amount of gas that gets moved between the mixtures

		if(!delta)
			continue

		// If we have more gas then they do, ga s is moving from us to them
		// This means we want to scale it by our coeff. Vis versa for their case
		if(delta > 0)
			delta = delta * our_coeff / our_pressure_coeff
		else
			delta = delta * sharer_coeff / their_pressure_coeff

		if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			var/gas_heat_capacity = delta * initial(id.molar_heat_capacity)//gas[GAS_META][META_GAS_SPECIFIC_HEAT]
			if(delta > 0)
				heat_capacity_self_to_sharer += gas_heat_capacity
			else
				heat_capacity_sharer_to_self -= gas_heat_capacity //subtract here instead of adding the absolute value because we know that delta is negative.

		gas[MOLES] -= delta
		sharergas[MOLES] += delta
		moved_moles += delta
		abs_moved_moles += abs(delta)

	//last_share = abs_moved_moles

	//THERMAL ENERGY TRANSFER
	if(abs_temperature_delta > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/new_self_heat_capacity = old_self_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
		var/new_sharer_heat_capacity = old_sharer_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self

		//transfer of thermal energy (via changed heat capacity) between self and sharer
		if(new_self_heat_capacity > MINIMUM_HEAT_CAPACITY)
			temperature = (old_self_heat_capacity*temperature - heat_capacity_self_to_sharer*temperature_archived + heat_capacity_sharer_to_self*sharer.temperature_archived)/new_self_heat_capacity

		if(new_sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
			sharer.temperature = (old_sharer_heat_capacity*sharer.temperature-heat_capacity_sharer_to_self*sharer.temperature_archived + heat_capacity_self_to_sharer*temperature_archived)/new_sharer_heat_capacity
		//thermal energy of the system (self and sharer) is unchanged

			if(abs(old_sharer_heat_capacity) > MINIMUM_HEAT_CAPACITY)
				if(abs(new_sharer_heat_capacity/old_sharer_heat_capacity - 1) < 0.1) // <10% change in sharer heat capacity
					temperature_share(sharer, OPEN_HEAT_TRANSFER_COEFFICIENT)

	if(length(only_in_sharer + only_in_cached)) //if all gases were present in both mixtures, we know that no gases are 0
		garbage_collect(only_in_cached) //any gases the sharer had, we are guaranteed to have. gases that it didn't have we are not.
		sharer.garbage_collect(only_in_sharer) //the reverse is equally true
	//else if (initial(sharer.gc_share))
	//	sharer.garbage_collect()

	if(temperature_delta > MINIMUM_TEMPERATURE_TO_MOVE || abs(moved_moles) > MINIMUM_MOLES_DELTA_TO_MOVE)
		var/our_moles
		TOTAL_MOLES(cached_gases,our_moles)
		var/their_moles
		TOTAL_MOLES(sharer_gases,their_moles)
		return (temperature_archived*(our_moles + moved_moles) - sharer.temperature_archived*(their_moles - moved_moles)) * R_IDEAL_GAS_EQUATION / gas_volume

///joules per kelvin
/datum/chemical_mix/proc/heat_capacity(phases = CHEMICAL_GASES|CHEMICAL_LIQUIDS|CHEMICAL_SOLIDS, data = MOLES)
	. = 0
	if(phases & CHEMICAL_GASES)
		var/list/cached_gases = gases
		for(var/datum/chemical/id as anything in cached_gases)
			var/gas_data = cached_gases[id]
			. += gas_data[data] * initial(id.molar_heat_capacity)
	if(phases & CHEMICAL_LIQUIDS)
		var/list/cached_liquids = liquids
		for(var/datum/chemical/id as anything in cached_liquids)
			var/liquid_data = cached_liquids[id]
			. += liquid_data[data] * initial(id.molar_heat_capacity)//cached_liquids[GAS_META][META_GAS_SPECIFIC_HEAT]

	if(phases & CHEMICAL_SOLIDS)
		var/list/cached_solids = solids
		for(var/datum/chemical/id as anything in cached_solids)
			var/solid_data = cached_solids[id]
			. += solid_data[data] * initial(id.molar_heat_capacity)

/datum/chemical_mix/proc/flow(datum/chemical_mix/sharer, our_coeff, their_coeff, list/us_all_deltas, turf/open/our_turf, turf/open/their_turf)
	var/our_volume = liquid_volume_archived
	var/their_volume = sharer.liquid_volume_archived

	var/list/our_liquids = liquids
	var/list/their_liquids = sharer.liquids

	var/list/only_in_us = our_liquids - their_liquids
	var/list/only_in_them = their_liquids - our_liquids

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
		our_liquids[new_to_us] = list(0,0, null)
		//our_liquids[new_to_us][CHEMICAL_CURRENT] = 0
	for(var/new_to_them in only_in_us)
		their_liquids[new_to_them] = list(0,0, null)
		//their_liquids[new_to_them][CHEMICAL_CURRENT] = 0

	for(var/datum/chemical/liquid_path as anything in our_liquids)
		var/our_moles = our_liquids[liquid_path][CHEMICAL_CURRENT]
		var/their_moles = their_liquids[liquid_path][CHEMICAL_CURRENT]

		var/molar_difference = (our_moles - their_moles)

		var/spreading_parameter = -1// <0 means partial wetting, > 0 means full wetting (infinitely spreading)

		var/viscosity = initial(liquid_path.viscosity)
		if(initial(liquid_path.surface_tension) == 0)
			spreading_parameter = 1//no internal forces to try to minimize surface area

		var/delta = QUANTIZE(molar_difference * 1 / clamp(sqrt(viscosity), 1, 100))

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

		var/old_us = our_liquids[liquid_path][CHEMICAL_NEXT]
		var/old_them = their_liquids[liquid_path][CHEMICAL_NEXT]

		our_liquids[liquid_path][CHEMICAL_NEXT] -= delta
		their_liquids[liquid_path][CHEMICAL_NEXT] += delta

		var/volume_delta = delta * (initial(liquid_path.molar_mass) / initial(liquid_path.liquid_density))
		total_volume_delta += volume_delta

		liquid_volume -= volume_delta
		sharer.liquid_volume += volume_delta

		if(our_liquids[liquid_path][CHEMICAL_NEXT] < 0)
			removed_from_us += liquid_path
		if(their_liquids[liquid_path][CHEMICAL_NEXT] < 0)
			removed_from_them += liquid_path

		moved_moles += delta
		abs_moved_moles += abs(delta)

	var/our_old_gas_volume = gas_volume
	var/their_old_gas_volume = sharer.gas_volume

	gas_volume = max(our_old_gas_volume + total_volume_delta * 1000, MINIMUM_AIR_VOLUME)
	sharer.gas_volume = max(their_old_gas_volume - total_volume_delta * 1000, MINIMUM_AIR_VOLUME)

	if(abs(our_old_gas_volume - gas_volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !(our_turf.active_phases & GAS_ACTIVE))//&& !us.excited)
		SSchemicals.add_gas_turf(src)
	if(abs(their_old_gas_volume - sharer.gas_volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !(their_turf.active_phases & GAS_ACTIVE))
		SSchemicals.add_gas_turf(their_turf)

	var/our_new_heat_capacity = our_old_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
	var/sharer_new_heat_capacity = sharer_old_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self
	if(our_new_heat_capacity)
		temperature = (our_old_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / our_new_heat_capacity
	if(sharer_new_heat_capacity)
		sharer.temperature = (sharer_old_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / sharer_new_heat_capacity
		/*
		if(abs(sharer_old_heat_capacity) > MINIMUM_HEAT_CAPACITY)
			if(abs(sharer_new_heat_capacity/sharer_old_heat_capacity - 1) < 0.1) // <10% change in sharer heat capacity
				temperature_share(sharer, LIQUID_HEAT_TRANSFER_COEFFICIENT)
		*/

	if(length(only_in_them) || length(only_in_us))
		garbage_collect(our_liquids)
		sharer.garbage_collect(their_liquids)

	//list(mole net flow (to us - from us), our new chemicals, our removed chemicals, their new chemicals, their removed chemicals)
	return list(moved_moles, only_in_them, removed_from_us, only_in_us, removed_from_them)

///tries to move as many of our liquid moles into the target mix as possible, stopping if their volume exceeds CELL_VOLUME
/datum/chemical_mix/proc/uni_flow(datum/chemical_mix/sharer, share_coeff, turf/open/us, turf/open/them)//TODOKYLER: make this diffuse if sharer cant be given all of our contents
	var/our_volume = liquid_volume_archived
	if(!our_volume)
		return
	var/their_volume = sharer.liquid_volume_archived

	var/their_volume_to_fill = CELL_VOLUME - their_volume
	if(their_volume_to_fill <= 0)
		return

	///how much volume can be moved from us to them / how much volume we have. scales the number of moles we move into them from each liquid in us
	var/volume_ratio = min(their_volume_to_fill, our_volume) / our_volume

	var/list/our_liquids = liquids
	var/list/their_liquids = sharer.liquids

	var/list/only_in_us = our_liquids - their_liquids

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
		their_liquids[new_to_them] = list(0,0, null)

	for(var/datum/chemical/liquid_path as anything in our_liquids)
		our_liquids[liquid_path][CHEMICAL_CURRENT] = LIQUID_QUANTIZE(our_liquids[liquid_path][CHEMICAL_CURRENT])

		var/our_moles = our_liquids[liquid_path][CHEMICAL_CURRENT]
		var/their_moles = their_liquids[liquid_path][CHEMICAL_CURRENT]

		var/liquid_capacity = initial(liquid_path.molar_heat_capacity)

		our_old_heat_capacity += our_moles * liquid_capacity
		sharer_old_heat_capacity += their_moles * liquid_capacity

		var/delta = LIQUID_QUANTIZE(our_moles * volume_ratio * share_coeff)//this effectively squares the quantization threshold in some cases when moving liquids down
		if(!delta)
			continue

		var/old_us = our_liquids[liquid_path][CHEMICAL_NEXT]
		var/old_them = their_liquids[liquid_path][CHEMICAL_NEXT]

		our_liquids[liquid_path][CHEMICAL_NEXT] -= delta
		their_liquids[liquid_path][CHEMICAL_NEXT] += delta

		heat_capacity_self_to_sharer += delta * liquid_capacity

		var/volume_delta = delta * (initial(liquid_path.molar_mass) / initial(liquid_path.liquid_density))//initial(liquid_path.molar_volume)
		total_volume_delta += volume_delta

		liquid_volume -= volume_delta
		sharer.liquid_volume += volume_delta

		moved_moles += delta
		abs_moved_moles += abs(delta)

	var/our_old_gas_volume = gas_volume
	var/their_old_gas_volume = sharer.gas_volume

	gas_volume = max(our_old_gas_volume + total_volume_delta * 1000, MINIMUM_AIR_VOLUME)
	sharer.gas_volume = max(their_old_gas_volume - total_volume_delta * 1000, MINIMUM_AIR_VOLUME)

	if(abs(our_old_gas_volume - gas_volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !(us.active_phases & GAS_ACTIVE))//&& !us.excited)
		SSchemicals.add_gas_turf(us)
	if(abs(their_old_gas_volume - sharer.gas_volume) > MINIMUM_VOLUME_DELTA_TO_ACTIVATE && !(them.active_phases & GAS_ACTIVE))
		SSchemicals.add_gas_turf(them)

	var/our_new_heat_capacity = our_old_heat_capacity - heat_capacity_self_to_sharer// + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
	var/sharer_new_heat_capacity = sharer_old_heat_capacity + heat_capacity_self_to_sharer// - heat_capacity_sharer_to_self //dont need this since its 0
	if(our_new_heat_capacity)
		temperature = (our_old_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / our_new_heat_capacity
	if(sharer_new_heat_capacity)
		sharer.temperature = (sharer_old_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / sharer_new_heat_capacity

	garbage_collect(our_liquids)

	//list(mole net flow (to us - from us), our old chemicals, our new chemicals, their old chemicals, their new chemicals)
	//return list(moved_moles, original_us, only_in_them, original_them, only_in_us, total_volume_delta)

/datum/chemical_mix/proc/archive()
	temperature_archived = temperature
	for(var/datum/chemical/chem as anything in gases)
		var/list/chemlist = gases[chem]
		chemlist[CHEMICAL_CURRENT] = chemlist[CHEMICAL_NEXT]
	for(var/datum/chemical/chem as anything in liquids)
		var/list/chemlist = liquids[chem]
		chemlist[CHEMICAL_CURRENT] = chemlist[CHEMICAL_NEXT]
	for(var/datum/chemical/chem as anything in solids)
		var/list/chemlist = solids[chem]
		chemlist[CHEMICAL_CURRENT] = chemlist[CHEMICAL_NEXT]
	//gases[CHEMICAL_CURRENT] = gases[CHEMICAL_NEXT].Copy()
	//liquids[CHEMICAL_CURRENT] = liquids[CHEMICAL_NEXT].Copy()
	//solids[CHEMICAL_CURRENT] = solids[CHEMICAL_NEXT].Copy()

	return TRUE

///Performs temperature sharing calculations (via conduction) between two chemical_mixtures assuming only 1 boundary length
///Returns: new temperature of the sharer
/datum/chemical_mix/proc/temperature_share(datum/chemical_mix/sharer, conduction_coefficient/*, sharer_temperature, sharer_heat_capacity*/)
	//transfer of thermal energy (via conduction) between self and sharer

	var/sharer_temperature = sharer.temperature_archived

	var/gas_coeff = OPEN_HEAT_TRANSFER_COEFFICIENT
	var/liquid_coeff = LIQUID_HEAT_TRANSFER_COEFFICIENT
	var/solid_coeff = OPEN_HEAT_TRANSFER_COEFFICIENT
	var/final_coeff = 0 //sum of each phase coeff * the molar fraction of that phase over all others

	var/our_gas_moles = 0
	var/our_liquid_moles = 0
	var/our_solid_moles = 0
	var/our_total_moles = 0

	var/sharer_gas_moles = 0
	var/sharer_liquid_moles = 0
	var/sharer_solid_moles = 0
	var/sharer_total_moles = 0

	var/list/our_gases = gases
	var/list/our_liquids = liquids
	var/list/our_solids = solids

	var/list/their_gases = sharer.gases
	var/list/their_liquids = sharer.liquids
	var/list/their_solids = sharer.solids

	var/temperature_delta = temperature_archived - sharer_temperature
	if(abs(temperature_delta) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = 0
		var/sharer_heat_capacity = 0

		for(var/datum/chemical/gas_path as anything in our_gases)
			var/moles = our_gases[gas_path][CHEMICAL_CURRENT]
			self_heat_capacity += moles * initial(gas_path.molar_heat_capacity)
			our_gas_moles += moles
		for(var/datum/chemical/liquid_path as anything in our_liquids)
			var/moles = our_liquids[liquid_path][CHEMICAL_CURRENT]
			self_heat_capacity += moles * initial(liquid_path.molar_heat_capacity)
			our_liquid_moles += moles
		for(var/datum/chemical/solid_path as anything in our_solids)
			var/moles = our_solids[solid_path][CHEMICAL_CURRENT]
			self_heat_capacity += moles * initial(solid_path.molar_heat_capacity)
			our_solid_moles += moles

		for(var/datum/chemical/gas_path as anything in their_gases)
			var/moles = their_gases[gas_path][CHEMICAL_CURRENT]
			sharer_heat_capacity += moles * initial(gas_path.molar_heat_capacity)
			sharer_gas_moles += moles
		for(var/datum/chemical/liquid_path as anything in their_liquids)
			var/moles = their_liquids[liquid_path][CHEMICAL_CURRENT]
			sharer_heat_capacity += moles * initial(liquid_path.molar_heat_capacity)
			sharer_liquid_moles += moles
		for(var/datum/chemical/solid_path as anything in their_solids)
			var/moles = their_solids[solid_path][CHEMICAL_CURRENT]
			sharer_heat_capacity += moles * initial(solid_path.molar_heat_capacity)
			sharer_solid_moles += moles

		our_total_moles = our_gas_moles + our_liquid_moles + our_solid_moles
		sharer_total_moles = sharer_gas_moles + sharer_liquid_moles + sharer_solid_moles

		var/combined_moles = (our_total_moles + sharer_total_moles) / 2

		final_coeff = (gas_coeff * ((our_gas_moles + sharer_gas_moles) / 2) + liquid_coeff * ((our_liquid_moles + sharer_liquid_moles) / 2) + solid_coeff * ((our_solid_moles + sharer_solid_moles)/2)) / combined_moles

		/*
		sharer_heat_capacity = sharer_heat_capacity
		if(sharer_heat_capacity <= 0)
			sharer_heat_capacity = 0
			for(var/datum/liquid/liquid_path as anything in sharer.liquids[LIQUID_CURRENT])
				var/moles = sharer.liquids[LIQUID_CURRENT][liquid_path]
				sharer_heat_capacity += moles * initial(liquid_path.molar_heat_capacity)
		*/

		if((sharer_heat_capacity > MINIMUM_HEAT_CAPACITY) && (self_heat_capacity > MINIMUM_HEAT_CAPACITY))
			// coefficient applied first because some turfs have very big heat caps.
			var/heat = CALCULATE_CONDUCTION_ENERGY(final_coeff * temperature_delta, sharer_heat_capacity, self_heat_capacity)

			temperature = max(temperature - heat/self_heat_capacity, TCMB)
			sharer_temperature = max(sharer_temperature + heat/sharer_heat_capacity, TCMB)
			if(sharer)
				sharer.temperature = sharer_temperature
	return sharer_temperature

///this is hard to do efficiently, do it the dumb way first
GLOBAL_LIST_INIT(chemical_reactions, init_chemical_reactions())

/proc/init_chemical_reactions()
	. = list()
	for(var/datum/reaction/reaction_path as anything in subtypesof(/datum/reaction))
		. += new reaction_path

/datum/chemical_mix/proc/react(atom/holder)
	if(!istype(holder))
		return

	var/temperature = src.temperature
	var/pressure = 0//TODOKYLER: figure this out

	//turf/holder, datum/liquid_mix/liquids, temperature, pressure, list/solid_interfaces, datum/gas_mixture/gas_interface
	for(var/datum/reaction/reaction as anything in GLOB.chemical_reactions)
		reaction.react(src, holder, temperature, pressure)

/datum/reaction
	var/name = "AAA"

	var/priority = 1

	var/list/atom/containers = list()
	var/active = FALSE

	/**
	 * list of sublists containing specified typepaths, each denoting a required chemcical to be present in order to
	 *
	 */
	var/list/requires = list()

	var/min_temperature = 0
	var/max_temperature = 0

	var/min_pressure = 0
	var/max_pressure = 0

/datum/reaction/proc/react(datum/chemical_mix/mix, atom/holder, temperature, pressure)
	return

//yeah i should really make phase changes distinct from reactions
/datum/chemical_mix/proc/handle_phase_changes(turf/holder)
	. = NO_REACTION

	var/temperature = src.temperature

	var/list/gases = src.gases
	var/list/liquids = src.liquids
	var/list/solids = src.solids

	for(var/datum/chemical/chem as anything in gases|liquids|solids)

		var/liquid_moles = liquids[chem]?[CHEMICAL_NEXT]||0
		var/gas_moles = gases[chem]?[CHEMICAL_NEXT]||0
		var/solid_moles = solids[chem]?[CHEMICAL_NEXT]||0

		if(!liquid_moles && !gas_moles && !solid_moles)
			continue

		. = REACTING

		var/consumed_liquid = 0
		var/consumed_gas = 0
		var/consumed_solid = 0

		var/added_gas = 0
		var/added_liquid = 0
		var/added_solid = 0

		var/liquid_max_temp = initial(chem.liquid_max_temp)
		var/solid_max_temp = initial(chem.solid_max_temp)

		var/delta_liquid_volume = 0
		var/delta_solid_volume = 0

		var/liquid_molar_volume =  initial(chem.molar_mass) / initial(chem.liquid_density)
		var/solid_molar_volume = initial(chem.molar_mass) / initial(chem.solid_density)

		if(liquid_moles > 0)
			if(liquid_max_temp != NONE && temperature > liquid_max_temp)
				var/delta_k = liquid_max_temp - temperature
				var/change = max(min(liquid_moles, 25), clamp(liquid_moles * (0.01 * (1 + delta_k/liquid_max_temp)), 0.01, 0.9))

				delta_liquid_volume -= change * (initial(chem.molar_mass) / initial(chem.liquid_density))
				consumed_liquid += change
				added_gas += change

			else if(temperature < solid_max_temp)
				var/delta_k = solid_max_temp - temperature
				var/change = max(min(liquid_moles, 25), clamp(liquid_moles * (0.01 * (1 + delta_k/solid_max_temp)), 0.01, 0.9))

				delta_liquid_volume -= change * liquid_molar_volume
				delta_solid_volume += change * solid_molar_volume
				consumed_liquid += change
				added_solid += change

		if(gas_moles > 0)
			if(temperature < solid_max_temp)//direct gas->solid
				var/delta_k = solid_max_temp - temperature
				var/change = max(min(gas_moles, 25), clamp(gas_moles * (0.01 * (1 + delta_k/solid_max_temp)), 0.01, 0.9))

				consumed_gas += change
				added_solid += change
				delta_solid_volume += change * solid_molar_volume

			else if(temperature < liquid_max_temp) //condensation
				var/delta_k = liquid_max_temp - temperature
				var/change = max(min(gas_moles, 25), clamp(gas_moles * (0.01 * (1 + delta_k/liquid_max_temp)), 0.01, 0.9))

				consumed_gas += change

				added_liquid += change
				delta_liquid_volume += change * liquid_molar_volume



		if(solid_moles > 0)

			if(temperature > solid_max_temp)
				if(temperature > liquid_max_temp)
					var/delta_k = liquid_max_temp - temperature
					var/change = max(min(solid_moles, 25), clamp(solid_moles * (0.01 * (1 + delta_k/liquid_max_temp)), 0.01, 0.9))

					delta_solid_volume -= change * solid_molar_volume
					consumed_solid += change

					added_gas += change
					//delta_liquid_volume += change * liquid_molar_volume

				else if(liquid_max_temp != NONE)
					var/delta_k = solid_max_temp - temperature
					var/change = max(min(solid_moles, 25), clamp(solid_moles * (0.01 * (1 + delta_k/solid_max_temp)), 0.01, 0.9))

					delta_solid_volume -= change * solid_molar_volume
					consumed_solid += change
					//if(temperature < liquid_max_temp || liquid_max_temp == NONE)
					added_liquid += change
					delta_liquid_volume += change * liquid_molar_volume

		liquid_volume += delta_liquid_volume
		solid_volume += delta_solid_volume
		//no gas volume? also is this unsafe considering bounded change happens right below this

		var/new_gas = max(gas_moles + (added_gas - consumed_gas), 0)
		var/new_liquid = max(liquid_moles + (added_liquid - consumed_liquid), 0)
		var/new_solid = max(solid_moles + (added_solid - consumed_solid), 0)

		if(gas_moles == 0)
			gases[chem] = list(new_gas, new_gas, SSchemicals.chemical_metas["GAS[chem]"])
		else
			gases[chem][CHEMICAL_NEXT] = new_gas

		if(liquid_moles == 0)
			liquids[chem] = list(new_liquid, new_liquid, SSchemicals.chemical_metas["LIQUID[chem]"])
		else
			liquids[chem][CHEMICAL_NEXT] = new_liquid

		if(solid_moles == 0)
			solids[chem] = list(new_solid, new_solid, SSchemicals.chemical_metas["SOLID[chem]"])
		else
			solids[chem][CHEMICAL_NEXT] = new_solid

		if(new_gas && !(holder.active_phases & CHEMICAL_GASES))
			SSchemicals.add_gas_turf(holder)

		if(new_liquid && !(holder.active_phases & CHEMICAL_LIQUIDS))
			SSchemicals.add_liquid_turf(holder)

		if(new_solid && !(holder.active_phases & CHEMICAL_SOLIDS))
			SSchemicals.add_solid_turf(holder)


/datum/reaction/proc/add_reacting_container(turf/new_container)
	if((src in new_container.reacting) || (new_container in containers))
		return

	LAZYADD(new_container.reacting, src)
	containers |= new_container
	if(!active)
		active = TRUE
		SSreactions.active_processing_reactions[priority] += src

/datum/reaction/proc/remove_reacting_container(turf/old_container)
	LAZYREMOVE(old_container.reacting, src)
	containers -= old_container

	if(active && !length(containers))
		active = FALSE
		SSreactions.active_processing_reactions -= src
		SSreactions.currentrun -= src

/datum/reaction/proc/process_reactions(fire_count)
	var/list/containers = src.containers
	return

///this is hard to do efficiently, do it the dumb way first
//GLOBAL_LIST_INIT(liquid_reactions, init_liquid_reactions())

SUBSYSTEM_DEF(reactions)
	name = "Reactions"
	can_fire = FALSE//TRUE TODO: implement SSreactions
	init_order = INIT_ORDER_CHEMICALS
	priority = FIRE_PRIORITY_FLUIDS
	wait = 0.5 SECONDS
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/reactions = list()

	var/list/active_processing_reactions = list()
	var/list/currentrun

/datum/controller/subsystem/reactions/Initialize()
	//reactions = init_global_reactions()
	return

/datum/controller/subsystem/reactions/fire(resumed)
	var/fire_count = times_fired
	if (!resumed)
		src.currentrun = active_processing_reactions.Copy()
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/datum/reaction/R = currentrun[currentrun.len]
		currentrun.len--
		if (R)
			R.react(fire_count)
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/reactions/proc/add_processing_reaction(datum/reaction/new_reaction)
	active_processing_reactions += new_reaction

/datum/controller/subsystem/reactions/proc/remove_processing_reaction(datum/reaction/old_reaction)
	active_processing_reactions -= old_reaction
	currentrun -= old_reaction

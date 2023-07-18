///liquids list index containing the list of the moles of every liquid that existed the last SSliquids fire
#define LIQUID_CURRENT 1
///liquids list index containing the list of the moles of every liquid that's being processed in the current SSliquids fire, and will become LIQUID_CURRENT at the end
#define LIQUID_NEXT 2

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

/turf/proc/assert_water(amount = 1000)
	if(amount < 0)
		return
	var/list/cached_liquid_list = liquids.liquids

	var/total_moles = 0
	TOTAL_LIQUID_MOLES(cached_liquid_list[LIQUID_NEXT], total_moles)

	if(total_moles > 0)

		if(amount > 0)
			cached_liquid_list[LIQUID_NEXT][/datum/liquid/water] = amount
		else
			cached_liquid_list[LIQUID_NEXT] -= /datum/liquid/water
			TOTAL_LIQUID_MOLES(cached_liquid_list[LIQUID_NEXT], total_moles)
			if(total_moles == 0)
				SSliquids.remove_active_turf(src)

	else if(amount > 0)
		liquids.liquids[LIQUID_CURRENT][/datum/liquid/water] = amount
		liquids.liquids[LIQUID_NEXT][/datum/liquid/water] = amount
		liquids.temperature = temperature
		liquids.temperature_archived = temperature_archived
		SSliquids.add_active_turf(src)

/turf/proc/process_liquids(fire_count)
	SSliquids.remove_active_turf(src)

/turf/open/process_liquids(fire_count)
	if(liquid_archived_cycle < fire_count)
		LIQUID_CYCLE_ARCHIVE(src)

	liquid_current_cycle = fire_count

	var/list/adjacent_turfs = atmos_adjacent_turfs
	var/our_share_coeff = 1/(length(adjacent_turfs) + 1)

	var/datum/liquid_mix/our_liquids = liquids

	var/list/us_all_deltas = list()

	for(var/turf/open/adjacent_turf as anything in adjacent_turfs)
		if(fire_count <= adjacent_turf.liquid_current_cycle)
			continue

		if(get_dir(src, adjacent_turf) == UP && has_gravity(src))
			continue

		SSliquids.add_active_turf(adjacent_turf)

		var/datum/liquid_mix/their_liquids = adjacent_turf.liquids

		LIQUID_CYCLE_ARCHIVE(adjacent_turf)

		var/their_share_coeff = 1/(length(adjacent_turf.atmos_adjacent_turfs) + 1)

		var/difference = our_liquids.flow(their_liquids, our_share_coeff, their_share_coeff, us_all_deltas)


	our_liquids.react()

	update_liquid_visuals()


/obj/effect/overlay/liquid
	icon = 'icons/turf/beach.dmi'
	icon_state = "water"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = FLY_LAYER
	plane = GAME_PLANE
	appearance_flags = TILE_BOUND
	vis_flags = NONE
	var/plane_offset = 0

/obj/effect/overlay/liquid/New(loc, state, alph, plane_offset)
	. = ..()
	icon_state = state
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
		if(GLOB.liquids_display_moles == TRUE)
			maptext = "[total_moles]"
		if(liquid_overlay)
			return
		//liquid_image = mutable_appearance('icons/turf/beach.dmi', "water", plane = offset)
		liquid_overlay = new(null, "water", 150, GET_TURF_PLANE_OFFSET(src) + 1)
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
	var/volume = 0

	var/last_diffuse = 0

	var/list/solutes

	var/vel_x = 0
	var/vel_y = 0
	var/vel_z = 0

/datum/liquid_phases //probably wont do this, for now definitely assume all liquids are perfectly soluable to all other liquids

/datum/liquid_mix/proc/archive()
	//var/list/cached_liquids = liquids
	liquids[LIQUID_CURRENT] = liquids[LIQUID_NEXT].Copy()

/datum/liquid_mix/proc/flow(datum/liquid_mix/sharer, our_coeff, their_coeff, list/us_all_deltas)
	var/our_volume = volume
	var/their_volume = sharer.volume

	var/our_liquids = liquids
	var/their_liquids = sharer.liquids

	var/list/only_in_us = our_liquids[LIQUID_CURRENT] - their_liquids[LIQUID_CURRENT]
	var/list/only_in_them = their_liquids[LIQUID_CURRENT] - our_liquids[LIQUID_CURRENT]

	var/temperature_delta = temperature_archived - sharer.temperature_archived
	var/abs_temperature_delta = abs(temperature_delta)

	var/moved_moles = 0
	var/abs_moved_moles = 0

	for(var/new_to_us in only_in_them)
		our_liquids[LIQUID_NEXT][new_to_us] = 0
		our_liquids[LIQUID_CURRENT][new_to_us] = 0
	for(var/new_to_them in only_in_us)
		their_liquids[LIQUID_NEXT][new_to_them] = 0
		their_liquids[LIQUID_CURRENT][new_to_them] = 0

	for(var/liquid_path in our_liquids[LIQUID_CURRENT])
		var/our_moles = our_liquids[LIQUID_CURRENT][liquid_path]
		var/their_moles = their_liquids[LIQUID_CURRENT][liquid_path]

		var/delta = QUANTIZE(our_moles - their_moles)
		if(!delta)
			continue

		if(delta > 0)
			delta *= our_coeff
		else
			delta *= their_coeff

		us_all_deltas += -delta

		var/old_us = our_liquids[LIQUID_NEXT][liquid_path]
		var/old_them = their_liquids[LIQUID_NEXT][liquid_path]

		our_liquids[LIQUID_NEXT][liquid_path] -= delta
		their_liquids[LIQUID_NEXT][liquid_path] += delta

		if(our_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1
		if(their_liquids[LIQUID_NEXT][liquid_path] < 0)
			var/i = 1

		moved_moles += delta
		abs_moved_moles += abs(delta)

	if(length(only_in_them) || length(only_in_us))
		garbage_collect()
		sharer.garbage_collect()

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
	var/icon_state

	/// g / mole
	var/molar_mass = 0
	/// g / m^3
	var/density = 0

	var/viscosity = 0
	///J/(mol * kelvin)
	var/specific_heat_capacity = 0



/datum/liquid/water
	name = "water"
	icon_state = "water"
	// g / mole
	molar_mass = 18.01528
	// g / m^3
	density = 997000
	//mega pascal seconds
	viscosity = 1.0016
	// J / (mole * kelvin)
	specific_heat_capacity = 75.385

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

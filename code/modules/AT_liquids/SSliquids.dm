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

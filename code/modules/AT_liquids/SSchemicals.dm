#define SSCHEMICALS_GASES 1
#define SSCHEMICALS_LIQUIDS 2
//#define SSCHEMICALS_SOLIDS 3
#define SSCHEMICALS_REACTIONS 4

SUBSYSTEM_DEF(chemicals)
	name = "Chemicals"
	can_fire = TRUE
	init_order = INIT_ORDER_CHEMICALS
	priority = FIRE_PRIORITY_FLUIDS
	wait = 0.5 SECONDS
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/chemical_metas = list()

	var/list/reactions_by_pressure_by_temperature = list()
	var/allow_reactions = TRUE

	var/list/on_enter_effects = list()
	var/list/on_exit_effects = list()

	var/current_stage = SSCHEMICALS_GASES

	var/list/active_turfs = list()

	var/list/active_gas_turfs = list()
	var/list/active_liquid_turfs = list()
	var/list/active_solid_turfs = list()

	var/list/reactions = list()

	var/list/currentrun

/datum/controller/subsystem/chemicals/Initialize()

	return

/datum/controller/subsystem/chemicals/fire(resumed)
	var/fire_count = times_fired
	if (!resumed)
		src.currentrun = active_gas_turfs|active_liquid_turfs|active_solid_turfs//active_turfs.Copy()
		current_stage = SSCHEMICALS_GASES
	var/list/currentrun = src.currentrun

	if(current_stage == SSCHEMICALS_GASES)
		while(currentrun.len)
			var/turf/open/T = currentrun[currentrun.len]
			currentrun.len--
			if (T)
				T.process_chemicals(fire_count)
			if (MC_TICK_CHECK)
				return
			//current_stage = SSCHEMICALS_LIQUIDS
			//src.currentrun = active_liquid_turfs.Copy()
			//break
	/*
	if(current_stage == SSCHEMICALS_LIQUIDS)
		while(currentrun.len)
			var/turf/open/T = currentrun[currentrun.len]
			currentrun.len--
			if (T)
				T.process_liquids(fire_count)
			if (MC_TICK_CHECK)
				return
			current_stage = SSCHEMICALS_LIQUIDS
			src.currentrun = active_liquid_turfs.Copy()
			break
	*/

/datum/controller/subsystem/chemicals/proc/add_gas_turf(turf/open/new_turf)
	//if(!istype(new_turf))
	//	stack_trace("wrong turf type! [new_turf]")
	active_gas_turfs |= new_turf
	new_turf.active_phases |= GAS_ACTIVE

/datum/controller/subsystem/chemicals/proc/remove_gas_turf(turf/old_turf)
	old_turf.active_phases ^= GAS_ACTIVE
	active_gas_turfs -= old_turf

/datum/controller/subsystem/chemicals/proc/add_liquid_turf(turf/open/new_turf)
	//if(!istype(new_turf))
	//	stack_trace("wrong turf type! [new_turf]")
	active_liquid_turfs |= new_turf
	new_turf.active_phases |= LIQUID_ACTIVE

/datum/controller/subsystem/chemicals/proc/remove_liquid_turf(turf/old_turf)
	old_turf.active_phases ^= LIQUID_ACTIVE
	active_liquid_turfs -= old_turf

/datum/controller/subsystem/chemicals/proc/add_solid_turf(turf/open/new_turf)
	//if(!istype(new_turf))
	//	stack_trace("wrong turf type! [new_turf]")
	active_solid_turfs |= new_turf
	new_turf.active_phases |= SOLID_ACTIVE

/datum/controller/subsystem/chemicals/proc/remove_solid_turf(turf/old_turf)
	old_turf.active_phases ^= SOLID_ACTIVE
	active_solid_turfs -= old_turf

//TODO: possibly split all processes between their own subsystems.
//but to do that i need to figure out how to make reactions process exactly once in a turf independently of ---
//what if each turf has its reactions handled by the first subsystem that its activated in?
//for example if i add_gas_turf(x) then add_liquid_turf(x) then x will be in SSair's reaction list but not SSliquids
//reactions cant be done for every subsystem's active turfs because a reaction can take place with chemicals between phases

//what if i do SSreactions? diffusion adds /reaction datums to turfs based on added/removed reagents which then process
//by themselves

/*
/proc/add_gas_turf(turf/open/new_turf)
	//if(!istype(new_turf))
	//	stack_trace("wrong turf type! [new_turf]")
	SSnewair.active_gas_turfs |= new_turf
	new_turf.active_phases |= GAS_ACTIVE

/proc/remove_gas_turf(turf/old_turf)
	SSnewair.active_gas_turfs -= old_turf
	old_turf.active_phases ^= GAS_ACTIVE

/proc/add_liquid_turf(turf/open/new_turf)
	//if(!istype(new_turf))
	//	stack_trace("wrong turf type! [new_turf]")
	active_liquid_turfs |= new_turf
	new_turf.active_phases |= LIQUID_ACTIVE

/proc/remove_liquid_turf(turf/old_turf)
	old_turf.active_phases ^= LIQUID_ACTIVE
	active_liquid_turfs -= old_turf

/proc/add_solid_turf(turf/open/new_turf)
	//if(!istype(new_turf))
	//	stack_trace("wrong turf type! [new_turf]")
	active_solid_turfs |= new_turf
	new_turf.active_phases |= SOLID_ACTIVE

/proc/remove_solid_turf(turf/old_turf)
	old_turf.active_phases ^= SOLID_ACTIVE
	active_solid_turfs -= old_turf

SUBSYSTEM_DEF(gases)
	name = "Gases"

SUBSYSTEM_DEF(liquids)
	name = "Liquids"

SUBSYSTEM_DEF(solids)
	name = "Solids"

*/

/**
 * StonedMC
 *
 * Designed to properly split up a given tick among subsystems
 * Note: if you read parts of this code and think "why is it doing it that way"
 * Odds are, there is a reason
 *
 **/

// See initialization order in /code/game/world.dm
GLOBAL_REAL(Master, /datum/controller/master)
/datum/controller/master
	name = "Master"

	/// Are we processing (higher values increase the processing delay by n ticks)
	var/processing = TRUE
	/// How many times have we ran
	var/iteration = 0
	/// Stack end detector to detect stack overflows that kill the mc's main loop
	var/datum/stack_end_detector/stack_end_detector

	/// world.time of last fire, for tracking lag outside of the mc
	var/last_run
	/// world.time of the fire before last_run
	var/run_before_last

	/// List of subsystems to process().
	var/list/subsystems

	///Most recent init stage to complete init.
	var/static/init_stage_completed

	// Vars for keeping track of tick drift.
	var/init_timeofday
	var/init_time
	var/tickdrift = 0
	/// Tickdrift as of last tick, w no averaging going on
	var/olddrift = 0

	/// How long is the MC sleeping between runs, read only (set by Loop() based off of anti-tick-contention heuristics)
	var/sleep_delta = 1

	/// Only run ticker subsystems for the next n ticks.
	var/skip_ticks = 0

	/// makes the mc main loop runtime
	var/make_runtime = FALSE

	var/initializations_finished_with_no_players_logged_in //I wonder what this could be?

	/// The type of the last subsystem to be fire()'d.
	var/last_type_processed

	var/datum/controller/subsystem/queue_head //!Start of queue linked list
	var/datum/controller/subsystem/queue_tail //!End of queue linked list (used for appending to the list)
	var/queue_priority_count = 0 //Running total so that we don't have to loop thru the queue each run to split up the tick
	var/queue_priority_count_bg = 0 //Same, but for background subsystems
	var/map_loading = FALSE //!Are we loading in a new map?

	var/current_runlevel //!for scheduling different subsystems for different stages of the round
	var/sleep_offline_after_initializations = TRUE

	/// During initialization, will be the instanced subsytem that is currently initializing.
	/// Outside of initialization, returns null.
	var/current_initializing_subsystem = null

	/// The last decisecond we force dumped profiling information
	/// Used to avoid spamming profile reads since they can be expensive (string memes)
	var/last_profiled = 0

	var/static/restart_clear = 0
	var/static/restart_timeout = 0
	var/static/restart_count = 0

	var/static/random_seed

	///current tick limit, assigned before running a subsystem.
	///used by CHECK_TICK as well so that the procs subsystems call can obey that SS's tick limits
	var/static/current_ticklimit = TICK_LIMIT_RUNNING

	/// Whether the Overview UI will update as fast as possible for viewers.
	var/overview_fast_update = FALSE

	var/average_ticks_skipped = 0

	///running average of how much each tick is already used when the MC is resumed to run by byond.
	///this exists because sleeping procs are scheduled to resume by byond which we cant control, so procs that sleep can resume before the MC
	var/average_starting_tick_usage = 0

	///number of stoplag() processes are sleeping, used for stat tracking
	var/stoplag_threads = 0

	var/active_sleeps = 0

	var/average_sleeps_per_tick = 0

	///running average of tick usage Master last used when it ended
	var/average_MC_tick_usage = 0

	///running average of how much time was spent resuming other sleeping procs after the mc went back to sleep.
	///this exists because sleeping procs are scheduled to resume by byond which we cant control, so procs that sleep can resume after the MC
	var/average_sleeping_tick_usage = 0

	///running average of how much overtime (in percents of a tick) was spent was spent resuming other sleeping procs after the mc went back to sleep.
	///this exists because sleeping procs are scheduled to resume by byond which we cant control, so procs that sleep can resume after the MC
	var/average_sleeping_overtime_usage = 0

	///verbs and procs called from client commands usually execute after SendMaps has executed which means they can delay the end of the tick.
	///the last of these important verbs/procs to execute sets this var to the current tick_usage when it stops, thus telling master how much that delayed the tick.
	var/last_post_maptick_tick_usage = 0

	///running average of how much of the tick post maptick client procs and verbs cost
	var/average_post_maptick_tick_usage = 0

	/// Tick usage when the mc last went to sleep
	var/last_ending_tick_usage = 0

	///
	var/tick_limit = TICK_LIMIT_MC_INITIAL

	var/min_reserve = MAPTICK_MC_MIN_RESERVE_INITIAL

	/// the procs that resumed each tick for the last 30 ticks. the oldest tick is kicked out and the newest inserted in every tick.
	/// TODOKYLER: figure out time limit and data to hold
	var/list/resuming_procs = list()

	var/list/last_resumer = null

	var/list/metadata_last_tick

	var/list/metadata_this_tick = list()

/world/Tick()
	var/ending_tick_usage = TICK_USAGE
	var/list/last_resumer = Master.last_resumer
	if(last_resumer)
		last_resumer[SLEEPING_PROC_WAKE_DURATION] = ending_tick_usage - last_resumer[SLEEPING_PROC_WAKEUP_TICK_USAGE]

	if(length(Master.resuming_procs) > MC_SLEEPING_PROCS_TICKS_TO_KEEP)
		Master.resuming_procs.Cut(1, 1 + length(Master.resuming_procs) - MC_SLEEPING_PROCS_TICKS_TO_KEEP)

	var/post_mc_usage = ending_tick_usage - Master.last_ending_tick_usage
	Master.average_sleeping_tick_usage = MC_AVERAGE_FAST(Master.average_sleeping_tick_usage, post_mc_usage)
	Master.average_sleeping_overtime_usage = MC_AVERAGE_FAST(Master.average_sleeping_overtime_usage, max(0, ending_tick_usage - 100))

	Master.last_resumer = null

	var/list/current_tick_metadata = Master.metadata_this_tick
	if(current_tick_metadata)
		current_tick_metadata[MC_METADATA_POST_MC_USAGE] = post_mc_usage

	//we dont have access to end of tick info - this is the last guaranteed spot to update information
	//on the previous tick. so this is why we look for Master's previous run and set maptick, and post maptick usage
	// here but for the previous tick - because only now do we have information from the previous tick
	if(Master.run_before_last != world.time - world.tick_lag)
		return //only useful if we can give a 1 tick change

	var/list/last_metadata = Master.metadata_last_tick
	if(!last_metadata)
		return
	last_metadata[MC_METADATA_POST_MAPTICK_USAGE] = Master.last_post_maptick_tick_usage
	last_metadata[MC_METADATA_MAPTICK] = world.map_cpu


/datum/controller/master/New()
	if(!config)
		config = new
	// Highlander-style: there can only be one! Kill off the old and replace it with the new.

	if(!random_seed)
		#ifdef UNIT_TESTS
		random_seed = 29051994 // How about 22475?
		#else
		random_seed = rand(1, 1e9)
		#endif
		rand_seed(random_seed)

	var/list/_subsystems = list()
	subsystems = _subsystems
	if (Master != src)
		if (istype(Master)) //If there is an existing MC take over his stuff and delete it
			Recover()
			qdel(Master)
			Master = src
		else
			//Code used for first master on game boot or if existing master got deleted
			Master = src
			var/list/subsystem_types = subtypesof(/datum/controller/subsystem)
			sortTim(subsystem_types, GLOBAL_PROC_REF(cmp_subsystem_init))

			//Find any abandoned subsystem from the previous master (if there was any)
			var/list/existing_subsystems = list()
			for(var/global_var in global.vars)
				if (istype(global.vars[global_var], /datum/controller/subsystem))
					existing_subsystems += global.vars[global_var]

			//Either init a new SS or if an existing one was found use that
			for(var/I in subsystem_types)
				var/ss_idx = existing_subsystems.Find(I)
				if (ss_idx)
					_subsystems += existing_subsystems[ss_idx]
				else
					_subsystems += new I

	if(!GLOB)
		new /datum/controller/global_vars

/datum/controller/master/Destroy()
	..()
	// Tell qdel() to Del() this object.
	return QDEL_HINT_HARDDEL_NOW

/datum/controller/master/Shutdown()
	processing = FALSE
	sortTim(subsystems, GLOBAL_PROC_REF(cmp_subsystem_init))
	reverse_range(subsystems)
	for(var/datum/controller/subsystem/ss in subsystems)
		log_world("Shutting down [ss.name] subsystem...")
		if (ss.slept_count > 0)
			log_world("Warning: Subsystem `[ss.name]` slept [ss.slept_count] times.")
		ss.Shutdown()
	log_world("Shutdown complete")

ADMIN_VERB(cmd_controller_view_ui, R_SERVER|R_DEBUG, "Controller Overview", "View the current states of the Subsystem Controllers.", ADMIN_CATEGORY_DEBUG)
	Master.ui_interact(user.mob)

/datum/controller/master/ui_status(mob/user, datum/ui_state/state)
	if(!user.client?.holder?.check_for_rights(R_SERVER|R_DEBUG))
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/controller/master/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(isnull(ui))
		ui = new /datum/tgui(user, src, "ControllerOverview")
		ui.open()

/datum/controller/master/ui_data(mob/user)
	var/list/data = list()

	var/list/subsystem_data = list()
	for(var/datum/controller/subsystem/subsystem as anything in subsystems)
		subsystem_data += list(list(
			"name" = subsystem.name,
			"ref" = REF(subsystem),
			"init_order" = subsystem.init_order,
			"last_fire" = subsystem.last_fire,
			"next_fire" = subsystem.next_fire,
			"can_fire" = subsystem.can_fire,
			"doesnt_fire" = !!(subsystem.flags & SS_NO_FIRE),
			"cost_ms" = subsystem.cost,
			"tick_usage" = subsystem.tick_usage,
			"tick_overrun" = subsystem.tick_overrun,
			"initialized" = subsystem.initialized,
			"initialization_failure_message" = subsystem.initialization_failure_message,
		))
	data["subsystems"] = subsystem_data
	data["world_time"] = world.time
	data["map_cpu"] = world.map_cpu
	data["fast_update"] = overview_fast_update

	data["active_sleeps"] = active_sleeps

	data["pre_mc_usage"] = average_starting_tick_usage
	data["mc_usage"] = average_MC_tick_usage
	data["post_mc_usage"] = average_sleeping_tick_usage
	data["post_maptick_usage"] = average_post_maptick_tick_usage
	//data["tick_layouts"] = resuming_procs //dont use an assoc list?

	///list( list("time" = world time of tick, "procs" = list(a proc that resumed that tick (list of data), another proc, ...)), other ticks... )
	var/list/unrolled_layouts = list()
	for(var/tick_world_time in resuming_procs)
		if(tick_world_time == world.time)
			continue
			//dont want to send in-progress ticks to the ui because itll
			//keep it as local state without checking for a more complete version later

		var/list/procs_in_tick = list()
		///list of procs resuming in a tick
		var/list/tick_layout = list(
			"world_time" = tick_world_time,
			"resuming_procs" = procs_in_tick
		)

		for(var/list/resuming_proc as anything in resuming_procs[tick_world_time])
			/*
			var/list/metadata = resuming_proc[SLEEPING_PROC_METADATA]
			if(!isnull(metadata))
				var/list/meta = list()
				switch(metadata[METADATA_IDENTIFIER])
					if(METADATA_IDENTIFIER_MC)
			*/ //TODOKYLER: figure out if i want to manually do this (i dont think i do)
			procs_in_tick += list(list(
				"file" = resuming_proc[SLEEPING_PROC_FILE],
				"proc" = resuming_proc[SLEEPING_PROC_PROC],
				"line" = resuming_proc[SLEEPING_PROC_LINE],
				"sleep_world_time" = resuming_proc[SLEEPING_PROC_SLEEP_WORLDTIME],
				"sleep_duration" = resuming_proc[SLEEPING_PROC_SLEEP_DURATION],
				"tick_usage_before_sleep" = resuming_proc[SLEEPING_PROC_TICK_USAGE_BEFORE_SLEEP],
				"wakeup_worldtime" = resuming_proc[SLEEPING_PROC_WAKEUP_WORLDTIME],
				"wake_duration" = resuming_proc[SLEEPING_PROC_WAKE_DURATION],
				"wakeup_tick_usage" = resuming_proc[SLEEPING_PROC_WAKEUP_TICK_USAGE],
				"metadata" = resuming_proc[SLEEPING_PROC_METADATA]
			))//the ui has to destructure metadata itself

		unrolled_layouts += list(tick_layout)
	data["ticks"] = unrolled_layouts

	return data

/datum/controller/master/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	switch(action)
		if("toggle_fast_update")
			overview_fast_update = !overview_fast_update
			return TRUE

		if("view_variables")
			var/datum/controller/subsystem/subsystem = locate(params["ref"]) in subsystems
			if(isnull(subsystem))
				to_chat(ui.user, span_warning("Failed to locate subsystem."))
				return
			SSadmin_verbs.dynamic_invoke_verb(ui.user, /datum/admin_verb/debug_variables, subsystem)
			return TRUE

/datum/controller/master/proc/check_and_perform_fast_update()
	PRIVATE_PROC(TRUE)
	set waitfor = FALSE


	if(!overview_fast_update)
		return

	var/static/already_updating = FALSE
	if(already_updating)
		return
	already_updating = TRUE
	SStgui.update_uis(src)
	already_updating = FALSE

// Returns 1 if we created a new mc, 0 if we couldn't due to a recent restart,
// -1 if we encountered a runtime trying to recreate it
/proc/Recreate_MC()
	. = -1 //so if we runtime, things know we failed
	if (world.time < Master.restart_timeout)
		return 0
	if (world.time < Master.restart_clear)
		Master.restart_count *= 0.5

	var/delay = 50 * ++Master.restart_count
	Master.restart_timeout = world.time + delay
	Master.restart_clear = world.time + (delay * 2)
	if (Master) //Can only do this if master hasn't been deleted
		Master.processing = FALSE //stop ticking this one
	try
		new/datum/controller/master()
	catch
		return -1
	return 1


/datum/controller/master/Recover()
	var/msg = "## DEBUG: [time2text(world.timeofday)] MC restarted. Reports:\n"
	var/list/master_attributes = Master.vars
	var/list/filtered_variables = list(
		NAMEOF(src, name),
		NAMEOF(src, parent_type),
		NAMEOF(src, statclick),
		NAMEOF(src, tag),
		NAMEOF(src, type),
		NAMEOF(src, vars),
	)
	for (var/varname in master_attributes - filtered_variables)
		var/varval = master_attributes[varname]
		if (isdatum(varval)) // Check if it has a type var.
			var/datum/D = varval
			msg += "\t [varname] = [D]([D.type])\n"
		else
			msg += "\t [varname] = [varval]\n"
	log_world(msg)

	var/datum/controller/subsystem/BadBoy = Master.last_type_processed
	var/FireHim = FALSE
	if(istype(BadBoy))
		msg = null
		LAZYINITLIST(BadBoy.failure_strikes)
		switch(++BadBoy.failure_strikes[BadBoy.type])
			if(2)
				msg = "The [BadBoy.name] subsystem was the last to fire for 2 controller restarts. It will be recovered now and disabled if it happens again."
				FireHim = TRUE
			if(3)
				msg = "The [BadBoy.name] subsystem seems to be destabilizing the MC and will be put offline."
				BadBoy.flags |= SS_NO_FIRE
		if(msg)
			to_chat(GLOB.admins, span_boldannounce("[msg]"))
			log_world(msg)

	if (istype(Master.subsystems))
		if(FireHim)
			Master.subsystems += new BadBoy.type //NEW_SS_GLOBAL will remove the old one
		subsystems = Master.subsystems
		current_runlevel = Master.current_runlevel
		StartProcessing(10)
	else
		to_chat(world, span_boldannounce("The Master Controller is having some issues, we will need to re-initialize EVERYTHING"))
		Initialize(20, TRUE, FALSE)

// Please don't stuff random bullshit here,
// Make a subsystem, give it the SS_NO_FIRE flag, and do your work in it's Initialize()
/datum/controller/master/Initialize(delay, init_sss, tgs_prime)
	set waitfor = 0

	if(delay)
		_sleep(delay)

	if(init_sss)
		init_subtypes(/datum/controller/subsystem, subsystems)

	init_stage_completed = 0
	var/mc_started = FALSE

	to_chat(world, span_boldannounce("Initializing subsystems..."))

	var/list/stage_sorted_subsystems = new(INITSTAGE_MAX)
	for (var/i in 1 to INITSTAGE_MAX)
		stage_sorted_subsystems[i] = list()

	// Sort subsystems by init_order, so they initialize in the correct order.
	sortTim(subsystems, GLOBAL_PROC_REF(cmp_subsystem_init))

	for (var/datum/controller/subsystem/subsystem as anything in subsystems)
		var/subsystem_init_stage = subsystem.init_stage
		if (!isnum(subsystem_init_stage) || subsystem_init_stage < 1 || subsystem_init_stage > INITSTAGE_MAX || round(subsystem_init_stage) != subsystem_init_stage)
			stack_trace("ERROR: MC: subsystem `[subsystem.type]` has invalid init_stage: `[subsystem_init_stage]`. Setting to `[INITSTAGE_MAX]`")
			subsystem_init_stage = subsystem.init_stage = INITSTAGE_MAX
		stage_sorted_subsystems[subsystem_init_stage] += subsystem

	// Sort subsystems by display setting for easy access.
	sortTim(subsystems, GLOBAL_PROC_REF(cmp_subsystem_display))
	var/start_timeofday = REALTIMEOFDAY
	for (var/current_init_stage in 1 to INITSTAGE_MAX)

		// Initialize subsystems.
		for (var/datum/controller/subsystem/subsystem in stage_sorted_subsystems[current_init_stage])
			init_subsystem(subsystem)

			CHECK_TICK
		current_initializing_subsystem = null
		init_stage_completed = current_init_stage
		if (!mc_started)
			mc_started = TRUE
			if (!current_runlevel)
				SetRunLevel(1) // Intentionally not using the defines here because the MC doesn't care about them
			// Loop.
			Master.StartProcessing(0)

	var/time = (REALTIMEOFDAY - start_timeofday) / 10



	var/msg = "Initializations complete within [time] second[time == 1 ? "" : "s"]!"
	to_chat(world, span_boldannounce("[msg]"))
	log_world(msg)


	if(world.system_type == MS_WINDOWS && CONFIG_GET(flag/toast_notification_on_init) && !length(GLOB.clients))
		world.shelleo("start /min powershell -ExecutionPolicy Bypass -File tools/initToast/initToast.ps1 -name \"[world.name]\" -icon %CD%\\icons\\ui_icons\\common\\tg_16.png -port [world.port]")

	// Set world options.
	world.change_fps(CONFIG_GET(number/fps))
	var/initialized_tod = REALTIMEOFDAY

	if(tgs_prime)
		world.TgsInitializationComplete()

	if(sleep_offline_after_initializations)
		world.sleep_offline = TRUE
	_sleep(1 TICKS)

	if(sleep_offline_after_initializations && CONFIG_GET(flag/resume_after_initializations))
		world.sleep_offline = FALSE
	initializations_finished_with_no_players_logged_in = initialized_tod < REALTIMEOFDAY - 10

/**
 * Initialize a given subsystem and handle the results.
 *
 * Arguments:
 * * subsystem - the subsystem to initialize.
 */
/datum/controller/master/proc/init_subsystem(datum/controller/subsystem/subsystem)
	var/static/list/valid_results = list(
		SS_INIT_FAILURE,
		SS_INIT_NONE,
		SS_INIT_SUCCESS,
		SS_INIT_NO_NEED,
		SS_INIT_NO_MESSAGE,
	)

	if (subsystem.flags & SS_NO_INIT || subsystem.initialized) //Don't init SSs with the corresponding flag or if they already are initialized
		return

	current_initializing_subsystem = subsystem
	rustg_time_reset(SS_INIT_TIMER_KEY)

	var/result = subsystem.Initialize()

	// Capture end time
	var/time = rustg_time_milliseconds(SS_INIT_TIMER_KEY)
	var/seconds = round(time / 1000, 0.01)

	// Always update the blackbox tally regardless.
	SSblackbox.record_feedback("tally", "subsystem_initialize", time, subsystem.name)

	// Gave invalid return value.
	if(result && !(result in valid_results))
		warning("[subsystem.name] subsystem initialized, returning invalid result [result]. This is a bug.")

	// just returned ..() or didn't implement Initialize() at all
	if(result == SS_INIT_NONE)
		warning("[subsystem.name] subsystem does not implement Initialize() or it returns ..(). If the former is true, the SS_NO_INIT flag should be set for this subsystem.")

	if(result != SS_INIT_FAILURE)
		// Some form of success, implicit failure, or the SS in unused.
		subsystem.initialized = TRUE

		SEND_SIGNAL(subsystem, COMSIG_SUBSYSTEM_POST_INITIALIZE)
	else
		// The subsystem officially reports that it failed to init and wishes to be treated as such.
		subsystem.initialized = FALSE
		subsystem.can_fire = FALSE

	// The rest of this proc is printing the world log and chat message.
	var/message_prefix

	// If true, print the chat message with boldwarning text.
	var/chat_warning = FALSE

	switch(result)
		if(SS_INIT_FAILURE)
			message_prefix = "Failed to initialize [subsystem.name] subsystem after"
			chat_warning = TRUE
		if(SS_INIT_SUCCESS, SS_INIT_NO_MESSAGE)
			message_prefix = "Initialized [subsystem.name] subsystem within"
		if(SS_INIT_NO_NEED)
			// This SS is disabled or is otherwise shy.
			return
		else
			// SS_INIT_NONE or an invalid value.
			message_prefix = "Initialized [subsystem.name] subsystem with errors within"
			chat_warning = TRUE

	var/message = "[message_prefix] [seconds] second[seconds == 1 ? "" : "s"]!"
	var/chat_message = chat_warning ? span_boldwarning(message) : span_boldannounce(message)

	if(result != SS_INIT_NO_MESSAGE)
		to_chat(world, chat_message)
	log_world(message)

/datum/controller/master/proc/SetRunLevel(new_runlevel)
	var/old_runlevel = current_runlevel

	testing("MC: Runlevel changed from [isnull(old_runlevel) ? "NULL" : old_runlevel] to [new_runlevel]")
	current_runlevel = log(2, new_runlevel) + 1
	if(current_runlevel < 1)
		current_runlevel = old_runlevel
		CRASH("Attempted to set invalid runlevel: [new_runlevel]")

// Starts the mc, and sticks around to restart it if the loop ever ends.
/datum/controller/master/proc/StartProcessing(delay)
	set waitfor = 0
	if(delay)
		_sleep(delay)
	testing("Master starting processing")
	var/started_stage
	var/rtn = -2
	do
		started_stage = init_stage_completed
		rtn = Loop(started_stage)
	while (rtn == MC_LOOP_RTN_NEWSTAGES && processing > 0 && started_stage < init_stage_completed)

	if (rtn >= MC_LOOP_RTN_GRACEFUL_EXIT || processing < 0)
		return //this was suppose to happen.
	//loop ended, restart the mc
	log_game("MC crashed or runtimed, restarting")
	message_admins("MC crashed or runtimed, restarting")
	var/rtn2 = Recreate_MC()
	if (rtn2 <= 0)
		log_game("Failed to recreate MC (Error code: [rtn2]), it's up to the failsafe now")
		message_admins("Failed to recreate MC (Error code: [rtn2]), it's up to the failsafe now")
		Failsafe.defcon = 2

// Main loop.
/datum/controller/master/proc/Loop(init_stage)
	. = -1
	//Prep the loop (most of this is because we want MC restarts to reset as much state as we can, and because
	// local vars rock

	//all this shit is here so that flag edits can be refreshed by restarting the MC. (and for speed)
	var/list/tickersubsystems = list()
	var/list/runlevel_sorted_subsystems = list(list()) //ensure we always have at least one runlevel
	var/timer = world.time
	for (var/thing in subsystems)
		var/datum/controller/subsystem/SS = thing
		if (SS.flags & SS_NO_FIRE)
			continue
		if (SS.init_stage > init_stage)
			continue
		SS.queued_time = 0
		SS.queue_next = null
		SS.queue_prev = null
		SS.state = SS_IDLE
		if ((SS.flags & (SS_TICKER|SS_BACKGROUND)) == SS_TICKER)
			tickersubsystems += SS
			// Timer subsystems aren't allowed to bunch up, so we offset them a bit
			timer += world.tick_lag * rand(0, 1)
			SS.next_fire = timer
			continue

		var/ss_runlevels = SS.runlevels
		var/added_to_any = FALSE
		for(var/I in 1 to GLOB.bitflags.len)
			if(ss_runlevels & GLOB.bitflags[I])
				while(runlevel_sorted_subsystems.len < I)
					runlevel_sorted_subsystems += list(list())
				runlevel_sorted_subsystems[I] += SS
				added_to_any = TRUE
		if(!added_to_any)
			WARNING("[SS.name] subsystem is not SS_NO_FIRE but also does not have any runlevels set!")

	queue_head = null
	queue_tail = null
	//these sort by lower priorities first to reduce the number of loops needed to add subsequent SS's to the queue
	//(higher subsystems will be sooner in the queue, adding them later in the loop means we don't have to loop thru them next queue add)
	sortTim(tickersubsystems, GLOBAL_PROC_REF(cmp_subsystem_priority))
	for(var/I in runlevel_sorted_subsystems)
		sortTim(I, GLOBAL_PROC_REF(cmp_subsystem_priority))
		I += tickersubsystems

	var/cached_runlevel = current_runlevel
	var/list/current_runlevel_subsystems = runlevel_sorted_subsystems[cached_runlevel]

	init_timeofday = REALTIMEOFDAY
	init_time = world.time

	iteration = 1
	var/error_level = 0
	var/sleep_delta = 1
	var/list/subsystems_to_check

	//setup the stack overflow detector
	stack_end_detector = new()
	var/datum/stack_canary/canary = stack_end_detector.prime_canary()
	canary.use_variable()
	//the actual loop.
	while (1)
		var/starting_tick_usage = TICK_USAGE
		var/newdrift = ((REALTIMEOFDAY - init_timeofday) - (world.time - init_time)) / world.tick_lag
		tickdrift = max(0, MC_AVERAGE_FAST(tickdrift, newdrift))

		metadata_last_tick = metadata_this_tick
		metadata_this_tick = MC_METADATA_CREATE_LIST(starting_tick_usage, current_ticklimit, skip_ticks, sleep_delta, current_runlevel)
		//list(METADATA_IDENTIFIER_MC, starting_tick_usage, -1, MC_METADATA_GOTO_SLEEP_REASON_UNSET, current_ticklimit, skip_ticks, sleep_delta, current_runlevel, list(), -1, -1, -1)

		average_starting_tick_usage = MC_AVERAGE_FAST(average_starting_tick_usage, starting_tick_usage)

		if(newdrift - olddrift >= CONFIG_GET(number/drift_dump_threshold))
			AttemptProfileDump(CONFIG_GET(number/drift_profile_delay))
		olddrift = newdrift

		if (init_stage != init_stage_completed)
			return MC_LOOP_RTN_NEWSTAGES
		if (processing <= 0)
			current_ticklimit = TICK_LIMIT_RUNNING

			average_ticks_skipped = MC_AVG_FAST_UP_SLOW_DOWN(average_ticks_skipped, max(DS2TICKS(10) - 1, 0))
			last_ending_tick_usage = TICK_USAGE

			metadata_this_tick[MC_METADATA_ENDING_TICK_USAGE] = last_ending_tick_usage
			sleep_metadata(1 SECONDS, metadata_this_tick)

			continue

		//Anti-tick-contention heuristics:
		if (init_stage == INITSTAGE_MAX)
			//if there are mutiple sleeping procs running before us hogging the cpu, we have to run later.
			// (because sleeps are processed in the order received, longer sleeps are more likely to run first)
			if (starting_tick_usage > TICK_LIMIT_MC) //if there isn't enough time to bother doing anything this tick, sleep a bit.
				sleep_delta *= 2
				current_ticklimit = TICK_LIMIT_RUNNING * 0.5
				average_ticks_skipped = MC_AVG_FAST_UP_SLOW_DOWN(average_ticks_skipped, max(DS2TICKS(10) - 1, 0))
				last_ending_tick_usage = TICK_USAGE

				metadata_this_tick[MC_METADATA_GOTO_SLEEP_REASON] = MC_METADATA_GOTO_SLEEP_REASON_TICK_CONTENTION
				metadata_this_tick[MC_METADATA_ENDING_TICK_USAGE] = last_ending_tick_usage
				sleep_metadata(world.tick_lag * (processing * sleep_delta), metadata_this_tick)
				continue

			//Byond resumed us late. assume it might have to do the same next tick
			if (last_run + CEILING(world.tick_lag * (processing * sleep_delta), world.tick_lag) < world.time)
				sleep_delta += 1

			sleep_delta = MC_AVERAGE_FAST(sleep_delta, 1) //decay sleep_delta

			if (starting_tick_usage > (TICK_LIMIT_MC*0.75)) //we ran 3/4 of the way into the tick
				sleep_delta += 1
		else
			sleep_delta = 1

		//debug
		if (make_runtime)
			var/datum/controller/subsystem/SS
			SS.can_fire = 0

		if (!Failsafe || (Failsafe.processing_interval > 0 && (Failsafe.lasttick+(Failsafe.processing_interval*5)) < world.time))
			new/datum/controller/failsafe() // (re)Start the failsafe.

		//now do the actual stuff
		if (!skip_ticks)
			var/checking_runlevel = current_runlevel
			if(cached_runlevel != checking_runlevel)
				//resechedule subsystems
				var/list/old_subsystems = current_runlevel_subsystems
				cached_runlevel = checking_runlevel
				current_runlevel_subsystems = runlevel_sorted_subsystems[cached_runlevel]

				//now we'll go through all the subsystems we want to offset and give them a next_fire
				for(var/datum/controller/subsystem/SS as anything in current_runlevel_subsystems)
					//we only want to offset it if it's new and also behind
					if(SS.next_fire > world.time || (SS in old_subsystems))
						continue
					SS.next_fire = world.time + world.tick_lag * rand(0, DS2TICKS(min(SS.wait, 2 SECONDS)))

			subsystems_to_check = current_runlevel_subsystems
		else
			subsystems_to_check = tickersubsystems

		if (CheckQueue(subsystems_to_check) <= 0) //error processing queue
			stack_trace("MC: CheckQueue failed. Current error_level is [round(error_level, 0.25)]")
			if (!SoftReset(tickersubsystems, runlevel_sorted_subsystems))
				error_level++
				CRASH("MC: SoftReset() failed, exiting loop()")

			if (error_level < 2) //except for the first strike, stop incrmenting our iteration so failsafe enters defcon
				iteration++
			else
				cached_runlevel = null //3 strikes, Lets reset the runlevel lists
			current_ticklimit = TICK_LIMIT_RUNNING

			average_ticks_skipped = MC_AVG_FAST_UP_SLOW_DOWN(average_ticks_skipped, max((processing * sleep_delta) - 1, 0))
			last_ending_tick_usage = TICK_USAGE

			metadata_this_tick[MC_METADATA_ENDING_TICK_USAGE] = last_ending_tick_usage
			metadata_this_tick[MC_METADATA_GOTO_SLEEP_REASON] = MC_METADATA_GOTO_SLEEP_REASON_CHECKQUEUE_ERROR
			sleep_metadata((1 SECONDS) * error_level, metadata_this_tick)
			error_level++
			continue

		metadata_this_tick[MC_METADATA_TICK_LIMIT] = current_ticklimit

		if (queue_head)
			if (RunQueue() <= 0) //error running queue
				stack_trace("MC: RunQueue failed. Current error_level is [round(error_level, 0.25)]")
				if (error_level > 1) //skip the first error,
					if (!SoftReset(tickersubsystems, runlevel_sorted_subsystems))
						error_level++
						CRASH("MC: SoftReset() failed, exiting loop()")

					if (error_level <= 2) //after 3 strikes stop incrmenting our iteration so failsafe enters defcon
						iteration++
					else
						cached_runlevel = null //3 strikes, Lets also reset the runlevel lists
					current_ticklimit = TICK_LIMIT_RUNNING

					average_ticks_skipped = MC_AVG_FAST_UP_SLOW_DOWN(average_ticks_skipped, max((processing * sleep_delta) - 1, 0))
					last_ending_tick_usage = TICK_USAGE

					metadata_this_tick[MC_METADATA_ENDING_TICK_USAGE] = last_ending_tick_usage
					metadata_this_tick[MC_METADATA_GOTO_SLEEP_REASON] = MC_METADATA_GOTO_SLEEP_REASON_RUNQUEUE_ERROR

					sleep_metadata((1 SECONDS) * error_level, metadata_this_tick)
					error_level++
					continue
				error_level++
		if (error_level > 0)
			error_level = max(MC_AVERAGE_SLOW(error_level-1, error_level), 0)
		if (!queue_head) //reset the counts if the queue is empty, in the off chance they get out of sync
			queue_priority_count = 0
			queue_priority_count_bg = 0

		iteration++
		run_before_last = last_run
		last_run = world.time
		if (skip_ticks)
			skip_ticks--
		src.sleep_delta = MC_AVERAGE_FAST(src.sleep_delta, sleep_delta)

// Force any verbs into overtime, to test how they perfrom under load
// For local ONLY
#ifdef VERB_STRESS_TEST
		/// Target enough tick usage to only allow time for our maptick estimate and verb processing, and nothing else
		var/overtime_target = TICK_LIMIT_RUNNING
// This will leave just enough cpu time for maptick, forcing verbs to run into overtime
// Use this for testing the worst case scenario, when maptick is spiking and usage is otherwise completely consumed
#ifdef FORCE_VERB_OVERTIME
		overtime_target += TICK_BYOND_RESERVE
#endif
		CONSUME_UNTIL(overtime_target)
#endif

		if (init_stage != INITSTAGE_MAX)
			current_ticklimit = TICK_LIMIT_RUNNING * 2
		else
			current_ticklimit = TICK_LIMIT_RUNNING
			if (processing * sleep_delta <= world.tick_lag)
				current_ticklimit -= (TICK_LIMIT_RUNNING * 0.25) //reserve the tail 1/4 of the next tick for the mc if we plan on running next tick

		check_and_perform_fast_update()

		average_ticks_skipped = MC_AVG_FAST_UP_SLOW_DOWN(average_ticks_skipped, max((processing * sleep_delta) - 1, 0))

		average_MC_tick_usage = MC_AVERAGE_FAST(average_MC_tick_usage, max(last_ending_tick_usage - starting_tick_usage, 0))

		average_post_maptick_tick_usage = MC_AVERAGE_FAST(average_post_maptick_tick_usage, max(last_post_maptick_tick_usage - (last_ending_tick_usage + MAPTICK_LAST_INTERNAL_TICK_USAGE), 0))

		if(metadata_last_tick && run_before_last == world.time - world.tick_lag)
			metadata_last_tick[MC_METADATA_POST_MAPTICK_USAGE] = last_post_maptick_tick_usage

		last_post_maptick_tick_usage = 0 //any client procs/verbs that execute later in this tick updates this number

		last_ending_tick_usage = TICK_USAGE

		metadata_this_tick[MC_METADATA_ENDING_TICK_USAGE] = last_ending_tick_usage
		sleep_metadata(world.tick_lag * (processing * sleep_delta), metadata_this_tick)

/// This is what decides if something should run.
/datum/controller/master/proc/CheckQueue(list/subsystemstocheck)
	. = 0 //so the mc knows if we runtimed

	//we create our variables outside of the loops to save on overhead
	var/datum/controller/subsystem/SS
	var/SS_flags

	for (var/thing in subsystemstocheck)
		if (!thing)
			subsystemstocheck -= thing
		SS = thing
		if (SS.state != SS_IDLE)
			continue
		if (SS.can_fire <= 0)
			continue
		if (SS.next_fire > world.time)
			continue
		SS_flags = SS.flags
		if (SS_flags & SS_NO_FIRE)
			subsystemstocheck -= SS
			continue
		if ((SS_flags & (SS_TICKER|SS_KEEP_TIMING)) == SS_KEEP_TIMING && SS.last_fire + (SS.wait * 0.75) > world.time)
			continue
		if (SS.postponed_fires >= 1)
			SS.postponed_fires--
			SS.update_nextfire()
			continue
		SS.enqueue()
	. = 1


/// RunQueue - Run thru the queue of subsystems to run, running them while balancing out their allocated tick precentage
/// Returns 0 if runtimed, a negative number for logic errors, and a positive number if the operation completed without errors
/datum/controller/master/proc/RunQueue()
	. = 0
	var/datum/controller/subsystem/queue_node
	var/queue_node_flags
	var/queue_node_priority
	var/queue_node_paused

	var/current_tick_budget
	var/tick_precentage
	var/tick_remaining
	var/ran = TRUE //this is right
	var/bg_calc //!have we switched current_tick_budget to background mode yet?
	var/tick_usage

	//keep running while we have stuff to run and we haven't gone over a tick
	// this is so subsystems paused eariler can use tick time that later subsystems never used
	while (ran && queue_head && TICK_USAGE < TICK_LIMIT_MC)
		ran = FALSE
		bg_calc = FALSE
		current_tick_budget = queue_priority_count
		queue_node = queue_head
		while (queue_node)
			if (ran && TICK_USAGE > TICK_LIMIT_RUNNING)
				break
			queue_node_flags = queue_node.flags
			queue_node_priority = queue_node.queued_priority

			if (!(queue_node_flags & SS_TICKER) && skip_ticks)
				queue_node = queue_node.queue_next
				continue

			if ((queue_node_flags & SS_BACKGROUND))
				if (!bg_calc)
					current_tick_budget = queue_priority_count_bg
					bg_calc = TRUE
			else if (bg_calc)
				//error state, do sane fallback behavior
				if (. == 0)
					log_world("MC: Queue logic failure, non-background subsystem queued to run after a background subsystem: [queue_node] queue_prev:[queue_node.queue_prev]")
				. = -1
				current_tick_budget = queue_priority_count //this won't even be right, but is the best we have.
				bg_calc = FALSE


			tick_remaining = TICK_LIMIT_RUNNING - TICK_USAGE

			if (queue_node_priority >= 0 && current_tick_budget > 0 && current_tick_budget >= queue_node_priority)
				//Give the subsystem a precentage of the remaining tick based on the remaining priority
				tick_precentage = tick_remaining * (queue_node_priority / current_tick_budget)
			else
				//error state
				if (. == 0)
					log_world("MC: tick_budget sync error. [json_encode(list(current_tick_budget, queue_priority_count, queue_priority_count_bg, bg_calc, queue_node, queue_node_priority))]")
				. = -1
				tick_precentage = tick_remaining //just because we lost track of priority calculations doesn't mean we can't try to finish off the run, if the error state persists, we don't want to stop ticks from happening

			tick_precentage = max(tick_precentage*0.5, tick_precentage-queue_node.tick_overrun)

			current_ticklimit = round(TICK_USAGE + tick_precentage)

			ran = TRUE

			queue_node_paused = (queue_node.state == SS_PAUSED || queue_node.state == SS_PAUSING)
			last_type_processed = queue_node

			var/list/subsystem_metadata = MC_METADATA_CREATE_SUBSYSTEM_LIST(queue_node.name, tick_precentage, queue_node_priority, queue_node_flags, queue_node.state)
			//list(queue_node.name, 0, tick_precentage, 0, queue_node_priority, queue_node_flags, queue_node.state, NONE)

			queue_node.state = SS_RUNNING

			if(queue_node.profiler_focused)
				world.Profile(PROFILE_START)

			tick_usage = TICK_USAGE
			var/state = queue_node.ignite(queue_node_paused)
			tick_usage = TICK_USAGE - tick_usage

			if(queue_node.profiler_focused)
				world.Profile(PROFILE_STOP)

			if (state == SS_RUNNING)
				state = SS_IDLE
			current_tick_budget -= queue_node_priority


			if (tick_usage < 0)
				tick_usage = 0
			queue_node.tick_overrun = max(0, MC_AVG_FAST_UP_SLOW_DOWN(queue_node.tick_overrun, tick_usage-tick_precentage))
			queue_node.state = state

			subsystem_metadata[MC_METADATA_SUBSYSTEM_END_STATE] = queue_node.state
			subsystem_metadata[MC_METADATA_SUBSYSTEM_TICK_USAGE] = tick_usage
			subsystem_metadata[MC_METADATA_SUBSYSTEM_OVERTIME] = tick_usage - tick_precentage

			metadata_this_tick[MC_METADATA_SUBSYSTEMS] += list(subsystem_metadata)

			if (state == SS_PAUSED)
				queue_node.paused_ticks++
				queue_node.paused_tick_usage += tick_usage
				queue_node = queue_node.queue_next
				continue

			queue_node.ticks = MC_AVERAGE(queue_node.ticks, queue_node.paused_ticks)
			tick_usage += queue_node.paused_tick_usage

			queue_node.tick_usage = MC_AVERAGE_FAST(queue_node.tick_usage, tick_usage)

			queue_node.cost = MC_AVERAGE_FAST(queue_node.cost, TICK_DELTA_TO_MS(tick_usage))
			queue_node.paused_ticks = 0
			queue_node.paused_tick_usage = 0

			if (bg_calc) //update our running total
				queue_priority_count_bg -= queue_node_priority
			else
				queue_priority_count -= queue_node_priority

			queue_node.last_fire = world.time
			queue_node.times_fired++

			queue_node.update_nextfire()

			queue_node.queued_time = 0

			//remove from queue
			queue_node.dequeue()

			queue_node = queue_node.queue_next

	if (. == 0)
		. = 1

//resets the queue, and all subsystems, while filtering out the subsystem lists
// called if any mc's queue procs runtime or exit improperly.
/datum/controller/master/proc/SoftReset(list/ticker_SS, list/runlevel_SS)
	. = 0
	stack_trace("MC: SoftReset called, resetting MC queue state.")

	if (!istype(subsystems) || !istype(ticker_SS) || !istype(runlevel_SS))
		log_world("MC: SoftReset: Bad list contents: '[subsystems]' '[ticker_SS]' '[runlevel_SS]'")
		return
	var/subsystemstocheck = subsystems | ticker_SS
	for(var/I in runlevel_SS)
		subsystemstocheck |= I

	for (var/thing in subsystemstocheck)
		var/datum/controller/subsystem/SS = thing
		if (!SS || !istype(SS))
			//list(SS) is so if a list makes it in the subsystem list, we remove the list, not the contents
			subsystems -= list(SS)
			ticker_SS -= list(SS)
			for(var/I in runlevel_SS)
				I -= list(SS)
			log_world("MC: SoftReset: Found bad entry in subsystem list, '[SS]'")
			continue
		if (SS.queue_next && !istype(SS.queue_next))
			log_world("MC: SoftReset: Found bad data in subsystem queue, queue_next = '[SS.queue_next]'")
		SS.queue_next = null
		if (SS.queue_prev && !istype(SS.queue_prev))
			log_world("MC: SoftReset: Found bad data in subsystem queue, queue_prev = '[SS.queue_prev]'")
		SS.queue_prev = null
		SS.queued_priority = 0
		SS.queued_time = 0
		SS.state = SS_IDLE
	if (queue_head && !istype(queue_head))
		log_world("MC: SoftReset: Found bad data in subsystem queue, queue_head = '[queue_head]'")
	queue_head = null
	if (queue_tail && !istype(queue_tail))
		log_world("MC: SoftReset: Found bad data in subsystem queue, queue_tail = '[queue_tail]'")
	queue_tail = null
	queue_priority_count = 0
	queue_priority_count_bg = 0
	log_world("MC: SoftReset: Finished.")
	. = 1

/// Warns us that the end of tick byond map_update will be laggier then normal, so that we can just skip running subsystems this tick.
/datum/controller/master/proc/laggy_byond_map_update_incoming()
	if (!skip_ticks)
		skip_ticks = 1


/datum/controller/master/stat_entry(msg)
	msg = "(Ticks Per MC Iteration:[Master.processing]) (Iteration:[Master.iteration]) (Max Tick Limit: [round(Master.current_ticklimit, 0.1)])\
	(Sleeping Overtime: [round(Master.average_sleeping_overtime_usage, 0.1)]) \
	(stoplag Threads: [stoplag_threads]) (Ticks Skipped [round(average_ticks_skipped, 0.1)])"
	return msg

///returns stats on how recent ticks have been divvied up between the MC, pre MC sleeping procs, post MC sleeping procs, maptick, and post maptick client verbs and procs
/datum/controller/master/proc/return_tick_divisions()
	var/message = "(Pre MC: [round(Master.average_starting_tick_usage, 0.1)]%)"//accurate
	message += " (MC: [round(Master.average_MC_tick_usage, 0.1)]%)"//accurate
	message += " (Post MC: [round(Master.average_sleeping_tick_usage, 0.1)]%)"//accurate
	message += " (Maptick: [round(MAPTICK_LAST_INTERNAL_TICK_USAGE,0.1)]%)"//accurate
	message += " (Post Maptick: [round(Master.average_post_maptick_tick_usage, 0.1)]%)"//not very accurate since we need to use an average to derive this and not all verbs covered

	return message


/datum/controller/master/StartLoadingMap()
	//disallow more than one map to load at once, multithreading it will just cause race conditions
	while(map_loading)
		stoplag()
	for(var/S in subsystems)
		var/datum/controller/subsystem/SS = S
		SS.StartLoadingMap()
	map_loading = TRUE

/datum/controller/master/StopLoadingMap(bounds = null)
	map_loading = FALSE
	for(var/S in subsystems)
		var/datum/controller/subsystem/SS = S
		SS.StopLoadingMap()


/datum/controller/master/proc/UpdateTickRate()
	if (!processing)
		return
	var/client_count = length(GLOB.clients)
	if (client_count < CONFIG_GET(number/mc_tick_rate/disable_high_pop_mc_mode_amount))
		processing = CONFIG_GET(number/mc_tick_rate/base_mc_tick_rate)
	else if (client_count > CONFIG_GET(number/mc_tick_rate/high_pop_mc_mode_amount))
		processing = CONFIG_GET(number/mc_tick_rate/high_pop_mc_tick_rate)

/datum/controller/master/proc/OnConfigLoad()
	for (var/thing in subsystems)
		var/datum/controller/subsystem/SS = thing
		SS.OnConfigLoad()

/// Attempts to dump our current profile info into a file, triggered if the MC thinks shit is going down
/// Accepts a delay in deciseconds of how long ago our last dump can be, this saves causing performance problems ourselves
/datum/controller/master/proc/AttemptProfileDump(delay)
	if(REALTIMEOFDAY - last_profiled <= delay)
		return FALSE
	last_profiled = REALTIMEOFDAY
	SSprofiler.DumpFile(allow_yield = FALSE)

SUBSYSTEM_DEF(maptick_track)
	name = "Maptick Tracking"
	wait = 5
	flags = SS_TICKER
	init_order = INIT_ORDER_MAPTICK
	runlevels = RUNLEVEL_GAME

	var/file_output_name //we output the recorded values to this name of file
	var/file_output_path //where the file we make is
	var/average_maptick = 0
	var/list/all_maptick_values = list()
	can_fire = FALSE

	var/list/used_filenames = list()
	var/time_dilation_current = 0

	var/time_dilation_avg_fast = 0
	var/time_dilation_avg = 0
	var/time_dilation_avg_slow = 0

	var/first_run = TRUE

	var/last_tick_realtime = 0
	var/last_tick_byond_time = 0
	var/last_tick_tickcount = 0

/datum/controller/subsystem/maptick_track/Initialize(start_timeofday)
	. = ..()

/datum/controller/subsystem/maptick_track/proc/start_tracking(filename)
	for (var/possible_repeated_name in used_filenames)
		if (possible_repeated_name == filename)
			return FALSE
	file_output_name = filename
	file_output_path = "[GLOB.log_directory]/mapticktest-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.config?.map_name]-[file_output_name].csv"
	can_fire = TRUE

/datum/controller/subsystem/maptick_track/proc/stop_tracking()
	can_fire = FALSE
	used_filenames += file_output_name
	all_maptick_values.Cut()
	first_run = TRUE

/datum/controller/subsystem/maptick_track/fire()

	if (first_run)
		log_maptick(
			list(
				"maptick",
				"average maptick",
				"players",
				"time",
			),
			file_output_path
		)
		first_run = FALSE

	average_maptick = 0
	all_maptick_values += MAPTICK_LAST_INTERNAL_TICK_USAGE

	for (var/i in all_maptick_values)
		average_maptick += i
	average_maptick = average_maptick / all_maptick_values.len

	log_maptick(
		list(
			MAPTICK_LAST_INTERNAL_TICK_USAGE, //maptick
			average_maptick, //average maptick
			length(GLOB.clients), //players
			world.time, //current time
		),
		file_output_path
	)
/*
log_maptick(
		list(
			"maptick",
			"players",
			"time",
			"tidi",
			"tidi_fastavg",
			"tidi_avg",
			"tidi_slowavg"
		),
		file_output_name
	)*/

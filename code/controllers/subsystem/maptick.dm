#define TEST_INTENSITY_LOW 		"low"
#define TEST_INTENSITY_MEDIUM	"medium"
#define TEST_INTENSITY_HIGH		"high"

SUBSYSTEM_DEF(maptick_track)
	name = "Maptick Tracking"
	wait = 5
	flags = SS_TICKER
	init_order = INIT_ORDER_MAPTICK
	runlevels = RUNLEVEL_GAME

	var/file_output_name //we output the recorded values to this name of file
	var/file_output_path //where the file we make is

	var/list/all_maptick_values = list()
	var/average_maptick = 0

	var/total_client_movement_this_fire = 0 //how many combined tiles all mobs with attached clients have moved since our last fire()
	var/number_of_dead_clients = 0

	var/list/used_filenames = list()

	var/starting_time

	var/first_run = TRUE
	can_fire = FALSE

/datum/controller/subsystem/maptick_track/Initialize(start_timeofday)
	. = ..()

/datum/controller/subsystem/maptick_track/proc/start_tracking(filename, track_movement = FALSE, intensity = TEST_INTENSITY_HIGH)
	for (var/possible_repeated_name in used_filenames)
		if (possible_repeated_name == filename)
			return FALSE
	starting_time = world.time
	file_output_name = filename
	file_output_path = "[GLOB.log_directory]/mapticktest-[world.timeofday]-[SSmapping.config?.map_name]-[file_output_name].csv"
	can_fire = TRUE
	log_maptick(
			list(
				"maptick",
				"average maptick",
				"minutes",
				"players",
			),
			file_output_path
		)



/datum/controller/subsystem/maptick_track/proc/stop_tracking()
	can_fire = FALSE
	used_filenames += file_output_name
	all_maptick_values.Cut()
	first_run = TRUE

/datum/controller/subsystem/maptick_track/fire()

	average_maptick = 0
	all_maptick_values += MAPTICK_LAST_INTERNAL_TICK_USAGE

	for (var/i in all_maptick_values)
		average_maptick += i
	average_maptick = average_maptick / all_maptick_values.len

	log_maptick(
		list(
			MAPTICK_LAST_INTERNAL_TICK_USAGE, //maptick
			average_maptick, //average maptick
			(world.time-starting_time) / 600, //current time in minutes
			length(GLOB.player_list), //players
		),
		file_output_path
	)

#undef TEST_INTENSITY_LOW
#undef TEST_INTENSITY_MEDIUM
#undef TEST_INTENSITY_HIGH

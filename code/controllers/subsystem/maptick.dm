#define TEST_INTENSITY_LOW 		"low"
#define TEST_INTENSITY_MEDIUM	"medium"
#define TEST_INTENSITY_HIGH		"high"

#define DELTA_MAPTICK_AVERAGE_ALERT_MINIMUM 0.0001

SUBSYSTEM_DEF(maptick_track)
	name = "Maptick Tracking"
	wait = 5
	flags = SS_TICKER
	init_order = INIT_ORDER_MAPTICK
	runlevels = RUNLEVEL_GAME

	var/file_output_name //we output the recorded values to this name of file
	var/file_output_path //where the file we make is
	var/list/used_filenames = list()

	var/list/all_maptick_values = list()
	var/average_maptick = 0

	var/list/x_minute_values = list()
	var/total_values_in_x_minutes = 5 * 60 * (10 / 5)//reeeeee why is wait an invalid variable
	var/x_minute_average = 0

	var/total_client_movement = 0 //how many combined tiles all mobs with attached clients have moved since our last fire()
	var/client_movement_over_time = 0 //total client movement divided by time elapsed
	var/number_of_dead_clients = 0

	var/list/tracked_client_mobs = list()

	var/starting_time
	var/time_elapsed = 0

	var/delta_maptick_average = 0
	var/stored_maptick_average = 0
	var/last_fire_maptick_average = 0


	var/first_run = TRUE
	can_fire = FALSE

/datum/controller/subsystem/maptick_track/Initialize(start_timeofday)
	. = ..()

/datum/controller/subsystem/maptick_track/proc/start_tracking(filename, track_movement = FALSE, intensity = TEST_INTENSITY_HIGH)
	for (var/possible_repeated_name in used_filenames)
		if (possible_repeated_name == filename)
			return FALSE
	starting_time = REALTIMEOFDAY
	file_output_name = filename
	file_output_path = "[GLOB.log_directory]/mapticktest-[world.timeofday]-[SSmapping.config?.map_name]-[file_output_name].csv"
	can_fire = TRUE
	log_maptick(
			list(
				"maptick",
				"average maptick",
				"5 minute average", //the last 600 measured maptick values
				"minutes",
				"players",
				"total tiles moved",
				"tiles moved per minute"
			),
			file_output_path
		)
	for (var/mob/mob_with_client in GLOB.player_list)
		RegisterSignal(mob_with_client, COMSIG_MOB_LOGOUT, .proc/unregister_mob, TRUE)
		RegisterSignal(mob_with_client, COMSIG_MOVABLE_MOVED, .proc/increment_tilesmoved, TRUE)
		tracked_client_mobs += mob_with_client
	SSair.can_fire = FALSE
	SSmachines.can_fire = FALSE
	SSnpcpool.can_fire = FALSE
	SSidlenpcpool.can_fire = FALSE
	SSadjacent_air.can_fire = FALSE
	SSshuttle.can_fire = FALSE
	SSweather.can_fire = FALSE
	SSradiation.can_fire = FALSE
	SSfire_burning.can_fire = FALSE
	SSmobs.can_fire = FALSE
	SSai_controllers.can_fire = FALSE
	SSeconomy.can_fire = FALSE
	SSfluids.can_fire = FALSE
	SSobj.can_fire = FALSE
	return TRUE

/datum/controller/subsystem/maptick_track/proc/unregister_mob(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOB_LOGOUT)
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)


/datum/controller/subsystem/maptick_track/proc/increment_tilesmoved(datum/source, atom/_OldLoc, _Dir, _Forced = FALSE)
	SIGNAL_HANDLER
	total_client_movement++

/datum/controller/subsystem/maptick_track/proc/stop_tracking()
	message_admins("the [file_output_name] maptick test has stopped")
	can_fire = FALSE
	used_filenames += file_output_name
	all_maptick_values.Cut()
	total_client_movement = 0
	for (var/mob/mob_with_client in GLOB.player_list)
		unregister_mob(mob_with_client)

	first_run = TRUE

/datum/controller/subsystem/maptick_track/fire()

	average_maptick = 0

	all_maptick_values += MAPTICK_LAST_INTERNAL_TICK_USAGE
	x_minute_values += MAPTICK_LAST_INTERNAL_TICK_USAGE

	for (var/i in all_maptick_values)
		average_maptick += i
	average_maptick = average_maptick / all_maptick_values.len

	if (x_minute_values.len > total_values_in_x_minutes)
		x_minute_values.Remove(x_minute_values[1])
	for (var/i in x_minute_values)
		x_minute_average += i
	x_minute_average = x_minute_average / x_minute_values.len

	time_elapsed = (REALTIMEOFDAY-starting_time) / 600
	client_movement_over_time = total_client_movement / time_elapsed

	log_maptick(
		list(
			MAPTICK_LAST_INTERNAL_TICK_USAGE, //maptick
			average_maptick, //average maptick
			x_minute_average, //moving average over x minutes, by default its 5
			time_elapsed, //current time in minutes
			length(GLOB.player_list), //players
			total_client_movement,
			client_movement_over_time,
		),
		file_output_path
	)

#undef TEST_INTENSITY_LOW
#undef TEST_INTENSITY_MEDIUM
#undef TEST_INTENSITY_HIGH

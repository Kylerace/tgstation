#define TEST_INTENSITY_LOW 		"low"
#define TEST_INTENSITY_MEDIUM	"medium"
#define TEST_INTENSITY_HIGH		"high"

#define DELTA_MAPTICK_AVERAGE_ALERT_MINIMUM 0.01 //default is 0.0001
#define DELTA_MAPTICK_CYCLES_TO_ALERT 20

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

	var/most_recent_delta_maptick_average = 0
	var/average_delta_maptick_average = 0 //average difference between each new maptick average and the value before it
	var/last_fire_maptick_average = 0
	var/total_x_cycles_below_delta_average_minimum = 0

	var/times_fired_this_cycle = 0
	var/list/all_sampled_x_minute_averages = list()

	var/standard_deviation = 0

	var/first_run = TRUE
	can_fire = FALSE

/datum/controller/subsystem/maptick_track/proc/start_tracking(filename, track_movement = FALSE, intensity = TEST_INTENSITY_MEDIUM)
	for (var/possible_repeated_name in used_filenames)
		if (possible_repeated_name == filename)
			return FALSE

	if (intensity == TEST_INTENSITY_HIGH)
		wait = 1
	else if (intensity == TEST_INTENSITY_MEDIUM)
		wait = 5
	else if (intensity == TEST_INTENSITY_LOW)
		wait = 10

	all_maptick_values.Cut()
	all_sampled_x_minute_averages.Cut()
	total_client_movement = 0

	average_maptick = MAPTICK_LAST_INTERNAL_TICK_USAGE
	last_fire_maptick_average = MAPTICK_LAST_INTERNAL_TICK_USAGE
	most_recent_delta_maptick_average = 0

	times_fired_this_cycle = 0
	starting_time = REALTIMEOFDAY
	file_output_name = filename
	file_output_path = "[GLOB.log_directory]/mapticktest-[REALTIMEOFDAY]-[SSmapping.config?.map_name]-[file_output_name].csv"
	can_fire = TRUE

	log_maptick_stats("start")

	for (var/mob/mob_with_client in GLOB.player_list)
		RegisterSignal(mob_with_client, COMSIG_MOB_LOGOUT, .proc/unregister_mob, TRUE)
		RegisterSignal(mob_with_client, COMSIG_MOVABLE_MOVED, .proc/increment_tilesmoved, TRUE)
		tracked_client_mobs += mob_with_client

	#ifdef MAPTICK_TESTING
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
	#endif

	return TRUE

/datum/controller/subsystem/maptick_track/proc/unregister_mob(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOB_LOGOUT)
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)


/datum/controller/subsystem/maptick_track/proc/increment_tilesmoved(datum/source, atom/_OldLoc, _Dir, _Forced = FALSE)
	SIGNAL_HANDLER
	total_client_movement++

/datum/controller/subsystem/maptick_track/proc/stop_tracking()
	can_fire = FALSE
	message_admins("the [file_output_name] maptick test has stopped")

	used_filenames += file_output_name


	for (var/mob/mob_with_client in GLOB.player_list)
		unregister_mob(mob_with_client)

	var/temp_average = 0
	for (var/i in all_maptick_values)
		temp_average += i
	average_maptick = temp_average / all_maptick_values.len

	time_elapsed = (REALTIMEOFDAY-starting_time) / 600
	client_movement_over_time = time_elapsed ? total_client_movement / time_elapsed : 0

	calculate_standard_deviation()

	log_maptick_stats("end")

	#ifdef MAPTICK_TESTING
	first_run = TRUE
	SSair.can_fire = TRUE
	SSmachines.can_fire = TRUE
	SSnpcpool.can_fire = TRUE
	SSidlenpcpool.can_fire = TRUE
	SSadjacent_air.can_fire = TRUE
	SSshuttle.can_fire = TRUE
	SSweather.can_fire = TRUE
	SSradiation.can_fire = TRUE
	SSfire_burning.can_fire = TRUE
	SSmobs.can_fire = TRUE
	SSai_controllers.can_fire = TRUE
	SSeconomy.can_fire = TRUE
	SSfluids.can_fire = TRUE
	SSobj.can_fire = TRUE
	#endif

/datum/controller/subsystem/maptick_track/fire()
	times_fired_this_cycle++

	all_maptick_values += MAPTICK_LAST_INTERNAL_TICK_USAGE
	x_minute_values += MAPTICK_LAST_INTERNAL_TICK_USAGE


	if (x_minute_values.len > total_values_in_x_minutes)
		x_minute_values.Remove(x_minute_values[1])
	for (var/i in x_minute_values)
		x_minute_average += i
	x_minute_average = x_minute_average / x_minute_values.len //takes the average maptick value over the last 5 minutes

	//turns out adding all measured maptick values and dividing them to get the average every 0.5 seconds is expensive
	//now the total average is calculated every 5 minutes once x_minute_values has completely replaced every number from the previous cycle
	if (times_fired_this_cycle >= total_values_in_x_minutes)
		all_sampled_x_minute_averages += x_minute_average
		var/temp_average = 0
		for (var/i in all_sampled_x_minute_averages)
			temp_average += i
		average_maptick = temp_average / all_sampled_x_minute_averages.len
		times_fired_this_cycle = 0

		most_recent_delta_maptick_average = abs(average_maptick - last_fire_maptick_average)
		if (most_recent_delta_maptick_average < DELTA_MAPTICK_AVERAGE_ALERT_MINIMUM)
			total_x_cycles_below_delta_average_minimum++

			if (total_x_cycles_below_delta_average_minimum > DELTA_MAPTICK_CYCLES_TO_ALERT)
				message_admins("Delta maptick average has gone below [DELTA_MAPTICK_AVERAGE_ALERT_MINIMUM] for more than [DELTA_MAPTICK_CYCLES_TO_ALERT * 20] minutes")


	time_elapsed = (REALTIMEOFDAY-starting_time) / 600
	client_movement_over_time = time_elapsed ? total_client_movement / time_elapsed : 0

	log_maptick_stats("mid")

/datum/controller/subsystem/maptick_track/proc/calculate_standard_deviation()
	var/sums_of_square_of_deviations_from_mean = 0 //basically the sigma in standard deviation
	for (var/i in all_maptick_values)
		sums_of_square_of_deviations_from_mean += (i - average_maptick) ** 2 //for each datapoint, find the square of its distance to the mean
	standard_deviation = sqrt(sums_of_square_of_deviations_from_mean / all_maptick_values.len)

/datum/controller/subsystem/maptick_track/proc/log_maptick_stats(log_type = "mid")
	if(!file_output_path)
		stack_trace("no file output path selected!")

	switch(log_type)
		if("start")
			log_maptick(
				list(
					"maptick",
					"5 minute average", //the last 600 measured maptick values
					"minutes",
					"average maptick",
					"world.cpu - maptick",
					//"players",
					//"total tiles moved",
					//"tiles moved per minute",
					//"delta maptick average",
					"standard deviation",
					"world.tick_usage"
				),
				file_output_path
			)

		if("mid")
			log_maptick(
				list(
					MAPTICK_LAST_INTERNAL_TICK_USAGE, //maptick
					x_minute_average, //moving average over x minutes, by default its 5
					time_elapsed, //current time in minutes
					"", //average maptick, filled in at the end
					world.cpu - MAPTICK_LAST_INTERNAL_TICK_USAGE,
					//length(GLOB.player_list), //players
					//total_client_movement,
					//client_movement_over_time,
					//most_recent_delta_maptick_average,
					standard_deviation ? standard_deviation : "", //standard deviation, filled in at the end (unless its requested to calculate it)
					world.tick_usage,
				),
				file_output_path
			)

		if("end")
			log_maptick(
				list(
					MAPTICK_LAST_INTERNAL_TICK_USAGE, //maptick
					x_minute_average, //moving average over x minutes, by default its 5
					time_elapsed, //current time in minutes
					average_maptick, //average maptick
					world.cpu - MAPTICK_LAST_INTERNAL_TICK_USAGE,
					//length(GLOB.player_list), //players
					//total_client_movement,
					//client_movement_over_time,
					//most_recent_delta_maptick_average,
					standard_deviation,
					world.tick_usage
				),
			file_output_path
			)


#undef TEST_INTENSITY_LOW
#undef TEST_INTENSITY_MEDIUM
#undef TEST_INTENSITY_HIGH
#undef DELTA_MAPTICK_AVERAGE_ALERT_MINIMUM
#undef DELTA_MAPTICK_CYCLES_TO_ALERT

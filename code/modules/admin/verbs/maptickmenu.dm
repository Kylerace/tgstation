/client/proc/maptick_menu()
	set name = "Maptick Menu"
	set category = "Debug"
	var/datum/maptick_menu/tgui = new(usr)
	tgui.ui_interact(usr)

/datum/maptick_menu
	var/client/holder
	var/ongoing_test = FALSE

	var/current_maptick_average
	var/current_maptick_exact
	var/current_moving_average
	var/time_elapsed
	var/name

/datum/maptick_menu/ui_state(mob/user)
	return GLOB.admin_state

/datum/maptick_menu/New(user)
	current_maptick_average = SSmaptick_track.average_maptick
	current_maptick_exact = MAPTICK_LAST_INTERNAL_TICK_USAGE
	current_moving_average = SSmaptick_track.x_minute_average
	time_elapsed = SSmaptick_track.time_elapsed
	if (istype(user, /client))
		var/client/user_client = user
		holder = user_client //if its a client, assign it to holder
	else
		var/mob/user_mob = user
		holder = user_mob.client

/datum/maptick_menu/ui_close()
	qdel(src)

/datum/maptick_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Maptick")
		ui.open()

/datum/maptick_menu/ui_data(mob/user)
	var/list/data = list()
	data["ongoing_test"] = ongoing_test
	data["current_maptick_average"] = current_maptick_average
	data["current_maptick_exact"] = current_maptick_exact
	data["current_moving_average"] = current_moving_average
	data["time_elapsed"] = time_elapsed
	data["templates"] = SSmapping.maptick_templates
	data["players"] = length(GLOB.player_list)


	return data

/datum/maptick_menu/ui_act(action, params)
	. = ..()
	if(.)
		return

	//switch(action)

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
	var/list/template_ids = list()
	var/current_template = null

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
	generate_program_list()

/datum/maptick_menu/ui_close()
	qdel(src)

/datum/maptick_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Maptick")
		ui.open()

/datum/maptick_menu/proc/generate_program_list()
	for (var/template_path in subtypesof(/datum/map_template/mapticktest))
		var/datum/map_template/mapticktest/true_template = template_path
		template_ids += initial(true_template.maptick_id)//template_ids["name"] = initial(true_template.maptick_id)


/datum/maptick_menu/ui_data(mob/user)
	var/list/data = list()
	data["ongoing_test"] = ongoing_test
	data["current_maptick_average"] = SSmaptick_track.average_maptick
	data["current_maptick_exact"] = MAPTICK_LAST_INTERNAL_TICK_USAGE
	data["current_moving_average"] = SSmaptick_track.x_minute_average
	data["time_elapsed"] = SSmaptick_track.time_elapsed
	data["templates"] = template_ids
	data["players"] = length(GLOB.player_list)
	data["selected_template"] = current_template

	return data

/datum/maptick_menu/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("template select")
			current_template = params["select"]
			message_admins("[current_template] has been selected")

		if("load template")
			load_test(current_template)
			message_admins("load template [current_template]")

		if("start test")
			SSmaptick_track.start_tracking("ecksdee")
			message_admins("start test")

		if("stop test")
			SSmaptick_track.stop_tracking()
			message_admins("stop test")


/datum/maptick_menu/proc/load_test(test_id)
	var/datum/map_template/mapticktest/test_template = SSmapping.maptick_templates[test_id]
	if (!holder.mob)
		message_admins("you must be in a mob to do this!")
		return

	var/mob/client_mob = holder.mob
	test_template.load(locate(client_mob.x, client_mob.y, client_mob.z), TRUE)

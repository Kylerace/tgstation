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
	var/name = "Default-Test-Name"
	var/list/template_ids = list()
	var/current_template = null

/datum/maptick_menu/ui_state(mob/user)
	return GLOB.admin_state

/datum/maptick_menu/New(user)
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
	data["test_name"] = name
	data["standard_deviation"] = SSmaptick_track.standard_deviation

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
			SSmaptick_track.start_tracking(name)
			message_admins("[name] test has started")

		if("end test")
			SSmaptick_track.stop_tracking()
			message_admins(action)

		if("name test")
			name = params["new_name"]
			message_admins(name)

		if("start automove")
			apply_automove()
			message_admins(action)

		if("end automove")
			end_automove()
			message_admins(action)

		if("calculate sd")
			SSmaptick_track.calculate_standard_deviation()
			message_admins(action)


/datum/maptick_menu/proc/load_test(test_id)
	var/datum/map_template/mapticktest/test_template = SSmapping.maptick_templates[test_id]
	if (!holder.mob)
		message_admins("you must be in a mob to do this!")
		return

	var/mob/client_mob = holder.mob
	test_template.load(locate(client_mob.x, client_mob.y, client_mob.z), TRUE)

/datum/maptick_menu/proc/apply_automove()
	if (holder.mob)
		var/mob/client_mob = holder.mob
		client_mob.AddComponent(/datum/component/maptick_moving_tester)

/datum/maptick_menu/proc/end_automove()
	if (!holder.mob)
		message_admins("youre not in a mob! somehow")
		return
	var/mob/client_mob = holder.mob
	var/datum/component/maptick_moving_tester/to_remove = client_mob.GetComponent(/datum/component/maptick_moving_tester)
	qdel(to_remove)

/obj/item/maptick_test_generic
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	lefthand_file = 'icons/mob/inhands/misc/sheets_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/sheets_righthand.dmi'


/obj/item/maptick_test_invisible_overlay
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	lefthand_file = 'icons/mob/inhands/misc/sheets_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/sheets_righthand.dmi'
	var/image/invisible_overlay

/obj/item/maptick_test_invisible_overlay/Initialize()
	. = ..()
	overlays += image("")


/obj/item/maptick_test_speen_object
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	lefthand_file = 'icons/mob/inhands/misc/sheets_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/sheets_righthand.dmi'

/obj/item/maptick_test_speen_object/Initialize()
	. = ..()
	animate(src, transform = turn(matrix(), 120), time = 1, loop = -1)


/obj/item/maptick_test_invisible_obj_vis_overlay
	icon = ""
	var/image/visible_overlay

/obj/item/maptick_test_invisible_obj_vis_overlay/Initialize()
	. = ..()
	visible_overlay = icon("icons/obj/stack_objects.dmi", "sheet-metal")
	overlays += visible_overlay


//below is unused so far
/obj/item/maptick_test_invisible_obj_vis_vis_content //like above, but adds to vis_contents instead of overlays
	icon = ""
	var/obj/item/maptick_test_generic/ecksdee

/obj/item/maptick_test_invisible_obj_vis_vis_content/Initialize()
	. = ..()
	ecksdee = new()
	vis_contents += ecksdee

/obj/item/maptick_test_vis_contents_list_change_spam //spams the fuck out of vis contents changes
	icon = ""
	var/obj/item/maptick_test_generic/ecksdee

/obj/item/maptick_test_vis_contents_list_change_spam/Initialize()
	. = ..()
	addtimer(CALLBACK(src, .proc/toggle_vis_contents), 5)
	ecksdee = new()
	vis_contents += ecksdee

/obj/item/maptick_test_vis_contents_list_change_spam/proc/toggle_vis_contents()
	if (vis_contents.len > 1)
		vis_contents -= ecksdee
	else
		vis_contents += ecksdee
	addtimer(CALLBACK(src, .proc/toggle_vis_contents), 5)


/obj/item/maptick_test_static_vis_contents_stacking
	icon = ""
	var/obj/item/maptick_test_generic/ecksdee = new()

/obj/item/maptick_test_static_vis_contents_stacking/Initialize()
	. = ..()
	for(var/i=1, i < 50, i++)
		vis_contents += ecksdee


/obj/item/maptick_test_static_overlay_stacking
	icon = ""

/obj/item/maptick_test_static_overlay_stacking/Initialize()
	. = ..()
	for(var/i=0, i < 1, i++)
		overlays += getRandomAnimalImage(src)

/mob/maptick_test_static_mob
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	status_flags = null

/obj/item/maptick_test_completely_invis_object
	icon = ""

/turf/open/floor/maptick_test_changer_one
	icon_state = "wood"

/turf/open/floor/maptick_test_changer_one/Initialize(mapload)
	. = ..()
	if (baseturfs.len > 5)
		baseturfs.Cut(4,6)
	addtimer(CALLBACK(src, .proc/change_to_other), 5)

/turf/open/floor/maptick_test_changer_one/proc/change_to_other()
	ChangeTurf(/turf/open/floor/maptick_test_changer_two)

/turf/open/floor/maptick_test_changer_two
	icon = 'icons/turf/floors/glass.dmi'
	icon_state = "glass-0"

/turf/open/floor/maptick_test_changer_two/Initialize(mapload)
	. = ..()
	if (baseturfs.len > 5)
		baseturfs.Cut(4,6)
	addtimer(CALLBACK(src, .proc/change_to_other), 5)

/turf/open/floor/maptick_test_changer_two/proc/change_to_other()
	ChangeTurf(/turf/open/floor/maptick_test_changer_one)

/obj/structure/closet/maptick_test_infinite_closet
	storage_capacity = 300000000000

/datum/component/maptick_moving_tester
	var/mob/living/carbon/host
	var/going_north = TRUE

/datum/component/maptick_moving_tester/RegisterWithParent()
	. = ..()
	if(istype(parent, /mob/living/carbon))
		host = parent
		//RegisterSignal(host,COMSIG_MOVABLE_MOVED, .proc/prepare_move)
		addtimer(CALLBACK(src, .proc/prepare_move), 1)

/datum/component/maptick_moving_tester/UnregisterFromParent()
	. = ..()
	UnregisterSignal(host, COMSIG_MOVABLE_MOVED)

/datum/component/maptick_moving_tester/proc/prepare_move()
	if(going_north)
		if (host.y < 230)
			//addtimer(CALLBACK(src, .proc/change_to_other), 5)
			//actually_move(going_north)
			host.Move(get_step(get_turf(host),NORTH))
		else
			going_north = FALSE
	else
		if (host.y > 25)
			//actually_move(going_north)
			//host.Move(get_step(get_turf(host),SOUTH))
			host.Move(get_step(get_turf(host),SOUTH))
		else
			going_north = TRUE
	addtimer(CALLBACK(src, .proc/prepare_move), 1)

/datum/component/maptick_moving_tester/proc/actually_move(going_north)
	if (going_north)
		//walk(host, NORTH)
		host.Move(get_step(get_turf(host),NORTH))
	else
		//walk(host, SOUTH)
		host.Move(get_step(get_turf(host),SOUTH))

/turf/open/floor/maptick_test_turf_single_viscont
	icon_state = "wood"

/turf/open/floor/maptick_test_turf_single_viscont/Initialize(mapload)
	. = ..()
	var/obj/maptick_test_single_viscontent/vis_daddy = locate() in locate(1,1,1)
	if (!vis_daddy)
		vis_daddy = new(locate(1,1,1))

	vis_contents += vis_daddy

/obj/maptick_test_single_viscontent
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"

/obj/maptick_test_single_viscontent/Initialize(mapload)
	. = ..()
	icon = getRandomAnimalImage(src)


//control item
/obj/item/maptick_test_generic
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	lefthand_file = 'icons/mob/inhands/misc/sheets_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/sheets_righthand.dmi'

//generic items but with an invisible overlay
/obj/item/maptick_test_invisible_overlay
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	lefthand_file = 'icons/mob/inhands/misc/sheets_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/sheets_righthand.dmi'
	var/image/invisible_overlay

/obj/item/maptick_test_invisible_overlay/Initialize()
	. = ..()
	overlays += image("")

//to test constant animation's affect on maptick
/obj/item/maptick_test_speen_object
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	lefthand_file = 'icons/mob/inhands/misc/sheets_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/sheets_righthand.dmi'

/obj/item/maptick_test_speen_object/Initialize()
	. = ..()
	animate(src, transform = turn(matrix(), 120), time = 1, loop = -1)

//item is invisible but the overlay is visible, to test if that makes a difference (doesnt seem to)
/obj/item/maptick_test_invisible_obj_vis_overlay
	icon = ""
	var/image/visible_overlay

/obj/item/maptick_test_invisible_obj_vis_overlay/Initialize()
	. = ..()
	visible_overlay = icon("icons/obj/stack_objects.dmi", "sheet-metal")
	overlays += visible_overlay

//like above, but adds to vis_contents instead of overlays
/obj/item/maptick_test_invisible_obj_vis_vis_content
	icon = ""
	var/obj/item/maptick_test_generic/ecksdee

/obj/item/maptick_test_invisible_obj_vis_vis_content/Initialize()
	. = ..()
	ecksdee = new()
	vis_contents += ecksdee

//spams the fuck out of vis contents changes
/obj/item/maptick_test_vis_contents_list_change_spam
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"

/obj/item/maptick_test_vis_contents_list_change_spam/Initialize()
	. = ..()

	START_PROCESSING(SSobj, src)

/obj/item/maptick_test_vis_contents_list_change_spam/process()
	if (managed_overlays.len)
		for(var/obj/effect/overlay/vis/vs as anything in managed_overlays)
			SSvis_overlays.remove_vis_overlay(src, list(vs))
	else
		SSvis_overlays.add_vis_overlay(src, icon, icon_state, EMISSIVE_BLOCKER_LAYER, EMISSIVE_BLOCKER_PLANE, dir)

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
	var/going_north = TRUE

/datum/component/maptick_moving_tester/RegisterWithParent()
	. = ..()
	if(istype(parent, /mob/living/carbon))
		//RegisterSignal(host,COMSIG_MOVABLE_MOVED, .proc/prepare_move)
		//addtimer(CALLBACK(src, .proc/prepare_move), 1)
		START_PROCESSING(SSprojectiles, src)

/datum/component/maptick_moving_tester/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)

/datum/component/maptick_moving_tester/process()
	var/mob/living/carbon/parent_as_carbon = parent
	if(going_north)
		if (parent_as_carbon.y < 230)
			parent_as_carbon.Move(get_step(get_turf(parent_as_carbon),NORTH))
		else
			going_north = FALSE
	else
		if (parent_as_carbon.y > 25)
			parent_as_carbon.Move(get_step(get_turf(parent_as_carbon),SOUTH))
		else
			going_north = TRUE

//50 random animal overlays added to each turf
/turf/open/floor/maptick_test_turf_overlay
	name = "plating"
	icon_state = "plating"
	base_icon_state = "plating"

/turf/open/floor/maptick_test_turf_overlay/Initialize(mapload)
	. = ..()
	for (var/i in 1 to 50)
		overlays += getRandomAnimalImage(src)

/turf/open/floor/maptick_test_turf_vis_contents
	name = "plating"
	icon_state = "plating"
	base_icon_state = "plating"

/turf/open/floor/maptick_test_turf_vis_contents/Initialize(mapload)
	. = ..()
	for (var/i in 1 to 50)
		SSvis_overlays.add_vis_overlay(src, 'icons/obj/stack_objects.dmi', "sheet-metal", layer, plane, dir, unique = FALSE)

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

/obj/item/maptick_test_inside_contents_changing
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"

/obj/item/maptick_test_inside_contents_changing/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSprocessing, src)

/obj/item/maptick_test_inside_contents_changing/process()
	name = pick("lkajdsj", "aksjdhakjshd", "alijsdlkajs")
	if(prob(10))
		SSvis_overlays.add_vis_overlay(src, icon, icon_state, EMISSIVE_BLOCKER_LAYER, EMISSIVE_BLOCKER_PLANE, dir)
	else if (prob(20))
		overlays += getRandomAnimalImage(src)
	else
		if (managed_overlays.len)
			for(var/obj/effect/overlay/vis/vs as anything in managed_overlays)
				SSvis_overlays.remove_vis_overlay(src, list(vs))
		overlays.Cut()

//to test if changing contents inside mobs affect maptick, these have 100 objects each and they dont seem to matter at all
/mob/maptick_test_changing_object_vorerer
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"

/mob/maptick_test_changing_object_vorerer/Initialize()
	. = ..()
	for(var/i = 0, i < 100, i++)
		new /obj/item/maptick_test_inside_contents_changing(src)

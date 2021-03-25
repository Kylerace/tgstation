#ifdef MAPTICK_TESTING

///control item, also is the father of all maptick items so they dont get the emissive blockers by default
/obj/item/maptick_tester
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	blocks_emissive = FALSE

///father type of special turfs used for maptick testing
/turf/open/floor/maptick_tester
	icon_state = "wood"

///father type of mobs meant for testing maptick, only needed to toggle emissive blockers
/mob/maptick_tester
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	blocks_emissive = FALSE

///10 of the same overlay that doesnt change
/obj/item/maptick_tester/static_overlay_stacking

/obj/item/maptick_tester/static_overlay_stacking/Initialize()
	. = ..()
	for(var/i=0, i < 10, i++)
		var/image/to_add = image('icons/obj/stack_objects.dmi', src, "sheet-metal", layer, dir)
		overlays += to_add

///10 overlays with randomized vars to try to make as many unique appearances as possible
/obj/item/maptick_tester/randomized_overlay_stacking
	icon = ""

/obj/item/maptick_tester/randomized_overlay_stacking/Initialize()
	. = ..()
	for(var/i=0, i < 10, i++)
		var/image/to_add = image('icons/obj/stack_objects.dmi', src, pick(icon_states('icons/obj/stack_objects.dmi')), layer, dir, pixel_x = rand(-10,10), pixel_y = rand(-10,10))
		to_add.alpha = rand(240, 255)
		overlays += to_add

///like normal overlays except with the decal element (which uses a mutable_appearance) to see if that makes a difference at all
/obj/item/maptick_tester/mutable_appearance_overlays
	icon = ""

/obj/item/maptick_tester/mutable_appearance_overlays/Initialize()
	. = ..()
	for(var/i = 0, i < 10, i++)
		var/mutable_appearance/pic
		var/temp_image = image('icons/obj/stack_objects.dmi', null, icon_states('icons/obj/stack_objects.dmi')[i + 1], ABOVE_OBJ_LAYER, dir)
		pic = new(temp_image)
		overlays += pic


///spams the fuck out of vis contents changes
/obj/item/maptick_tester/vis_contents_list_change_spam

/obj/item/maptick_tester/vis_contents_list_change_spam/Initialize()
	. = ..()

	START_PROCESSING(SSfluids, src)

/obj/item/maptick_tester/vis_contents_list_change_spam/process()
	if (length(managed_overlays))
		SSvis_overlays.remove_vis_overlay(src, list(managed_overlays))
	else
		SSvis_overlays.add_vis_overlay(src, icon, icon_state, EMISSIVE_BLOCKER_LAYER, EMISSIVE_BLOCKER_PLANE, dir)

//generic items but with an invisible overlay
/obj/item/maptick_tester/invisible_overlay
	var/image/invisible_overlay

/obj/item/maptick_tester/invisible_overlay/Initialize()
	. = ..()
	overlays += image("")

///to test constant animation's affect on maptick
/obj/item/maptick_tester/speen_object

/obj/item/maptick_tester/speen_object/Initialize()
	. = ..()
	animate(src, transform = turn(matrix(), 120), time = 1, loop = -1)

///just a mob that doesnt move
/mob/maptick_tester/static_mob
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	status_flags = null
	blocks_emissive = FALSE //as opposed to EMISSIVE_BLOCK_UNIQUE

///like the maptick_tester object but is set to block emissives like normal items
/obj/item/maptick_tester/emissive_blocker
	blocks_emissive = EMISSIVE_BLOCK_GENERIC

///like the emissive_blocker object but has an overlay to block emissives instead of vis_contents
/obj/item/maptick_tester/emissive_blocker/overlay

/obj/item/maptick_tester/emissive_blocker/overlay/update_emissive_block()
	var/mutable_appearance/gen_emissive_blocker = mutable_appearance(icon, icon_state, EMISSIVE_BLOCKER_LAYER, EMISSIVE_BLOCKER_PLANE)
	gen_emissive_blocker.dir = dir
	gen_emissive_blocker.alpha = alpha
	gen_emissive_blocker.appearance_flags |= appearance_flags
	add_overlay(list(gen_emissive_blocker))

///completely invisible object to see if maptick is still affected by that
/obj/item/maptick_tester/completely_invis_object
	icon = ""

///changing turfs, they change to the other one every process
/turf/open/floor/maptick_tester/changer_one
	icon_state = "wood"

/turf/open/floor/maptick_tester/changer_one/Initialize(mapload)
	. = ..()
	if (baseturfs.len > 5)
		baseturfs.Cut(4,6)
	START_PROCESSING(SSstation, src)

/turf/open/floor/maptick_tester/changer_one/process()
	ChangeTurf(/turf/open/floor/maptick_tester/changer_two)

/turf/open/floor/maptick_tester/changer_two
	icon = 'icons/turf/floors/glass.dmi'
	icon_state = "glass-0"

/turf/open/floor/maptick_tester/changer_two/Initialize(mapload)
	. = ..()
	if (baseturfs.len > 5)
		baseturfs.Cut(4,6)
	START_PROCESSING(SSstation, src)

/turf/open/floor/maptick_tester/changer_two/process()
	ChangeTurf(/turf/open/floor/maptick_tester/changer_one)
///end of changing turfs

///for testing whether contents factor into maptick, put fucktons of objects into these and theyll swallow them up. also not dense so you can do moving tests
/obj/structure/closet/maptick_tester_infinite_closet
	storage_capacity = 300000000000
	density = FALSE

///automover, makes you move() up and down but doesnt let you see the edges of the z level (unless you have binoculars maybe)
/datum/component/maptick_moving_tester
	var/going_north = TRUE

/datum/component/maptick_moving_tester/RegisterWithParent()
	. = ..()
	if(istype(parent, /mob/living/carbon))
		//START_PROCESSING(SSfastprocess, src)
		automove()

/datum/component/maptick_moving_tester/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)

/datum/component/maptick_moving_tester/proc/automove()
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
	addtimer(CALLBACK(src, .proc/automove), 1)

///50 random animal overlays added to each turf
/turf/open/floor/maptick_tester/turf_overlay
	name = "plating"
	icon_state = "plating"
	base_icon_state = "plating"

/turf/open/floor/maptick_tester/turf_overlay/Initialize(mapload)
	. = ..()
	for (var/i in 1 to 50)
		overlays += getRandomAnimalImage(src)

///50 set vis_contents per turf, non unique
/turf/open/floor/maptick_tester/turf_vis_contents
	name = "plating"
	icon_state = "plating"
	base_icon_state = "plating"

/turf/open/floor/maptick_tester/turf_vis_contents/Initialize(mapload)
	. = ..()
	for (var/i in 1 to 50)
		SSvis_overlays.add_vis_overlay(src, 'icons/obj/stack_objects.dmi', "sheet-metal", layer, plane, dir, unique = TRUE)

///one single vis_overlay
/turf/open/floor/maptick_tester/turf_single_viscont
	icon_state = "wood"

/turf/open/floor/maptick_tester/turf_single_viscont/Initialize(mapload)
	. = ..()
	SSvis_overlays.add_vis_overlay(src, 'icons/obj/stack_objects.dmi', "sheet-metal", layer, plane, dir, unique = FALSE)

///item intended to be used as contents in something else, has its name and overlays and vis_contents changing
/obj/item/maptick_tester/inside_contents_changing
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"

/obj/item/maptick_tester/inside_contents_changing/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSprocessing, src)

/obj/item/maptick_tester/inside_contents_changing/process()
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

///to test if changing contents inside mobs affect maptick, these have 100 objects each and they dont seem to matter at all
/mob/maptick_tester/changing_object_vorerer
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"

/mob/maptick_tester/changing_object_vorerer/Initialize()
	. = ..()
	for(var/i = 0, i < 100, i++)
		new /obj/item/maptick_tester/inside_contents_changing(src)

///adds ten decal elements with a different icon_state for each
/turf/open/floor/maptick_tester/fake_decals_ten_stack
	icon_state = "wood"

/turf/open/floor/maptick_tester/fake_decals_ten_stack/Initialize(mapload)
	. = ..()
	var/list/decals_to_add = subtypesof(/obj/effect/turf_decal)
	for(var/i = 0, i < 10, i++)
		var/decal_type = decals_to_add[i + 1]
		new decal_type(src)

#endif

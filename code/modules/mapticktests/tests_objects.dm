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
		START_PROCESSING(SSfields, src)
		//automove()

/datum/component/maptick_moving_tester/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)

/datum/component/maptick_moving_tester/process()
	var/mob/living/carbon/parent_as_carbon = parent
	//var/add_delay = parent_as_carbon.cached_multiplicative_slowdown
	//if(old_move_delay + (add_delay*MOVEMENT_DELAY_BUFFER_DELTA) + MOVEMENT_DELAY_BUFFER > world.time)
	//	parent_as_carbon.move_delay = old_move_delay
	//else
	//	parent_as_carbon.move_delay = world.time
	parent_as_carbon.client.move_delay = world.time + world.tick_lag
	if(going_north)
		if (parent_as_carbon.y < 230)
			//parent_as_carbon.client.Move(get_step(get_turf(parent_as_carbon),NORTH))//get_step(get_turf(parent_as_carbon),NORTH)
			parent_as_carbon.client.keyDown("w")
		else
			going_north = FALSE
	else
		if (parent_as_carbon.y > 25)
			//parent_as_carbon.client.Move(get_step(get_turf(parent_as_carbon),SOUTH))
			parent_as_carbon.client.keyDown("s")
		else
			going_north = TRUE
	//addtimer(CALLBACK(src, .proc/automove), 1)

///50 random animal overlays added to each turf
/turf/open/floor/maptick_tester/turf_overlay
	name = "plating"
	icon_state = "plating"
	base_icon_state = "plating"

/turf/open/floor/maptick_tester/turf_overlay/Initialize(mapload)
	. = ..()
	for (var/i in 1 to 20)
		overlays += image('icons/obj/stack_objects.dmi', src, "sheet-metal", layer, dir)

///50 set vis_contents per turf, non unique
/turf/open/floor/maptick_tester/turf_vis_contents
	name = "plating"
	icon_state = "plating"
	base_icon_state = "plating"

/turf/open/floor/maptick_tester/turf_vis_contents/Initialize(mapload)
	. = ..()
	for (var/i in 1 to 20)
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

///i think this is completely unusable
/atom/maptick_atom_tester
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	density = FALSE
	plane = GAME_PLANE
	layer = OBJ_LAYER

/atom/movable/maptick_movable_tester
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	density = FALSE
	plane = GAME_PLANE
	layer = OBJ_LAYER

///gives itself a random layer between 1 and 20
/obj/item/maptick_tester/random_layer
	layer = OBJ_LAYER

/obj/item/maptick_tester/random_layer/Initialize()
	. = ..()
	layer = rand(1,20)

///gives itself a random plane between 1000 and 1000+number_of_planes
/obj/item/maptick_tester/random_plane
	plane = GAME_PLANE
	var/number_of_planes = 20

/obj/item/maptick_tester/random_plane/Initialize()
	. = ..()
	plane = rand(1000, 1000 + number_of_planes)

/obj/item/maptick_tester/image_deleter
	var/list/images_to_delete = list()
	var/delete_this_cycle = TRUE

/obj/item/maptick_tester/image_deleter/Initialize()
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/item/maptick_tester/image_deleter/process()
	if(delete_this_cycle)
		for(var/image/image_to_delete in images_to_delete)
			images_to_delete -= image_to_delete
			qdel(image_to_delete)
	else
		images_to_delete += image('icons/obj/stack_objects.dmi', loc, icon_states('icons/obj/stack_objects.dmi')[rand(1, icon_states('icons/obj/stack_objects.dmi').len)], ABOVE_OBJ_LAYER, dir)
	delete_this_cycle = !delete_this_cycle

/mob/living/carbon/human/species/skeleton/object_vorer

/mob/living/carbon/human/species/skeleton/object_vorer/Initialize()
	. = ..()
	for(var/i in 1 to 19950)
		var/obj/item/maptick_tester/to_spawn = new(src)

	START_PROCESSING(SSfluids, src)

/mob/living/carbon/human/species/skeleton/client_images_spammer/process()
	for(var/atom/movable/aties as anything in contents)
		aties.alpha = rand(0,255)

/mob/living/carbon/human/species/skeleton/objects_in_screen

/mob/living/carbon/human/species/skeleton/objects_in_screen/Login()
	. = ..()

	for(var/i in 1 to 19950)
		var/obj/item/maptick_tester/to_spawn = new()
		client.screen += to_spawn

/mob/living/carbon/human/species/skeleton/client_images_spammer

/mob/living/carbon/human/species/skeleton/client_images_spammer/Login()
	. = ..()
	for(var/i in 1 to 19950)
		var/image/immies = image('icons/obj/stack_objects.dmi', null, icon_states('icons/obj/stack_objects.dmi')[rand(1, icon_states('icons/obj/stack_objects.dmi').len)], ABOVE_OBJ_LAYER, dir)
		client.images += immies

/obj/item/maptick_tester/emissive_tester

/obj/item/maptick_tester/emissive_tester/Initialize()
	. = ..()
	overlays += mutable_appearance('icons/obj/stationobjs.dmi', "recharger-full", alpha = src.alpha)
	overlays += emissive_appearance('icons/obj/stationobjs.dmi', "recharger-full", alpha = src.alpha)

#endif

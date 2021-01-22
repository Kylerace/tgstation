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

/obj/item/maptick_test_invisible_obj_vis_vis_content
	icon = ""
	var/obj/item/maptick_test_generic/ecksdee

/obj/item/maptick_test_invisible_obj_vis_vis_content/Initialize()
	. = ..()
	ecksdee = new()
	vis_contents += ecksdee

/obj/item/maptick_test_vis_contents_list_change_spam
	icon = ""
	var/obj/item/maptick_test_generic/ecksdee

/obj/item/maptick_test_vis_contents_list_change_spam/Initialize()
	. = ..()
	addtimer(CALLBACK(src, .proc/toggle_vis_contents), 1)

/obj/item/maptick_test_vis_contents_list_change_spam/proc/toggle_vis_contents()
	if (vis_contents.len)
		vis_contents -= ecksdee
		qdel(ecksdee)
	else
		ecksdee = new()
		vis_contents += ecksdee

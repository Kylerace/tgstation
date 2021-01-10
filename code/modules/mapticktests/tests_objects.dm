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

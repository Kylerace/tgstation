/obj/structure/chair/e_chair
	name = "electric chair"
	desc = "Looks absolutely SHOCKING!"
	icon_state = "echair0"
	var/obj/item/assembly/shock_kit/part = null
	var/last_time = 1
	item_chair = null

/obj/structure/chair/e_chair/Initialize()
	. = ..()
	add_overlay(mutable_appearance('icons/obj/chairs.dmi', "echair_over", MOB_LAYER + 1))
	if(!part)
		part = new(src)
		part.master = src

/obj/structure/chair/e_chair/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		var/obj/structure/chair/C = new /obj/structure/chair(loc)
		W.play_tool_sound(src)
		C.setDir(dir)
		part.forceMove(loc)
		part.master = null
		part = null
		qdel(src)

/obj/structure/chair/e_chair/proc/shock()
	if(last_time + 50 > world.time)
		return
	last_time = world.time

	// special power handling
	var/area/A = get_area(src)
	if(!isarea(A))
		return
	if(!A.powered(AREA_USAGE_EQUIP))
		return
	A.use_power(AREA_USAGE_EQUIP, 5000)

	flick("echair_shock", src)
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(12, 1, src)
	s.start()
	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/buckled_mob = m
			buckled_mob.electrocute_act(85, src, 1)
			to_chat(buckled_mob, "<span class='userdanger'>You feel a deep shock course through your body!</span>")
			addtimer(CALLBACK(buckled_mob, /mob/living.proc/electrocute_act, 85, src, 1), 1)
	visible_message("<span class='danger'>The electric chair went off!</span>", "<span class='hear'>You hear a deep sharp shock!</span>")

/obj/structure/chair/e_chair/post_buckle_mob(mob/living/L)
	SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "dying", /datum/mood_event/deaths_door)

/obj/structure/chair/e_chair/post_unbuckle_mob(mob/living/L)
	SEND_SIGNAL(L, COMSIG_CLEAR_MOOD_EVENT, "dying")

/datum/component/electrified_chair
	///the chair that we are attached to
	var/obj/structure/chair/parent_chair
	///the shock kit attached to parent_chair
	var/obj/item/assembly/shock_kit/used_shock_kit
	///the mob buckled to parent_chair, if any
	var/mob/living/guinea_pig

/datum/component/electrified_chair/Initialize(obj/item/assembly/shock_kit/input_shock_kit)
	if(!istype(parent, /obj/structure/chair) || !istype(input_shock_kit, /obj/item/assembly/shock_kit))
		message_admins("incompatible")
		return COMPONENT_INCOMPATIBLE
	message_admins("compatible")
	parent_chair = parent
	used_shock_kit = input_shock_kit
	RegisterSignal(parent_chair, COMSIG_PARENT_PREQDELETED, .proc/unregister)
	RegisterSignal(used_shock_kit, COMSIG_PARENT_PREQDELETED, .proc/unregister)

	RegisterSignal(parent_chair, COMSIG_MOVABLE_BUCKLE, .proc/confirm_shockable)
	RegisterSignal(parent_chair, COMSIG_ATOM_EXIT, .proc/check_shock_kit)
	parent_chair.add_overlay(mutable_appearance('icons/obj/chairs.dmi', "echair_over", MOB_LAYER + 1))

/datum/component/electrified_chair/proc/unregister()
	SIGNAL_HANDLER
	//do all the shit related to deleting itself
	if(parent_chair)
		UnregisterSignal(parent_chair, list(COMSIG_PARENT_PREQDELETED, COMSIG_MOVABLE_BUCKLE, COMSIG_MOVABLE_UNBUCKLE, COMSIG_ATOM_EXIT))
	if(used_shock_kit)
		UnregisterSignal(used_shock_kit, list(COMSIG_PARENT_PREQDELETED))
	if(guinea_pig)
		UnregisterSignal(guinea_pig, list(COMSIG_PARENT_PREQDELETED))
	parent_chair = null
	used_shock_kit = null
	guinea_pig  = null

	qdel(src)

/datum/component/electrified_chair/proc/nullify_guinea_pig()
	SIGNAL_HANDLER
	message_admins("null gp")
	UnregisterSignal(guinea_pig, COMSIG_PARENT_PREQDELETED)
	UnregisterSignal(parent_chair, COMSIG_MOVABLE_UNBUCKLE)
	guinea_pig = null
	//the next time the timer calls the shocking proc it will bail when guinea_pig is null

/datum/component/electrified_chair/proc/check_shock_kit(datum/source, atom/movable/AM, atom/newLoc)
	SIGNAL_HANDLER
	if(used_shock_kit == AM && newLoc != parent_chair)
		message_admins("no more shock kit")
		unregister()

/datum/component/electrified_chair/proc/confirm_shockable(datum/source, mob/living/mob_to_buckle, _force)
	SIGNAL_HANDLER
	if(!istype(mob_to_buckle))
		message_admins("not shockable")
		return
	guinea_pig = mob_to_buckle
	RegisterSignal(guinea_pig, COMSIG_PARENT_PREQDELETED, .proc/nullify_guinea_pig)
	RegisterSignal(parent_chair, COMSIG_MOVABLE_UNBUCKLE, .proc/nullify_guinea_pig)
	addtimer(CALLBACK(src, .proc/shock_guinea_pig), 5 SECONDS)
	message_admins("confirm shockable")

/datum/component/electrified_chair/proc/shock_guinea_pig()
	if(!guinea_pig)
		message_admins("no shock")
		return
	message_admins("shock guinea pig")

	//flick("echair_shock", parent_chair)
	var/turf/our_turf = get_turf(parent_chair)
	var/obj/structure/cable/live_cable = our_turf.get_cable_node()
	if(!live_cable)
		return

	if(parent_chair.has_buckled_mobs())
		for(var/m in parent_chair.buckled_mobs)
			var/mob/living/buckled_mob = m
			buckled_mob.electrocute_act(85, parent_chair, 1)
			to_chat(buckled_mob, "<span class='userdanger'>You feel a deep shock course through your body!</span>")

			//addtimer(CALLBACK(buckled_mob, /mob/living/proc/electrocute_act, 85, parent_chair, 1), 1)
	parent_chair.visible_message("<span class='danger'>The electric chair went off!</span>", "<span class='hear'>You hear a deep sharp shock!</span>")
	addtimer(CALLBACK(src, .proc/shock_guinea_pig), 5 SECONDS)


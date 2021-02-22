/obj/structure/chair/e_chair
	name = "electric chair"
	desc = "Looks absolutely SHOCKING!"
	icon_state = "echair0"
	//var/obj/item/assembly/shock_kit/part = null
	var/last_time = 1
	item_chair = null

/obj/structure/chair/e_chair/Initialize()
	. = ..()
	add_overlay(mutable_appearance('icons/obj/chairs.dmi', "echair_over", MOB_LAYER + 1))
	if(!stored_kit)
		stored_kit = new(src)
		stored_kit.master = src
		AddComponent(/datum/component/electrified_chair, stored_kit)

/obj/structure/chair/e_chair/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WRENCH)
		var/obj/structure/chair/C = new /obj/structure/chair(loc)
		W.play_tool_sound(src)
		C.setDir(dir)
		stored_kit.forceMove(loc)
		stored_kit.master = null
		stored_kit = null
		qdel(src)


/datum/component/electrified_chair
	///the chair that we are attached to
	var/obj/structure/chair/parent_chair
	///the shock kit attached to parent_chair
	var/obj/item/assembly/shock_kit/used_shock_kit
	///the mob buckled to parent_chair, if any
	var/mob/living/guinea_pig
	///the guinea pig can only be shocked if this reaches 5 seconds
	var/time_since_last_shock = 0

/datum/component/electrified_chair/Initialize(obj/item/assembly/shock_kit/input_shock_kit)
	if(!istype(parent, /obj/structure/chair) || !istype(input_shock_kit, /obj/item/assembly/shock_kit))
		return COMPONENT_INCOMPATIBLE
	parent_chair = parent
	used_shock_kit = input_shock_kit
	RegisterSignal(parent_chair, COMSIG_PARENT_PREQDELETED, .proc/UnregisterFromParent)
	RegisterSignal(used_shock_kit, COMSIG_PARENT_PREQDELETED, .proc/UnregisterFromParent)

	RegisterSignal(parent_chair, COMSIG_MOVABLE_BUCKLE, .proc/on_buckle)
	RegisterSignal(parent_chair, COMSIG_ATOM_EXIT, .proc/check_shock_kit)
	parent_chair.add_overlay(mutable_appearance('icons/obj/chairs.dmi', "echair_over", MOB_LAYER + 1))

	if(parent_chair.has_buckled_mobs())
		for(var/m in parent_chair.buckled_mobs)
			var/mob/living/possible_guinea_pig = m
			if(on_buckle(src, possible_guinea_pig, FALSE))
				break

/datum/component/electrified_chair/UnregisterFromParent()
	SIGNAL_HANDLER

	if(parent_chair)
		UnregisterSignal(parent_chair, list(COMSIG_PARENT_PREQDELETED, COMSIG_MOVABLE_BUCKLE, COMSIG_MOVABLE_UNBUCKLE, COMSIG_ATOM_EXIT))
	if(used_shock_kit)
		UnregisterSignal(used_shock_kit, list(COMSIG_PARENT_PREQDELETED))
	if(guinea_pig)
		UnregisterSignal(guinea_pig, list(COMSIG_PARENT_PREQDELETED))
	parent_chair = null
	used_shock_kit = null
	guinea_pig  = null
	STOP_PROCESSING(SSprocessing, src)

	qdel(src)

///checks if the shock kit connected to parent is still there and unregisters if it isnt
/datum/component/electrified_chair/proc/check_shock_kit(datum/source, atom/movable/AM, atom/newLoc)
	SIGNAL_HANDLER
	if(used_shock_kit == AM && newLoc != parent_chair)
		UnregisterFromParent()

/datum/component/electrified_chair/proc/on_buckle(datum/source, mob/living/mob_to_buckle, _force)
	SIGNAL_HANDLER
	. = FALSE
	if(!istype(mob_to_buckle) || guinea_pig)
		return
	guinea_pig = mob_to_buckle
	RegisterSignal(guinea_pig, COMSIG_PARENT_PREQDELETED, .proc/nullify_guinea_pig)
	RegisterSignal(parent_chair, COMSIG_MOVABLE_UNBUCKLE, .proc/nullify_guinea_pig)
	START_PROCESSING(SSprocessing, src)
	return TRUE

///for whatever reason the guinea pig is gone so we cant shock them anymore
/datum/component/electrified_chair/proc/nullify_guinea_pig()
	SIGNAL_HANDLER
	UnregisterSignal(guinea_pig, COMSIG_PARENT_PREQDELETED)
	UnregisterSignal(parent_chair, COMSIG_MOVABLE_UNBUCKLE)
	guinea_pig = null
	STOP_PROCESSING(SSprocessing, src)

///where the guinea pig is actually shocked if possible
/datum/component/electrified_chair/process(delta_time)
	if(QDELETED(guinea_pig) || QDELETED(used_shock_kit) || QDELETED(parent_chair))
		time_since_last_shock = 0
		return PROCESS_KILL

	if(time_since_last_shock < 5)
		time_since_last_shock += delta_time
		return
	time_since_last_shock = 0

	var/turf/our_turf = get_turf(parent_chair)
	var/obj/structure/cable/live_cable = our_turf.get_cable_node()

	if(parent_chair.has_buckled_mobs() && guinea_pig in parent_chair.buckled_mobs)
		if(!live_cable || !live_cable.powernet || live_cable.powernet.avail < 10)
			return
		var/shock_damage = round(live_cable.powernet.avail/5000)
		guinea_pig.electrocute_act(shock_damage, parent_chair, 1)
		to_chat(guinea_pig, "<span class='userdanger'>You feel a deep shock course through your body!</span>")
	else
		nullify_guinea_pig()
		time_since_last_shock = 0
		return PROCESS_KILL

	parent_chair.visible_message("<span class='danger'>The electric chair went off!</span>", "<span class='hear'>You hear a deep sharp shock!</span>")

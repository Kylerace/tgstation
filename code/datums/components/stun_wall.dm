//applies a fake airlock overlay
/datum/component/stun_wall
    var/overlay

/datum/component/stun_wall/Initialize(turf/closed/wall/wall)
	if(!istype(wall))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(wall, COMSIG_ATOM_BUMPED, PROC_REF(on_bump))
	RegisterSignal(wall, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_clean))
	overlay = mutable_appearance('icons/turf/walls/airlock.dmi', "closed")
	wall.add_overlay(overlay)

/datum/component/stun_wall/Destroy()
	var/turf/closed/wall/wall = parent
	wall.cut_overlay(overlay)
	return ..()

/datum/component/stun_wall/proc/on_bump(datum/source, atom/bumped_atom)
	if(!istype(bumped_atom,/mob/living/carbon/human))
		return
	var/mob/living/carbon/human/H = bumped_atom
	H.Stun(5)
	H.visible_message(span_warning("[H] bumps into [source] and gets stunned!"))

/datum/component/stun_wall/proc/on_clean(datum/source)
	qdel(src)

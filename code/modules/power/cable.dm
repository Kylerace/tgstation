//Use this only for things that aren't a subtype of obj/machinery/power
//For things that are, override "should_have_node()" on them
GLOBAL_LIST_INIT(wire_node_generating_types, typecacheof(list(/obj/structure/grille)))

#define UNDER_SMES -1
#define UNDER_TERMINAL 1

/turf
	var/list/graph_nodes

///class to handle the concept of connecting to other nodes in a graph
/datum/node
	///what connections this node has to other nodes. by default this assumes bidirectional connections.
	///if you want a weighted and/or directed graph, youll need to override the class
	var/list/connected_nodes

/datum/node/New()
	. = ..()

/datum/node/Destroy(force, ...)
	. = ..()
	for(var/datum/node/connected_node in connections)
		disconnect(connected_node)
	on_connection_change()

/datum/node/proc/find_connections()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("called unimplemented stub proc for the base null class! you need to override it!")

///
/datum/node/proc/can_connect_with(datum/node/potential_connection)
	return TRUE //TODOKYLER: probably introduce some typechecking support

///create a bidirectional connection between us and another node
/datum/node/proc/connect(datum/node/new_connection)
	LAZYOR(connected_nodes, new_connection)
	LAZYOR(new_connection.connected_nodes, src)

///severs the (by default) bidirectional connection between us and another node
/datum/node/proc/disconnect(datum/node/gone)
	LAZYREMOVE(connected_nodes, gone)
	LAZYREMOVE(gone.connected_nodes, src)

///react to a change in our connected graph list
/datum/node/proc/on_connection_change(list/newly_connected)
	SHOULD_CALL_PARENT(FALSE)
	return

/datum/node/proc/unassociate_with_representative()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("called unimplemented stub!")

/datum/node/proc/associate_with_representative()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("called unimplemented stub!")

///finds the nodes/node holders we should be polling for connections
/datum/node/proc/find_near()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("called unimplemented stub!")

///a node that represents something on the map and its connections to other similar things on the map
/datum/node/map
	var/atom/movable/representative
	var/turf/associated_loc
	var/connected_dirs

/datum/node/map/New(atom/movable/new_representative, turf/associated_loc, ...)
	if(!new_representative || !associated_loc)
		qdel(src)
		return FALSE

	associate_with_representative(new_representative, args.Copy(3))
	associate_with_turf(associated_loc)

	. = ..()

/datum/node/map/Destroy(force, ...)
	. = ..()
	unassociate_with_representative()
	unassociate_with_turf()

/datum/node/map/proc/associate_with_turf(turf/new_turf)
	associated_loc = new_turf
	LAZYADD(new_turf.graph_nodes, src)

/datum/node/map/proc/unassociate_with_turf(turf/old_turf)
	associated_loc = null
	LAZYREMOVE(old_turf.graph_nodes, src)

/datum/node/map/associate_with_representative(atom/movable/new_representative, ...)
	RegisterSignal(new_representative, COMSIG_PARENT_QDELETING, .proc/unassociate_with_representative)
	inherit_parameters(arglist(args.Copy(2)))

/datum/node/map/unassociate_with_representative()
	SIGNAL_HANDLER

	UnregisterSignal(representative, COMSIG_PARENT_QDELETING)
	if(!QDELETED(representative))
		re_place_representative()
	representative = null

/datum/node/map/find_connections()
	for(var/turf/adjacent_turf in find_near())

		var/list/new_connections = list()
		for(var/datum/node/other_undertile as anything in adjacent_turf.graph_nodes)
			if(can_connect_with(other_undertile))
				connect(other_undertile)
				new_connections += other_undertile

		on_connection_change(new_connections)

/datum/node/map/can_connect_with(datum/node/map/new_node)
	return (get_dist(associated_loc, new_node.associated_loc) == 1) && (associated_loc.z == new_node.associated_loc.z)//adjacent

/datum/node/map/find_near()
	return list(get_step(associated_loc, NORTH),
		get_step(associated_loc, SOUTH),
		get_step(associated_loc, EAST),
		get_step(associated_loc, WEST),
		)

/datum/node/map/connect(datum/node/map/new_node)
	. = ..()
	dirs |= get_dir(associated_loc, new_node.associated_loc)

/datum/node/map/disconnect(datum/node/map/old_node)
	. = ..()
	dirs &= get_dir(associated_loc, new_node.associated_loc)

/datum/node/map/on_connection_change()
	representative.update_appearance()

///take whatever vars we need from our representative when we're first associated with them.
///define what vars youre inheriting in the arguments for overrides, if you get them wrong they will runtime
/datum/node/map/proc/inherit_parameters()
	SHOULD_CALL_PARENT(FALSE)
	return FALSE //stub

///a mapped node that nullspaces its representative when its turf covers it. made for maptick reasons.
///a critical design goal of these is that theyre supposed to be used for almost all behavior,
///the representatives of this datum should by and large do nothing except functionality that deal with its singular existence
///any system that deals with the concept of "x set of connected things" should explicitely deal with THIS datum
///that way nothing can confusedly try to make the representative do something in nullspace that breaks the assumptions
///of the pure and innocent (but clueless) coder who made that functionality. essentially, we need to hide the fact that
///undertiles managed by this datum have two locs for optimization purposes
/datum/node/map/undertile_manager
	var/is_nullspaced = FALSE

	var/del_without_representative = TRUE

	var/add_overlay_when_nullspaced = TRUE
	var/image/nullspace_overlay
	///exact copy of
	var/image/visible_overlay

/datum/node/map/undertile_manager/New(atom/movable/new_representative, turf/associated_loc, ...)
	. = ..()

/datum/node/map/undertile_manager/Destroy(force, ...)
	. = ..()

/datum/node/proc/on_cover_changed(datum/source, underfloor_accessibility, list/uncovered_objects)
	SIGNAL_HANDLER
	if(is_nullspaced)
		switch(underfloor_accessibility)
			if(UNDERFLOOR_HIDDEN)
				associated_loc.vis_contents -= representative
				//associated_loc.overlays -= nullspace_overlay

			if(UNDERFLOOR_VISIBLE)
				associated_loc.vis_contents += representative

			if(UNDERFLOOR_INTERACTABLE)
				associated_loc.vis_contents -= representative
				re_place_representative()
				uncovered_objects += representative

	else
		switch(underfloor_accessibility)
			if(UNDERFLOOR_HIDDEN)
				nullspace_representative()

			if(UNDERFLOOR_VISIBLE)
				nullspace_representative()
				associated_loc.vis_contents += representative

/datum/node/map/undertile_manager/proc/nullspace_representative()
	SIGNAL_HANDLER
	representative.abstract_move(null)//should probably just directly do loc = null
	is_nullspaced = TRUE

/datum/node/map/undertile_manager/proc/re_place_representative()
	SIGNAL_HANDLER
	representative.abstract_move(associated_loc)
	is_nullspaced = FALSE

/datum/node/map/undertile_manager/associate_with_turf(turf/new_turf)
	. = ..()
	RegisterSignal(new_turf, COMSIG_TURF_COVER, .proc/on_cover_changed)

/datum/node/map/undertile_manager/unassociate_with_turf(turf/old_turf)
	UnregisterSignal(old_turf, COMSIG_TURF_COVER)
	. = ..()

/datum/node/map/undertile_manager/unassociate_with_representative()
	if(!QDELETED(representative))
		re_place_representative()
	. = ..()

/datum/node/map/undertile_manager/associate_with_representative(atom/movable/new_representative, list/additional_args)
	. = ..()

/datum/node/map/undertile_manager/cable
	var/datum/powernet/powernet
	var/node = FALSE //used for sprites display
	var/cable_layer = CABLE_LAYER_2 //bitflag

/datum/node/map/undertile_manager/inherit_parameters()

///////////////////////////////
//CABLE STRUCTURE
///////////////////////////////
////////////////////////////////
// Definitions
////////////////////////////////
/obj/structure/cable
	name = "power cable"
	desc = "A flexible, superconducting insulated cable for heavy-duty power transfer."
	icon = 'icons/obj/power_cond/layer_cable.dmi'
	icon_state = "l2-1-2-4-8-node"
	color = "yellow"
	layer = WIRE_LAYER //Above hidden pipes, GAS_PIPE_HIDDEN_LAYER
	anchored = TRUE
	obj_flags = CAN_BE_HIT | ON_BLUEPRINTS
	var/linked_dirs = 0 //bitflag
	var/node = FALSE //used for sprites display
	var/cable_layer = CABLE_LAYER_2 //bitflag
	var/machinery_layer = MACHINERY_LAYER_1 //bitflag
	var/datum/powernet/powernet

/obj/structure/cable/layer1
	color = "red"
	cable_layer = CABLE_LAYER_1
	machinery_layer = null
	layer = WIRE_LAYER - 0.01
	icon_state = "l1-1-2-4-8-node"

/obj/structure/cable/layer3
	color = "blue"
	cable_layer = CABLE_LAYER_3
	machinery_layer = null
	layer = WIRE_LAYER + 0.01
	icon_state = "l4-1-2-4-8-node"

/obj/structure/cable/Initialize(mapload)
	. = ..()

	GLOB.cable_list += src //add it to the global cable list
	Connect_cable()
	AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE)
	RegisterSignal(src, COMSIG_RAT_INTERACT, .proc/on_rat_eat)

/obj/structure/cable/proc/on_rat_eat(datum/source, mob/living/simple_animal/hostile/regalrat/king)
	SIGNAL_HANDLER

	if(avail())
		king.apply_damage(10)
		playsound(king, 'sound/effects/sparks2.ogg', 100, TRUE)
	deconstruct()

///Set the linked indicator bitflags
/obj/structure/cable/proc/Connect_cable(clear_before_updating = FALSE)
	var/under_thing = NONE
	if(clear_before_updating)
		linked_dirs = 0
	var/obj/machinery/power/search_parent
	for(var/obj/machinery/power/P in loc)
		if(istype(P, /obj/machinery/power/terminal))
			under_thing = UNDER_TERMINAL
			search_parent = P
			break
		if(istype(P, /obj/machinery/power/smes))
			under_thing = UNDER_SMES
			search_parent = P
			break
	for(var/check_dir in GLOB.cardinals)
		var/TB = get_step(src, check_dir)
		//don't link from smes to its terminal
		if(under_thing)
			switch(under_thing)
				if(UNDER_SMES)
					var/obj/machinery/power/terminal/term = locate(/obj/machinery/power/terminal) in TB
					//Why null or equal to the search parent?
					//during map init it's possible for a placed smes terminal to not have initialized to the smes yet
					//but the cable underneath it is ready to link.
					//I don't believe null is even a valid state for a smes terminal while the game is actually running
					//So in the rare case that this happens, we also shouldn't connect
					//This might break.
					if(term && (!term.master || term.master == search_parent))
						continue
				if(UNDER_TERMINAL)
					var/obj/machinery/power/smes/S = locate(/obj/machinery/power/smes) in TB
					if(S && (!S.terminal || S.terminal == search_parent))
						continue
		var/inverse = turn(check_dir, 180)
		for(var/obj/structure/cable/C in TB)
			if(C.cable_layer & cable_layer)
				linked_dirs |= check_dir
				C.linked_dirs |= inverse
				C.update_appearance()

	update_appearance()

///Clear the linked indicator bitflags
/obj/structure/cable/proc/Disconnect_cable()
	for(var/check_dir in GLOB.cardinals)
		var/inverse = turn(check_dir, 180)
		if(linked_dirs & check_dir)
			var/TB = get_step(loc, check_dir)
			for(var/obj/structure/cable/C in TB)
				if(cable_layer & C.cable_layer)
					C.linked_dirs &= ~inverse
					C.update_appearance()

/obj/structure/cable/Destroy() // called when a cable is deleted
	Disconnect_cable()

	if(powernet)
		cut_cable_from_powernet() // update the powernets
	GLOB.cable_list -= src //remove it from global cable list

	return ..() // then go ahead and delete the cable

/obj/structure/cable/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/cable_coil(drop_location(), 1)
	qdel(src)

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/structure/cable/update_icon_state()
	if(!linked_dirs)
		icon_state = "l[cable_layer]-noconnection"
		return ..()

	var/list/dir_icon_list = list()
	for(var/check_dir in GLOB.cardinals)
		if(linked_dirs & check_dir)
			dir_icon_list += "[check_dir]"
	var/dir_string = dir_icon_list.Join("-")
	if(dir_icon_list.len > 1)
		for(var/obj/O in loc)
			if(GLOB.wire_node_generating_types[O.type])
				dir_string = "[dir_string]-node"
				break
			else if(istype(O, /obj/machinery/power))
				var/obj/machinery/power/P = O
				if(P.should_have_node())
					dir_string = "[dir_string]-node"
					break
	dir_string = "l[cable_layer]-[dir_string]"
	icon_state = dir_string
	return ..()


/obj/structure/cable/examine(mob/user)
	. = ..()
	if(isobserver(user))
		. += get_power_info()


/obj/structure/cable/proc/handlecable(obj/item/W, mob/user, params)
	var/turf/T = get_turf(src)
	if(T.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return
	if(W.tool_behaviour == TOOL_WIRECUTTER)
		if (shock(user, 50))
			return
		user.visible_message(span_notice("[user] cuts the cable."), span_notice("You cut the cable."))
		investigate_log("was cut by [key_name(usr)] in [AREACOORD(src)]", INVESTIGATE_WIRES)
		deconstruct()
		return

	else if(W.tool_behaviour == TOOL_MULTITOOL)
		to_chat(user, get_power_info())
		shock(user, 5, 0.2)

	add_fingerprint(user)


/obj/structure/cable/proc/get_power_info()
	if(powernet?.avail > 0)
		return span_danger("Total power: [display_power(powernet.avail)]\nLoad: [display_power(powernet.load)]\nExcess power: [display_power(surplus())]")
	else
		return span_danger("The cable is not powered.")


// Items usable on a cable :
//   - Wirecutters : cut it duh !
//   - Multitool : get the power currently passing through the cable
//
/obj/structure/cable/attackby(obj/item/W, mob/user, params)
	handlecable(W, user, params)


// shock the user with probability prb
/obj/structure/cable/proc/shock(mob/user, prb, siemens_coeff = 1)
	if(!prob(prb))
		return FALSE
	if(electrocute_mob(user, powernet, src, siemens_coeff))
		do_sparks(5, TRUE, src)
		return TRUE
	else
		return FALSE

/obj/structure/cable/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

////////////////////////////////////////////
// Power related
///////////////////////////////////////////

// All power generation handled in add_avail()
// Machines should use add_load(), surplus(), avail()
// Non-machines should use add_delayedload(), delayed_surplus(), newavail()

/obj/structure/cable/proc/add_avail(amount)
	if(powernet)
		powernet.newavail += amount

/obj/structure/cable/proc/add_load(amount)
	if(powernet)
		powernet.load += amount

/obj/structure/cable/proc/surplus()
	if(powernet)
		return clamp(powernet.avail-powernet.load, 0, powernet.avail)
	else
		return 0

/obj/structure/cable/proc/avail(amount)
	if(powernet)
		return amount ? powernet.avail >= amount : powernet.avail
	else
		return 0

/obj/structure/cable/proc/add_delayedload(amount)
	if(powernet)
		powernet.delayedload += amount

/obj/structure/cable/proc/delayed_surplus()
	if(powernet)
		return clamp(powernet.newavail - powernet.delayedload, 0, powernet.newavail)
	else
		return 0

/obj/structure/cable/proc/newavail()
	if(powernet)
		return powernet.newavail
	else
		return 0

/////////////////////////////////////////////////
// Cable laying helpers
////////////////////////////////////////////////

// merge with the powernets of power objects in the given direction
/obj/structure/cable/proc/mergeConnectedNetworks(direction)

	var/inverse_dir = (!direction)? 0 : turn(direction, 180) //flip the direction, to match with the source position on its turf

	var/turf/TB = get_step(src, direction)

	for(var/obj/structure/cable/C in TB)
		if(!C)
			continue

		if(src == C)
			continue

		if(!(cable_layer & C.cable_layer))
			continue

		if(C.linked_dirs & inverse_dir) //we've got a matching cable in the neighbor turf
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_cable(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet, C.powernet)
			else
				C.powernet.add_cable(src) //else, we simply connect to the matching cable powernet

// merge with the powernets of power objects in the source turf
/obj/structure/cable/proc/mergeConnectedNetworksOnTurf()
	var/list/to_connect = list()
	node = FALSE

	if(!powernet) //if we somehow have no powernet, make one (should not happen for cables)
		var/datum/powernet/newPN = new()
		newPN.add_cable(src)

	//first let's add turf cables to our powernet
	//then we'll connect machines on turf where a cable is present
	for(var/atom/movable/AM in loc)
		if(istype(AM, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/N = AM
			if(!N.terminal)
				continue // APC are connected through their terminal

			if(N.terminal.powernet == powernet) //already connected
				continue

			to_connect += N.terminal //we'll connect the machines after all cables are merged

		else if(istype(AM, /obj/machinery/power)) //other power machines
			var/obj/machinery/power/M = AM

			if(M.powernet == powernet)
				continue

			to_connect += M //we'll connect the machines after all cables are merged

	//now that cables are done, let's connect found machines
	for(var/obj/machinery/power/PM in to_connect)
		node = TRUE
		if(!PM.connect_to_network())
			PM.disconnect_from_network() //if we somehow can't connect the machine to the new powernet, remove it from the old nonetheless

//////////////////////////////////////////////
// Powernets handling helpers
//////////////////////////////////////////////

/obj/structure/cable/proc/get_cable_connections(powernetless_only)
	. = list()
	var/turf/T = get_turf(src)
	for(var/check_dir in GLOB.cardinals)
		if(linked_dirs & check_dir)
			T = get_step(src, check_dir)
			for(var/obj/structure/cable/C in T)
				if(cable_layer & C.cable_layer)
					. += C

/obj/structure/cable/proc/get_all_cable_connections(powernetless_only)
	. = list()
	var/turf/T
	for(var/check_dir in GLOB.cardinals)
		T = get_step(src, check_dir)
		for(var/obj/structure/cable/C in T.contents - src)
			. += C

/obj/structure/cable/proc/get_machine_connections(powernetless_only)
	. = list()
	for(var/obj/machinery/power/P in get_turf(src))
		if(!powernetless_only || !P.powernet)
			if(P.anchored)
				. += P

/obj/structure/cable/proc/auto_propagate_cut_cable(obj/O)
	if(O && !QDELETED(O))
		var/datum/powernet/newPN = new()// creates a new powernet...
		propagate_network(O, newPN)//... and propagates it to the other side of the cable

//Makes a new network for the cable and propgates it. If we already have one, just die
/obj/structure/cable/proc/propagate_if_no_network()
	if(powernet)
		return
	var/datum/powernet/newPN = new()
	propagate_network(src, newPN)

// cut the cable's powernet at this cable and updates the powergrid
/obj/structure/cable/proc/cut_cable_from_powernet(remove = TRUE)
	if(!powernet)
		return

	var/turf/T1 = loc
	if(!T1)
		return

	//clear the powernet of any machines on tile first
	for(var/obj/machinery/power/P in T1)
		P.disconnect_from_network()

	var/list/P_list = list()
	for(var/dir_check in GLOB.cardinals)
		if(linked_dirs & dir_check)
			T1 = get_step(loc, dir_check)
			P_list += locate(/obj/structure/cable) in T1

	// remove the cut cable from its turf and powernet, so that it doesn't get count in propagate_network worklist
	if(remove)
		moveToNullspace()
	powernet.remove_cable(src) //remove the cut cable from its powernet

	var/first = TRUE
	for(var/obj/O in P_list)
		if(first)
			first = FALSE
			continue
		addtimer(CALLBACK(O, .proc/auto_propagate_cut_cable, O), 0) //so we don't rebuild the network X times when singulo/explosion destroys a line of X cables

///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

#define CABLE_RESTRAINTS_COST 15

/obj/item/stack/cable_coil
	name = "cable coil"
	custom_price = PAYCHECK_LOWER * 0.8
	gender = NEUTER //That's a cable coil sounds better than that's some cable coils
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	inhand_icon_state = "coil"
	base_icon_state = "coil"
	novariants = FALSE
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	max_amount = MAXCOIL
	amount = MAXCOIL
	merge_type = /obj/item/stack/cable_coil // This is here to let its children merge between themselves
	color = "yellow"
	desc = "A coil of insulated power cable."
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 3
	throw_range = 5
	mats_per_unit = list(/datum/material/iron=10, /datum/material/glass=5)
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("whips", "lashes", "disciplines", "flogs")
	attack_verb_simple = list("whip", "lash", "discipline", "flog")
	singular_name = "cable piece"
	full_w_class = WEIGHT_CLASS_SMALL
	grind_results = list(/datum/reagent/copper = 2) //2 copper per cable in the coil
	usesound = 'sound/items/deconstruct.ogg'
	cost = 1
	source = /datum/robot_energy_storage/wire
	var/cable_color = "yellow"
	var/obj/structure/cable/target_type = /obj/structure/cable
	var/target_layer = CABLE_LAYER_2

/obj/item/stack/cable_coil/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	. = ..()
	pixel_x = base_pixel_x + rand(-2, 2)
	pixel_y = base_pixel_y + rand(-2, 2)
	update_appearance()

/obj/item/stack/cable_coil/examine(mob/user)
	. = ..()
	. += "<b>Ctrl+Click</b> to change the layer you are placing on."

/obj/item/stack/cable_coil/update_name()
	. = ..()
	name = "cable [(amount < 3) ? "piece" : "coil"]"

/obj/item/stack/cable_coil/update_desc()
	. = ..()
	desc = "A [(amount < 3) ? "piece" : "coil"] of insulated power cable."

/obj/item/stack/cable_coil/update_icon_state()
	if(novariants)
		return
	. = ..()
	icon_state = "[base_icon_state][amount < 3 ? amount : ""]"

/obj/item/stack/cable_coil/suicide_act(mob/user)
	if(locate(/obj/structure/chair/stool) in get_turf(user))
		user.visible_message(span_suicide("[user] is making a noose with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	else
		user.visible_message(span_suicide("[user] is strangling [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return(OXYLOSS)

/obj/item/stack/cable_coil/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/stack/cable_coil/attack_self(mob/living/user)
	if(!user)
		return

	var/image/restraints_icon = image(icon = 'icons/obj/restraints.dmi', icon_state = "cuff")
	restraints_icon.maptext = MAPTEXT("<span [amount >= CABLE_RESTRAINTS_COST ? "" : "style='color: red'"]>[CABLE_RESTRAINTS_COST]</span>")

	var/list/radial_menu = list(
	"Layer 1" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-red"),
	"Layer 2" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-yellow"),
	"Layer 3" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-blue"),
	"Multilayer cable hub" = image(icon = 'icons/obj/power.dmi', icon_state = "cable_bridge"),
	"Multi Z layer cable hub" = image(icon = 'icons/obj/power.dmi', icon_state = "cablerelay-broken-cable"),
	"Cable restraints" = restraints_icon
	)

	var/layer_result = show_radial_menu(user, src, radial_menu, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(layer_result)
		if("Layer 1")
			color = "red"
			target_type = /obj/structure/cable/layer1
			target_layer = CABLE_LAYER_1
			novariants = FALSE
		if("Layer 2")
			color = "yellow"
			target_type = /obj/structure/cable
			target_layer = CABLE_LAYER_2
			novariants = FALSE
		if("Layer 3")
			color = "blue"
			target_type = /obj/structure/cable/layer3
			target_layer = CABLE_LAYER_3
			novariants = FALSE
		if("Multilayer cable hub")
			name = "multilayer cable hub"
			desc = "A multilayer cable hub."
			icon_state = "cable_bridge"
			color = "white"
			target_type = /obj/structure/cable/multilayer
			target_layer = CABLE_LAYER_2
			novariants = TRUE
		if("Multi Z layer cable hub")
			name = "multi z layer cable hub"
			desc = "A multi-z layer cable hub."
			icon_state = "cablerelay-broken-cable"
			color = "white"
			target_type = /obj/structure/cable/multilayer/multiz
			target_layer = CABLE_LAYER_2
			novariants = TRUE
		if("Cable restraints")
			if (amount >= CABLE_RESTRAINTS_COST)
				if(use(CABLE_RESTRAINTS_COST))
					var/obj/item/restraints/handcuffs/cable/restraints = new
					restraints.color = color
					user.put_in_hands(restraints)
	update_appearance()


///////////////////////////////////
// General procedures
///////////////////////////////////
//you can use wires to heal robotics
/obj/item/stack/cable_coil/attack(mob/living/carbon/human/H, mob/user)
	if(!istype(H))
		return ..()

	var/obj/item/bodypart/affecting = H.get_bodypart(check_zone(user.zone_selected))
	if(affecting && !IS_ORGANIC_LIMB(affecting))
		if(user == H)
			user.visible_message(span_notice("[user] starts to fix some of the wires in [H]'s [affecting.name]."), span_notice("You start fixing some of the wires in [H == user ? "your" : "[H]'s"] [affecting.name]."))
			if(!do_mob(user, H, 50))
				return
		if(item_heal_robotic(H, user, 0, 15))
			use(1)
		return
	else
		return ..()


///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

// called when cable_coil is clicked on a turf
/obj/item/stack/cable_coil/proc/place_turf(turf/T, mob/user, dirnew)
	if(!isturf(user.loc))
		return

	if(!isturf(T) || T.underfloor_accessibility < UNDERFLOOR_INTERACTABLE || !T.can_have_cabling())
		to_chat(user, span_warning("You can only lay cables on catwalks and plating!"))
		return

	if(get_amount() < 1) // Out of cable
		to_chat(user, span_warning("There is no cable left!"))
		return

	if(get_dist(T,user) > 1) // Too far
		to_chat(user, span_warning("You can't lay cable at a place that far away!"))
		return

	for(var/obj/structure/cable/C in T)
		if(C.cable_layer & target_layer)
			to_chat(user, span_warning("There's already a cable at that position!"))
			return

	var/obj/structure/cable/C = new target_type(T)

	//create a new powernet with the cable, if needed it will be merged later
	var/datum/powernet/PN = new()
	PN.add_cable(C)

	for(var/dir_check in GLOB.cardinals)
		C.mergeConnectedNetworks(dir_check) //merge the powernet with adjacents powernets
	C.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets

	use(1)

	if(C.shock(user, 50))
		if(prob(50)) //fail
			C.deconstruct()

	return C

/obj/item/stack/cable_coil/five
	amount = 5

/obj/item/stack/cable_coil/cut
	amount = null
	icon_state = "coil2"
	worn_icon_state = "coil"
	base_icon_state = "coil2"

/obj/item/stack/cable_coil/cut/Initialize(mapload, new_amount, merge = TRUE, list/mat_override=null, mat_amt=1)
	if(!amount)
		amount = rand(1,2)
	. = ..()
	pixel_x = base_pixel_x + rand(-2, 2)
	pixel_y = base_pixel_y + rand(-2, 2)
	update_appearance()

#undef CABLE_RESTRAINTS_COST
#undef UNDER_SMES
#undef UNDER_TERMINAL

///multilayer cable to connect different layers
/obj/structure/cable/multilayer
	name = "multilayer cable hub"
	desc = "A flexible, superconducting insulated multilayer hub for heavy-duty multilayer power transfer."
	icon = 'icons/obj/power.dmi'
	icon_state = "cable_bridge"
	cable_layer = CABLE_LAYER_2
	machinery_layer = MACHINERY_LAYER_1
	layer = WIRE_LAYER - 0.02 //Below all cables Disabled layers can lay over hub
	color = "white"
	var/obj/effect/node/machinery_node
	var/obj/effect/node/layer1/cable_node_1
	var/obj/effect/node/layer2/cable_node_2
	var/obj/effect/node/layer3/cable_node_3

/obj/effect/node
	icon = 'icons/obj/power_cond/layer_cable.dmi'
	icon_state = "l2-noconnection"
	vis_flags = VIS_INHERIT_ID|VIS_INHERIT_PLANE|VIS_INHERIT_LAYER
	color = "black"

/obj/effect/node/layer1
	color = "red"
	icon_state = "l1-1-2-4-8-node"
	vis_flags = VIS_INHERIT_ID|VIS_INHERIT_PLANE|VIS_INHERIT_LAYER|VIS_UNDERLAY

/obj/effect/node/layer2
	color = "yellow"
	icon_state = "l2-1-2-4-8-node"
	vis_flags = VIS_INHERIT_ID|VIS_INHERIT_PLANE|VIS_INHERIT_LAYER|VIS_UNDERLAY

/obj/effect/node/layer3
	color = "blue"
	icon_state = "l4-1-2-4-8-node"
	vis_flags = VIS_INHERIT_ID|VIS_INHERIT_PLANE|VIS_INHERIT_LAYER|VIS_UNDERLAY

/obj/structure/cable/multilayer/update_icon_state()
	SHOULD_CALL_PARENT(FALSE)
	return

/obj/structure/cable/multilayer/update_icon()
	machinery_node?.alpha = machinery_layer & MACHINERY_LAYER_1 ? 255 : 0
	cable_node_1?.alpha = cable_layer & CABLE_LAYER_1 ? 255 : 0
	cable_node_2?.alpha = cable_layer & CABLE_LAYER_2 ? 255 : 0
	cable_node_3?.alpha = cable_layer & CABLE_LAYER_3 ? 255 : 0
	return ..()

/obj/structure/cable/multilayer/Initialize(mapload)
	. = ..()

	var/turf/T = get_turf(src)
	for(var/obj/structure/cable/C in T.contents - src)
		if(C.cable_layer & cable_layer)
			C.deconstruct() // remove adversary cable
	if(!mapload)
		auto_propagate_cut_cable(src)

	machinery_node = new /obj/effect/node()
	vis_contents += machinery_node
	cable_node_1 = new /obj/effect/node/layer1()
	vis_contents += cable_node_1
	cable_node_2 = new /obj/effect/node/layer2()
	vis_contents += cable_node_2
	cable_node_3 = new /obj/effect/node/layer3()
	vis_contents += cable_node_3
	update_appearance()

/obj/structure/cable/multilayer/Destroy() // called when a cable is deleted
	QDEL_NULL(machinery_node)
	QDEL_NULL(cable_node_1)
	QDEL_NULL(cable_node_2)
	QDEL_NULL(cable_node_3)
	return ..() // then go ahead and delete the cable

/obj/structure/cable/multilayer/examine(mob/user)
	. += ..()
	. += span_notice("L1:[cable_layer & CABLE_LAYER_1 ? "Connect" : "Disconnect"].")
	. += span_notice("L2:[cable_layer & CABLE_LAYER_2 ? "Connect" : "Disconnect"].")
	. += span_notice("L3:[cable_layer & CABLE_LAYER_3 ? "Connect" : "Disconnect"].")
	. += span_notice("M:[machinery_layer & MACHINERY_LAYER_1 ? "Connect" : "Disconnect"].")

GLOBAL_LIST(hub_radial_layer_list)

/obj/structure/cable/multilayer/attack_robot(mob/user)
	attack_hand(user)

/obj/structure/cable/multilayer/attack_hand(mob/living/user, list/modifiers)
	if(!user)
		return
	if(!GLOB.hub_radial_layer_list)
		GLOB.hub_radial_layer_list = list(
			"Layer 1" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-red"),
			"Layer 2" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-yellow"),
			"Layer 3" = image(icon = 'icons/hud/radial.dmi', icon_state = "coil-blue"),
			"Machinery" = image(icon = 'icons/obj/power.dmi', icon_state = "smes")
			)

	var/layer_result = show_radial_menu(user, src, GLOB.hub_radial_layer_list, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	var/CL
	switch(layer_result)
		if("Layer 1")
			CL = CABLE_LAYER_1
			to_chat(user, span_warning("You toggle L1 connection."))
		if("Layer 2")
			CL = CABLE_LAYER_2
			to_chat(user, span_warning("You toggle L2 connection."))
		if("Layer 3")
			CL = CABLE_LAYER_3
			to_chat(user, span_warning("You toggle L3 connection."))
		if("Machinery")
			machinery_layer ^= MACHINERY_LAYER_1
			to_chat(user, span_warning("You toggle machinery connection."))

	cut_cable_from_powernet(FALSE)

	Disconnect_cable()

	cable_layer ^= CL

	Connect_cable(TRUE)

	Reload()

/obj/structure/cable/multilayer/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

///Reset powernet in this hub.
/obj/structure/cable/multilayer/proc/Reload()
	var/turf/T = get_turf(src)
	for(var/obj/structure/cable/C in T.contents - src)
		if(C.cable_layer & cable_layer)
			C.deconstruct() // remove adversary cable
	auto_propagate_cut_cable(src) // update the powernets

/obj/structure/cable/multilayer/CtrlClick(mob/living/user)
	to_chat(user, span_warning("You push the reset button."))
	addtimer(CALLBACK(src, .proc/Reload), 10, TIMER_UNIQUE) //spam protect

// This is a mapping aid. In order for this to be placed on a map and function, all three layers need to have their nodes active
/obj/structure/cable/multilayer/connected
		cable_layer = CABLE_LAYER_1 | CABLE_LAYER_2 | CABLE_LAYER_3

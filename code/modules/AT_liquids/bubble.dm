/datum/bubble_group
	var/list/atom/movable/bubbles = list()
	var/datum/liquid_mix/liquids

#define MAX_BUBBLE_VOLUME 10

///in the absence of gravity liquids minimize their surface area by forming into spheres
/atom/movable/bubble
	icon = 'icons/turf/liquids/bubble.dmi'
	icon_state = "lone_bubble"

	///meters
	var/radius = 0.1
	var/border_dirs = NONE

	var/datum/liquid_mix/liquids
	var/list/bubble_neighbors = list()


/atom/movable/bubble/Initialize(mapload)
	. = ..()
	var/turf/turfloc = loc
	if(!turfloc || turfloc != get_turf(src))
		stack_trace("bubble initialized outside of a turf")
		return

	liquids = new
	var/datum/liquid_mix/our_liquids = src.liquids
	var/datum/liquid_mix/their_liquids = turfloc.liquids

	their_liquids.uni_flow(our_liquids)



/atom/movable/bubble/Destroy(force)
	. = ..()

/atom/movable/bubble/proc/process_bubble(fire_count)

/proc/get_line___(atom/starting_atom, atom/ending_atom)
	var/current_x_step = starting_atom.x//start at x and y, then add 1 or -1 to these to get every turf from starting_atom to ending_atom
	var/current_y_step = starting_atom.y
	var/starting_z = starting_atom.z

	var/list/line = list(get_turf(starting_atom))//get_turf(atom) is faster than locate(x, y, z)

	var/x_distance = ending_atom.x - current_x_step //x distance
	var/y_distance = ending_atom.y - current_y_step

	var/abs_x_distance = abs(x_distance)//Absolute value of x distance
	var/abs_y_distance = abs(y_distance)

	var/x_distance_sign = SIGN(x_distance) //Sign of x distance (+ or -)
	var/y_distance_sign = SIGN(y_distance)

	var/x = abs_x_distance >> 1 //Counters for steps taken, setting to distance/2
	var/y = abs_y_distance >> 1 //Bit-shifting makes me l33t.  It also makes get_line() unnessecarrily fast.

	if(abs_x_distance >= abs_y_distance) //x distance is greater than y
		for(var/distance_counter in 0 to (abs_x_distance - 1))//It'll take abs_x_distance steps to get there
			y += abs_y_distance

			if(y >= abs_x_distance) //Every abs_y_distance steps, step once in y direction
				y -= abs_x_distance
				current_y_step += y_distance_sign

			current_x_step += x_distance_sign //Step on in x direction
			line += locate(current_x_step, current_y_step, starting_z)//Add the turf to the list
	else
		for(var/distance_counter in 0 to (abs_y_distance - 1))
			x += abs_x_distance

			if(x >= abs_y_distance)
				x -= abs_y_distance
				current_x_step += x_distance_sign

			current_y_step += y_distance_sign
			line += locate(current_x_step, current_y_step, starting_z)
	return line

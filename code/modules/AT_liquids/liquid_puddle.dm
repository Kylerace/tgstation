
/turf
	var/list/puddles

///amount = moles, radius = meters, liquid_type is the type thats spawned
/turf/proc/assert_puddle(amount = 100, radius = 0.05, datum/liquid/liquid_type = /datum/liquid/water, vz = 0, vx = 0, vy = 0, g = 9.81)
	var/r_2 = radius ** 2

	var/total_volume = amount * initial(liquid_type.molar_volume)
	//circle
	var/interface_area = PI * r_2

	var/spreading_parameter = 0

	var/interface_energy = 0
	//we need to determine the surface energy of the solid-liquid interface

	//assume its a non wetting droplet at t=0 maybe?
	var/height = 0

	var/hydrostatic_pressure = 0
	var/laplace_pressure = 0

/datum/puddle

	var/list/liquids = list(list(), list())
	var/list/turf/turfs = list()

/datum/puddle/process(seconds_per_tick)


/datum/puddle/proc/get_expansion_border()


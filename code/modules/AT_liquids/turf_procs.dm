

/turf/proc/delete_all_liquids(range = 20)
	var/min_x = max(x-range, 1)
	var/min_y = max(y-range, 1)
	var/min_z = max(z-range, 1)
	var/max_x = min(x+range, world.maxx)
	var/max_y = min(y+range, world.maxy)
	var/max_z = min(z+range, world.maxz)
	for(var/turf/turf_to_clear in block(locate(min_x, min_y, min_z), locate(max_x, max_y, max_z)))
		var/datum/liquid_mix/turf_liquids = turf_to_clear.liquids
		if(!turf_liquids)
			continue
		var/liquid_moles = 0
		TOTAL_LIQUID_MOLES(turf_liquids.liquids[LIQUID_CURRENT], liquid_moles)
		if(liquid_moles == 0)
			continue
		turf_liquids.liquids = list(list(), list())
		SSliquids.remove_active_turf(turf_to_clear)
		turf_to_clear.update_liquid_visuals()

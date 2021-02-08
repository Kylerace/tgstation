
/datum/map_template/mapticktest
	var/maptick_id

/datum/map_template/mapticktest/New(path = null, rename = null, cache = FALSE)
	if(path)
		mappath = path
	if(mappath)
		preload_size(mappath, cache)
	if(rename)
		name = rename
		maptick_id = rename

/*
when making a test, it should in 99% of cases by 25x25 in order to be standardized, the turf should be featureless plating unless you are
testing a specific turf. tests must be made to answer a specific question about how something impacts maptick against a control test.
make sure that in most cases that the entire test area is uniform, the player is expected to be spawned in the middle of the test in a non
station z level (note, jury is still out on whether number of appearances in the entire z level affects maptick even when unseen).

tests that involve objects should have at least two variants, a 1 layer and a 50 layer version. 1 layer is the object in question
distributed on every tile once, 50 layer is every tile being filled with 50 of those objects in the exact same place (no pixel shifting),
unless you are of course testing what pixel shifting does to maptick. if possible base your objects off of /obj/item/maptick_test_generic
except for one single difference

group 1 and 50 test variants together, post what the purpose of the tests are, and exactly what question they are supposed to answer about maptick
comment what average maptick was while you were testing via the "start maptick test" admin verb in the debug panel, name it after the test
after around 10 minutes, turn off the maptick test with the stop maptick test verb. its a csv so you can put it into google sheets or MS office
to get a graph. always put the last average maptick value you get on the test template in here

when testing do not move, turn off hud as that raises maptick marginally (the only way to get 0% maptick is with the blank test and no hud)
CLOTHING THAT CHANGES VISION RAISES MAPTICK EVEN WITHOUT ANY WALLS, UNLESS YOU ARE TESTING THAT DO NOT WEAR ANY MESONS OR WHATEVER
also by default turn off parallax.

as of right now i am testing with a human wearing the debug outfit, there used to be a dummy species which was preferable to this but i
think it was removed, ill have to find a species with less visual noise on the suspicion of mob overlays/viscontents/whatever the fuck else

maptick is very noisy, testing stuff on station is almost impossible. even with all of this it is still pretty noisy. maptick might somehow
improve after the first couple of tests?????
*/


/datum/map_template/mapticktest
	var/maptick_id

//blank control test, nothing but generic plating 20x20. ~ 0-0.1% hs 0.2-0.3%
/datum/map_template/mapticktest/blank
	maptick_id = "blank"
	mappath = "_maps/templates/mapticktest_blank.dmm"

//generic object tests, meant as the control for all object tests
/datum/map_template/mapticktest/generic_objects_1_layer // 0.2-0.3% hs 0.4%
	maptick_id = "generic objects 1 layer"
	mappath = "_maps/templates/mapticktest_generic_objects.dmm"

/datum/map_template/mapticktest/generic_objects_50_layer // ~ 9.5-10.5% hs 11.2-11.9% | 8.5-10.5%??? hs ~11.5%
	maptick_id = "generic objects 50 layer"
	mappath = "_maps/templates/mapticktest_generic_objects_50_layers.dmm"

/datum/map_template/mapticktest/generic_objects_100_layer //19-20%
	maptick_id = "generic objects 100 layer"
	mappath = "_maps/templates/mapticktest_generic_objects_100_layers.dmm"

//these objects have an invisible image as an overlay to test whether or not overlays in general raise maptick
//will likely need to add many invisible images to fully rule this out
/datum/map_template/mapticktest/invisible_image_objects // 0.2-0.3% hs 0.4%
	maptick_id = "invisible images"
	mappath = "_maps/templates/mapticktest_invisible_image_objects.dmm"

/datum/map_template/mapticktest/invisible_image_objects_50_layer // ~8.5-9.8% hs 11% ld 7-8% | 8.5-10% consistently lower???? hs ~11.5%
	maptick_id = "invisible images 50 layer"
	mappath = "_maps/templates/mapticktest_invisible_image_objects_50_layer.dmm"

//these objects are permanently spinning with animate(src, transform = turn(matrix(), 120), time = 1, loop = -1)
//this is to test whether constant animations increase maptick
/datum/map_template/mapticktest/speen_objects // 0.3-0.4% hs 0.5%
	maptick_id = "spinning objects"
	mappath = "_maps/templates/mapticktest_animation_test.dmm"

/datum/map_template/mapticktest/speen_objects_50_layer // 9-10.5% hs 11.5% ld 8.5%
	maptick_id = "spinning objects 50 layer"
	mappath = "_maps/templates/mapticktest_animation_50_layer.dmm"

//this is meant to test whether overlays are more expensive than normal icons, the objects have no icon but have an overlay with the metal sheet sprite
/datum/map_template/mapticktest/invis_objects_vis_overlays //0.2-0.3% hs 0.4%
	maptick_id = "invis obj vis overlay"
	mappath = "_maps/templates/mapticktest_invis_object_vis_overlay.dmm"

/datum/map_template/mapticktest/invis_objects_vis_overlays_50_layer
	maptick_id = "invis obj vis overlay 50 layer"
	mappath = "_maps/templates/mapticktest_invis_object_vis_overlay_50_layers.dmm"

//this test is designed to test if lack of vision has any effect on maptick, is exactly like the normal generic objects 50 test except the center is walled in
/datum/map_template/mapticktest/generic_objects_50_layer_walled_in
	maptick_id = "generic objects 50 layer walled in"
	mappath = "_maps/templates/mapticktest_generic_objects_50_layers_walled_in_vision.dmm"


/datum/map_template/mapticktest/mapticktest_moving_genobj50l
	maptick_id = "mapticktest_moving_genobj50l"
	mappath = "_maps/templates/mapticktest_moving_genobj50l.dmm"

/datum/map_template/mapticktest/mapticktest_changing_turfs
	maptick_id = "mapticktest_changing_turfs"
	mappath = "_maps/templates/mapticktest_changing_turfs.dmm"

/datum/map_template/mapticktest/mapticktest_invisible_object
	maptick_id = "mapticktest_invisible_object"
	mappath = "_maps/templates/mapticktest_invisible_object.dmm"

/datum/map_template/mapticktest/mapticktest_moving_blank_test
	maptick_id = "mapticktest_moving_blank_test"
	mappath = "_maps/templates/mapticktest_moving_blank_test.dmm"

/datum/map_template/mapticktest/mapticktest_moving_genobj
	maptick_id = "mapticktest_moving_genobj"
	mappath = "_maps/templates/mapticktest_moving_genobj.dmm"

/datum/map_template/mapticktest/mapticktest_invis_obj_vis_viscontents
	maptick_id = "mapticktest_invis_obj_vis_viscontents"
	mappath = "_maps/templates/mapticktest_invis_obj_vis_viscontents.dmm"

/datum/map_template/mapticktest/mapticktest_static_mob
	maptick_id = "mapticktest_static_mob"
	mappath = "_maps/templates/mapticktest_static_mob.dmm"

/datum/map_template/mapticktest/mapticktest_static_overlay_stacking
	maptick_id = "mapticktest_static_overlay_stacking"
	mappath = "_maps/templates/mapticktest_static_overlay_stacking.dmm"

/datum/map_template/mapticktest/mapticktest_static_viscont_stacking
	maptick_id = "mapticktest_static_viscont_stacking"
	mappath = "_maps/templates/mapticktest_static_viscont_stacking.dmm"

/datum/map_template/mapticktest/mapticktest_viscont_changespam
	maptick_id = "mapticktest_viscont_changespam"
	mappath = "_maps/templates/mapticktest_viscont_changespam.dmm"

/datum/map_template/mapticktest/mapticktest_invisible_object50l
	maptick_id = "mapticktest_invisible_object50l"
	mappath = "_maps/templates/mapticktest_invisible_object50l.dmm"

/datum/map_template/mapticktest/mapticktest_static_mob50l
	maptick_id = "mapticktest_static_mob50l"
	mappath = "_maps/templates/mapticktest_static_mob50l.dmm"

/datum/map_template/mapticktest/mapticktest_static_overlay_stacking50l
	maptick_id = "mapticktest_static_overlay_stacking50l"
	mappath = "_maps/templates/mapticktest_static_overlay_stacking50l.dmm"

/datum/map_template/mapticktest/mapticktest_static_viscont_stacking50l
	maptick_id = "mapticktest_static_viscont_stacking50l"
	mappath = "_maps/templates/mapticktest_static_viscont_stacking50l.dmm"

/datum/map_template/mapticktest/mapticktest_viscont_changespam50l
	maptick_id = "mapticktest_viscont_changespam50l"
	mappath = "_maps/templates/mapticktest_viscont_changespam50l.dmm"

/datum/map_template/mapticktest/mapticktest_invis_obj_vis_viscontents50l
	maptick_id = "mapticktest_invis_obj_vis_viscontents50l"
	mappath = "_maps/templates/mapticktest_invis_obj_vis_viscontents50l.dmm"

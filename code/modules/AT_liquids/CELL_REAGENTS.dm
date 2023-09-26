#define NEW_REAGENTS_GASES 1
#define NEW_REAGENTS_LIQUIDS 2
#define NEW_REAGENTS_SOLIDS 3

#define NEW_REAGENTS_EMPTY list()

/turf
	var/datum/new_reagents/new_reagents

/turf/open/New(loc, ...)
	. = ..()
	new_reagents = new

//i dont want to refactor actual reagents so make a new version that works how you want
/datum/new_reagents
	///sublists, one each for each phase of reagents in this material: GAS, LIQUIDS, and SOLIDS
	///each sublist is like the gas list, of the form: list(reagent typepath = list(archived moles, next moles, meta reference))
	var/list/phases = list("liquid phase" = list("archived temp", "next temp", "archived ph", "next ph", list(/datum/reagent/water = list(1, 2, "reference to meta list"))))

	///
	var/list/solid_surfaces

	///liters
	var/max_volume

	//these add up to 1
	///
	var/gas_volume_fraction = 1
	var/liquid_volume_fraction = 0
	var/solid_volume_fraction = 0

/datum/new_reagents/New()
	//fluid_reagents = NEW_REAGENTS_EMPTY


/datum/new_reagents/cell
	max_volume = CELL_VOLUME

/turf
	///the material we present to
	var/datum/material/material_interface = /datum/material/iron

///this is hard to do efficiently, do it the dumb way first
GLOBAL_LIST_INIT(liquid_reactions, init_liquid_reactions())

/proc/init_liquid_reactions()
	. = list()
	for(var/datum/liquid_reaction/reaction_path as anything in subtypesof(/datum/liquid_reaction))
		. += new reaction_path

#define LIQUID_REACTION_REQUIREMENT_LIQUID 1
#define LIQUID_REACTION_REQUIREMENT_SOLID_INTERFACE 2
#define LIQUID_REACTION_REQUIREMENT_GAS_INTERFACE 3

/datum/liquid_reaction
	var/name = "AAA"

	/**
	 * list of sublists containing specified typepaths, each denoting a required chemcical to be present in order to
	 *
	 */
	var/list/requires = list()

	var/min_temperature = 0
	var/max_temperature = 0

	var/min_pressure = 0
	var/max_pressure = 0

/datum/liquid_reaction/proc/react(turf/holder, datum/liquid_mix/liquids, temperature, pressure, list/solid_interfaces, datum/gas_mixture/gas_interface)
	return


/datum/liquid_reaction/water_boiling
	name = "boiling"

//TODOKYLER: make this accurate, with pressure
/datum/liquid_reaction/water_boiling/react(turf/holder, datum/liquid_mix/liquids, temperature, pressure, list/solid_interfaces, datum/gas_mixture/gas_interface)
	. = NO_REACTION
	if(!isturf(holder))
		return

	var/list/cached_liquids = liquids.liquids
	var/num_moles = cached_liquids[LIQUID_NEXT][/datum/liquid/water]

	if(temperature < 375.15 || num_moles <= 0)
		return
	. = REACTING

	var/consumed = min(num_moles, 5)

	var/datum/liquid/water/water = /datum/liquid/water
	var/datum/gas/water_vapor/water_vapor = /datum/gas/water_vapor

	var/list/gases = gas_interface.gases
	var/old_vapor_moles = gases[/datum/gas/water_vapor]?[MOLES]
	var/new_vapor_moles = old_vapor_moles + consumed

	ASSERT_GAS(/datum/gas/water_vapor, gas_interface)
	gases[/datum/gas/water_vapor][MOLES] = new_vapor_moles

	if(old_vapor_moles == 0)
		SSair.add_to_active(holder)

	cached_liquids[LIQUID_NEXT][/datum/liquid/water] -= consumed
	liquids.volume -= consumed * initial(water.molar_volume)

	var/old_gas_heat_capacity = 0
	var/old_liquid_heat_capacity = 0
	for(var/datum/gas/gas_path as anything in gases)
		var/moles = gases[gas_path][MOLES]
		old_gas_heat_capacity += moles * initial(gas_path.specific_heat)

	for(var/datum/liquid/liquid_path as anything in cached_liquids[LIQUID_NEXT])
		var/moles = cached_liquids[LIQUID_NEXT][liquid_path]
		old_liquid_heat_capacity += moles * initial(liquid_path.molar_heat_capacity)

	var/heat_capacity_liquid_to_gas = consumed * initial(water.molar_heat_capacity)

	var/new_gas_heat_capacity = old_gas_heat_capacity + heat_capacity_liquid_to_gas
	var/new_liquid_heat_capacity = old_liquid_heat_capacity - heat_capacity_liquid_to_gas

	if(new_gas_heat_capacity)
		gas_interface.temperature = (old_gas_heat_capacity * gas_interface.temperature + heat_capacity_liquid_to_gas * liquids.temperature_archived) / new_gas_heat_capacity

	if(new_liquid_heat_capacity)
		liquids.temperature = (old_liquid_heat_capacity * liquids.temperature - heat_capacity_liquid_to_gas * gas_interface.temperature_archived) / new_liquid_heat_capacity

	if(old_vapor_moles <= 0)
		SSair.add_to_active(holder)

/datum/liquid_reaction/gasoline_burn
	name = "gasoline burning"

/datum/liquid_reaction/gasoline_burn/react(turf/holder, datum/liquid_mix/liquids, temperature, pressure, list/solid_interfaces, datum/gas_mixture/gas_interface)
	. = NO_REACTION
	if(!isturf(holder))
		return

	var/list/cached_liquids = liquids.liquids
	var/gasoline_moles = cached_liquids[LIQUID_NEXT][/datum/liquid/gasoline]

	var/list/cached_gases = gas_interface.gases
	var/oxygen_moles = cached_gases[/datum/gas/oxygen]?[MOLES]

	if(temperature < 540 || gasoline_moles <= 0.5 || oxygen_moles <= 0.5)
		return
	. = REACTING

	var/oxygen_per_gasoline_burn_ratio = 12.5
	var/carbon_dioxide_per_gasoline_creation_ratio = 8
	var/water_per_gasoline_creation_ratio = 9

	//2 C8H18 + 25 O2 = 16 CO2 + 18 H2O, where C8H18 is octane, which we assume to be gasoline

	var/consumed_gasoline = min(gasoline_moles, oxygen_moles / oxygen_per_gasoline_burn_ratio, 5)
	var/consumed_oxygen = consumed_gasoline * oxygen_per_gasoline_burn_ratio

	var/created_co2 = consumed_gasoline * carbon_dioxide_per_gasoline_creation_ratio
	var/created_water = consumed_gasoline * water_per_gasoline_creation_ratio

	//each mole of octane (major component of gasoline) burned with oxygen creates 5472 kJ of thermal energy
	//molar ratio of oxygen : gasoline in the reaction is 12.5:1

	var/created_energy = consumed_gasoline * 5472 //moles * joules/mole = joules

	var/old_liquid_heat_capacity = 0
	var/old_gas_heat_capacity = 0

	for(var/datum/liquid/liquid_path as anything in cached_liquids[LIQUID_NEXT])
		var/moles = cached_liquids[LIQUID_NEXT][liquid_path]
		old_liquid_heat_capacity += moles * initial(liquid_path.molar_heat_capacity)

	for(var/datum/gas/gas_path as anything in cached_gases)
		var/moles = cached_gases[gas_path][MOLES]
		old_gas_heat_capacity += moles * initial(gas_path.specific_heat)

	var/datum/gas/water_vapor/water_vapor = /datum/gas/water_vapor
	var/datum/gas/oxygen/oxygen = /datum/gas/oxygen
	var/datum/gas/carbon_dioxide/carbon_dioxide = /datum/gas/carbon_dioxide

	var/datum/liquid/water/water = /datum/liquid/water

	var/heat_capacity_liquid_to_gas = created_water * initial(water_vapor.specific_heat) + created_co2 * initial(water_vapor.specific_heat) - consumed_oxygen * initial(oxygen.specific_heat)

	var/new_gas_heat_capacity = old_gas_heat_capacity + heat_capacity_liquid_to_gas
	var/new_liquid_heat_capacity = old_liquid_heat_capacity - heat_capacity_liquid_to_gas

	ASSERT_GAS(/datum/gas/water_vapor, gas_interface)
	ASSERT_GAS(/datum/gas/carbon_dioxide, gas_interface)

	cached_gases[/datum/gas/water_vapor][MOLES] += created_water
	cached_gases[/datum/gas/carbon_dioxide][MOLES] += created_co2

	cached_gases[/datum/gas/oxygen][MOLES] -= consumed_oxygen

	cached_liquids[LIQUID_NEXT][/datum/liquid/gasoline] -= consumed_gasoline

	///amount of created energy going to the liquid / total created energy. whatever isnt given to the liquid goes to the gas.
	/// if this is 0.5 then half of it goes to both the gas and the liquid
	var/created_energy_to_liquid_ratio = 0.5

	if(!new_gas_heat_capacity || !new_liquid_heat_capacity)
		if(!new_gas_heat_capacity)//assume that one is still nonzero because if both are zero no share happens anyways
			created_energy_to_liquid_ratio = 1
		if(!new_liquid_heat_capacity)
			created_energy_to_liquid_ratio = 0

	/*
	if(new_gas_heat_capacity)
		gas_interface.temperature = (old_gas_heat_capacity * gas_interface.temperature + heat_capacity_liquid_to_gas * liquids.temperature_archived) / new_gas_heat_capacity

	if(new_liquid_heat_capacity)
		liquids.temperature = (old_liquid_heat_capacity * liquids.temperature - heat_capacity_liquid_to_gas * gas_interface.temperature_archived) / new_liquid_heat_capacity
	*/

	if(new_gas_heat_capacity)
		gas_interface.temperature = (old_gas_heat_capacity * gas_interface.temperature + heat_capacity_liquid_to_gas * liquids.temperature_archived + (1 - created_energy_to_liquid_ratio) * 5472) / new_gas_heat_capacity

	if(new_liquid_heat_capacity)
		liquids.temperature = (old_liquid_heat_capacity * liquids.temperature - heat_capacity_liquid_to_gas * liquids.temperature_archived + created_energy_to_liquid_ratio * 5472) / new_liquid_heat_capacity

	SSair.add_to_active(holder)

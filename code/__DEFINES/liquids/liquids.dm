///liquids list index containing the list of the moles of every liquid that existed the last SSchemicals fire
#define LIQUID_CURRENT 1
///liquids list index containing the list of the moles of every liquid that's being processed in the current SSchemicals fire, and will become LIQUID_CURRENT at the end
#define LIQUID_NEXT 2

///CELL_VOLUME = 2500 liters, this is 2.5 m^3
#define LIQUID_CELL_VOLUME 2.5

#define MINIMUM_VOLUME_DELTA_TO_ACTIVATE 500
///cant make turf gas mixes have less volume than this
#define MINIMUM_AIR_VOLUME 0.01

/// Molar accuracy to round to
#define LIQUID_MOLAR_ACCURACY  0.1
#define LIQUID_QUANTIZE(variable) (round((variable), (LIQUID_MOLAR_ACCURACY)))

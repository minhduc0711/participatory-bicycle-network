# Participatory-bicycle-network

This model generates a process of collecting pollution information from on-board sensors by an urban population of cyclists. To this end, an urban synthetic population of cyclists and its daily trips are simulated, and then coupled with a pollution model. The model uses demographical data, employment data, mobility survey data, points of interest dataset, and a network. The objective is to know whether or not the bicycle traffic can transcript urban pollution.

The model runs on GAMA-platform, which is a modeling environment for building spatially explicit agent-based simulations.

# Traffic simulation 
The GAML code last worked with https://github.com/gama-platform/gama/tree/ca9d94a39c54544e594a12a47dd59f231e3af617.

## Input data
You should have a copy of `includes.zip` (not stored on GitHub due to its size).
Extract it to the root dir.
<!-- TODO: elaborate on the input files -->

## Running the GAMA simulation
You should check [params.gaml](models/params.gaml) if you need to change some global simulation parameters.
The notable ones are:
* `city`: determines the shapefiles used. At the moment we have three cities:
`Aix-en-Provence`, `Marseille` and `Toulouse`.
* `number_of_sensors`: the number of cyclists who are able to record the pollution levels as they move (i.e. they are equipped with air quality sensors).

Execute the GAML files in the following order:
1. [preprocess_shapefiles.gaml](models/preprocess_shapefiles.gaml): preprocess the raw shapefiles, outputs new shapefiles in `generated/city/preprocessed_shapefiles`.
    * For more variety in the buildings, we combine data from OSM and IGN databases. Types of buildings are coupled between these two databases.
    * Roads: extracted from OSM database, and we only keep roads that can be used by cyclists. A speed coefficient is added depending on the type of road adapt cyclists' speed. Many factors to determine cyclist's speed have been taken into account, like the slope of the road in the model 'Digital Elevation Model for roads.gaml'.

1. [create_cyclists_profiles.gaml](models/create_cyclists_profiles.gaml):
generate information for a population of cyclists.
    * The population is composed of workers, students and "leisure people". 
    * Their living place, destination place and timetable are defined by data from [Mobiliscope](https://mobiliscope.cnrs.fr) and household surveys. 
    * The resulting CSV is saved to `generated/the_city/synthetic_population`.
    * Note that you can generate a test population which is 20 times smaller than the actual population, by setting the global param `test_population <- true`.

1. [Optional] [precompute_shortest_paths.gaml](models/precompute_shortest_paths.gaml): compute the shortest paths between all possible nodes in the road network. Might take some time but it will speed up the traffic simulation. However, an error will be thrown if the road network has too many nodes (due to maximum size of a GAMA matrix).

1. [simulate_traffic.gaml](models/simulate_traffic.gaml): simulate cyclists' movement around the city.
    * Cyclists' speed is chosen depending on the type of road they take.
    * Their trajectories (positions and timestamps) are saved as CSV files in `generated/city/type_of_population` (e.g. `generated/Toulouse/worker`). 

1. [build_dataset.gaml](models/build_dataset.gaml): for each point in a cyclist's trajectory,
compute the environmental features (taking into account certain radius around the point) and retrieve the pollution levels using the pollution rasters.
This can be useful for training ML models to predict pollution levels in areas unexplored by cyclists.
    * The resulting dataset is saved to `generated/city/measures_N.csv` (`N` is the number of cyclists equipped with sensors).

The other GAML files in [models/archived](models/archived) could have some use but
they need to be rewrite to work with this new version.

## Predicting pollution levels using land-use regression
After generating the dataset consisting of environmental features (e.g. building volumes, areas of nearby forest, distance to closest main road...) and pollution levels as targets,
we can run [gam.R](regression/gam.R) to train GAM for predicting in unexplored areas.
The required R packages are:
* mgcv (implementation of GAMs)
* dplyr (manipulate dataframes)
* lubridate (used for cyclical encoding of timestamps)

## Rendez-vous for faulty sensor detection
[This paper](https://link.springer.com/chapter/10.1007/978-3-319-03071-5_3) proposes the concept of a rendez-vous:
two sensors make a rendez-vous when the set of temporally & spacially close measurement pairs is big enough.
By computing the correlation in-between the rendez-vous pairs, we can detect if any sensors is generating incorrect measurements (when the correlation coefficient is smaller than usual).
We attempted to implement this procedure in the Python notebook [rendez_vous.ipynb](rendez_vous.ipynb), but it does not seem to be able to detect faulty sensor since the relevant coefficients are still high.

To try out the notebook, you need to install some required Python packages by running `pip install -r requirements.txt`.

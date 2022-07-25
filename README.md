# Participatory-bicycle-model

This model generates a process of collecting pollution information from on-board sensors by an urban population of cyclists. To this end, an urban synthetic population of cyclists and its daily trips are simulated, and then coupled with a pollution model. The model uses demographical data, employment data, mobility survey data, points of interest dataset, and a network. The objective is to know whether or not the bicycle traffic can transcript urban pollution. 

The model runs on GAMA-platform, which is a modeling environment for building spatially explicit agent-based simulations.

# Getting started

## Installing

Download the GAMA-platform (GAMA1.8.2 with JDK version) from https://gama-platform.github.io/.

## Running the model

The input data of the project is in the `includes` folder and the model codes are in the `models` folder.

1. Run the experiments in [1_Buildings_and_roads_environment.gaml](./models/1_Buildings_and_roads_environment.gaml) and [2_Adapt_roads_to_cyclists.gaml](models/2_Adapt_roads_to_cyclists.gaml) to produce the city environment (buildings and roads) which will be used by cyclists.
    * Buildings: for more variety in the building data, we used both OSM and IGN databases. Types of buildings are coupled between these two databases.
    * Roads: they are simply extracted from OSM database and adapted so that we only keep roads that can be used by cyclists. A speed coefficient is added depending on the type of road adapt cyclists' speed. Many factors to determine cyclist's speed have been taken into account, like the slope of the road in the model 'Digital Elevation Model for roads.gaml'.

1. Generate a synthetic population with the model [3_Synthetic_population.gaml](models/3_Synthetic_population.gaml).
    * At the moment, only the populations of Marseille and Toulouse can be generated, but it is possible to generate the population of any city in France by retrieving the population data from [Mobiliscope](https://mobiliscope.cnrs.fr), and by rerunning the first step for the chosen city. 
    * However, the rest of the model only takes into account the city of Marseille due to the lack of pollution data for other cities.
    * The population is composed of workers, students and leisure people. Their living place, destination place and agenda are defined by data from Mobiliscope and household surveys. The synthetic population is saved under `results/the_city/synthetic_population` as a csv file.
    * Note that you can generate a test population which is 20 times smaller than the actual population (useful if you do not want to wait too long).

1. Simulate cyclists' trips with the experiment in [4_Bicycle_network_Marseille_travel_agents.gaml](models/4_Bicycle_network_Marseille_travel_agents.gaml).
    * Cyclists' speed is chosen depending on the type of road they take.
    * During the experiment, each path is generated and finally recorded under `results/Marseille/`.
    * This model saves the shapefiles of each population's positions during the day in `results/Marseille/type_of_population`. You can see an overview of the generated population with the model `Synthetic population viewer.gaml`.

1. Generate pollution level measurements (NO2, O3, PM10, PM25) made by each population of agent (worker, student or leisure) during their trips with the model [5_Synthetic_measures_from_agents_travels.gaml](models/5_Synthetic_measures_from_agents'_travels.gaml).
    * Results are saved under `results/Marseille/measures_N.csv` (in which `N` is the number of sensors).
    * Depending on a parameter, the model can generate measures for 100, 1000 or 5000 agents (representing the number of pollution sensors deployed to citizens in the city).

1. Run [6_Environment_for_measures.gaml](models/6_Environment_for_measures.gaml) to generate environmental data with a radius of 50m for every measure point, in order to use for predict pollution levels in unexplored areas.
    * The results of each measure's environment is saved in `results/Marseille/environment_of_measures_N_sensors.csv`.

1. The models [7_Measures_to_predict.gaml](models/7_Measures_to_predict.gaml) and [8_Environment_for_measures_to_predict.gaml](models/8_Environment_for_measures_to_predict.gaml) generate environmental data for trips we want to predict the pollution.
    * They are randomly chosen in the set of trips already generated.
    * The results of each measure to predict is saved in `results/Marseille/measures_to_predict.csv`, and the environment for the prediction is saved in `../results/Marseille/environment_of_measures_to_predict.csv`

1. Create land use regression (LUR) models using the generated enviromental features coupled with temporal indicators to predict pollution levels.
    * **However I could not achieve this step**: the regression I performed in the model [9_Regression_and_prediction.gaml](models/9_Regression_and_prediction.gaml) realizes a regression using the least squares method and then use it to predict the pollution level in places where other cyclist agents (the last quarter of cyclists for whom pollution was not measured) will go. This methods does not seem optimal. However, some suggestions are made in the Perspectives section of the report.

Other notes:
* To validate the trips data, it can be useful to compare mean trips' length and duration. You can generate this information with the model [Travel_study.gaml](models/Travel_study.gaml). It saves all trips data in `results/Marseille/the_agent_population/travel_time.csv`.
* You can also check each population's exposure to each pollutant with the model [Agents_exposure.gaml](models/Agents_exposure.gaml). For each agent, it saves pollution exposure such as maximum concentration met or mean exposure during trips.

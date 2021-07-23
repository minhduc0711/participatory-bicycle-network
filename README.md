# Participatory-bicycle-model

This model generates a process of collecting pollution information from on-board sensors by an urban population of cyclists. To this end, an urban synthetic population of cyclists and its daily trips are simulated, and then coupled with a pollution model. The model uses demographical data, employment data, mobility survey data, points of interest dataset, and a network. The objective is to know whether or not the bicycle traffic can transcript urban pollution. 

The model runs on GAMA-platform, which is a modeling environment for building spatially explicit agent-based simulations.

# Getting started

## Installing

Download the GAMA-platform (GAMA1.8.2 with JDK version) from https://gama-platform.github.io/.

## Running the model

The input data of the project is in the “includes” folder and the model codes are in the “models” folder.

The first step is to produce the city environment which will be used by cyclists: buildings and roads. You have to run the experiment from model '1_Buildings and roads environment.gaml'. 
Buildings: for more variety in the building data, we used both OSM and IGN databases. Types of buildings are coupled between these two databases.
Roads: they are simply extracted from OSM database and adapted so that we only keep roads that can be used by cyclists (model '2_Adapt roads to cyclists'). A speed coefficient is added depending on the type of road to adapt cyclists' speed. Many factors to determine cyclist's speed have been taken into account, like the slope of the road in the model 'Digital Elevation Model for roads.gaml'. 

Then you can generate a synthetic population with the model 'Synthetic population.gaml'. At that time, only the populations of Marseille and Toulouse can be generated, but it is possible to generate the population of any city in France by retrieving the population data from Mobiliscope (https://mobiliscope.cnrs.fr), and by doing the first step for the chosen city. However, the rest of the model only takes into account the city of Marseille (lack of pollution data for other cities). The population is composed of workers, students and leisure people. Their living place, destination place and agenda are defined by data from Mobiliscope and household surveys. The synthetic population is saved under '../results/the_city/synthetic_population' as a csv file.

Once the synthetic population is created, you can simulated its trips with the experiment in 'Bicycle network Marseille travel agents.gaml'. Cyclists' speed is chosen depending on the type of road they take. During the experiment, each path is generated and finally recorded under 'results/Marseille/'. This model saves the shapefiles of every population's positions during the day in 'results/Marseille/type_of_population'. You can see an overview of the generated population with the model 'Synthetic population viewer.gaml'.

Then, pollution level measurements (NO2, O3, PM10, PM25) made by each population of agent (worker, student or leisure) during their trips are generated with the model "Synthetic measures from agents' travels.gaml". They are saved under "../results/Marseille/measures_'number_of_sensors'.csv". 
Depending on a parameter, the model can generate measures for 100, 1000 or 5000 agents (representing the number of pollution sensors deployed to citizens in the city)

In order to predict the pollution level in places where no cyclists have travelled, we first need to generate environmental data for every measure point. The model "Environment for measures.gaml" generates environmental data with a radius of 50m around the measure point. The results of each measure's environment is saved in "../results/Marseille/environment_of_measures_'number_of_sensors'_sensors.csv".
The models "Measures to predict.gaml" and "Environment for measures to predict.gaml" generate environmental data for trips we want to predict the pollution. They are randomly chosen in the set of trips already generated. The results of each measure to predict is saved in 'results/Marseille/measures_to_predict.csv', and the environment for the prediction is saved in '../results/Marseille/environment_of_measures_to_predict.csv'

Then, for each environmental indicator (types of roads, vegetation...), a regression with every corresponding measure point is performed in the model 'Regression and prediction.gaml'. This model realizes a regression and then use it to predict the pollution level in places where other cyclist agents (the last quarter of cyclists for whom pollution was not measured) will go. Finally, the pertinence of the indicator chosen for the regression will be tested by comparing the pollution level predicted and the pollution level seen by the cyclist. However, the regression operator implemented in GAMA is multi-linear, which is not adapted to the studied data (the relationship between the pollution values and the environment is not linear). 

To validate the trips data, it can be useful to compare mean trips' length and duration. You can generate this information with the model 'Travel study.gaml'. It saves all trips data in results/Marseille/the_agent_population/travel_time.csv'.
You can also check every population's exposition to each pollutant with the model 'Agents' exposition.gaml'. It saves, for each agent, pollution exposition such as maximum concentration met or mean exposition during trips.

/**
 * Name: params
 * Based on the internal empty template.
 * Author: nathancoisne
 * Tags:
 */

model params

global {
	float seed <- 42.0;

	string city <- "Aix-en-Provence";

	bool test_population <- false; // permet de générer une population test 20 fois moins peuplée que la population réelle
	bool entire_population <- false; //true pour générer les mesures de tous les agents (pour vérifier des expositions de populations avec le modèle Agents' exposition)

	bool workers <- true;
	bool students <- true;
	bool leisures <- true;

	bool measure_NO2 <- true;
	bool measure_O3 <- true;
	bool measure_PM10 <- true;
	bool measure_PM25 <- true;

	int number_of_sensors <- 100; //represente le nombre de cyclistes équipés de capteurs dans la ville

	// Commonly used paths
	string includes_dir <- "../includes/" + city + "/";
	string includes_shp_dir <- includes_dir + "shapefiles/";
	string pollution_rasters_dir <- includes_dir + "pollution_rasters/";
	string generated_dir <- "../generated/" + city + "/";
	string population_csv_dir <- generated_dir + "synthetic_population" + (test_population ? "_test/" : "/");

	string bounds_path <- includes_shp_dir + "bounds.shp";
	string cleaned_roads_path <- generated_dir + "preprocessed_shapefiles/roads.shp";
	string cleaned_buildings_path <- generated_dir + "/preprocessed_shapefiles/buildings.shp";
	string sp_matrix_path <- generated_dir + "shortest_paths.csv";
}

/**
 * Name: Deplacementdevelos
 * Based on the internal empty template.
 * Author: nathancoisne
 * Tags:
 */


model Deplacementdevelos

/*
 * This model evaluates the capacity of each of the sensor networks to reproduce the diurnal cycle of the pollutants studied.
 *
 */

import "params.gaml"

global {

	file bound <- shape_file("../includes/Marseille/boundary_Marseille.shp");

	// true : récuperer les max de pollution horaire du polluant correspondant
	geometry shape <- envelope(bound);

	// coordonees des rasters de pollution
	float min_x <- 889462.50000;
	float min_y <- 6236287.50000;
	float max_x <- 905062.50000;
	float max_y <- 6254412.50000;

	file measures_csv <- csv_file("../results/Marseille/measures_" + number_of_sensors + ".csv",true);

	init{
		// creation d'un tableau de pas de temps 5 secondes, qui met dans chaque ligne le max mesuré à cette date

		create measure from: measures_csv;

		loop m over: measure {
			string time_m <- (((m.time_of_measure split_with "'(")[1]) split_with ")'")[0];
			m.int_date_measure <- int(date(time_m));
		}

		list<int> list_of_date;
		int beginnig_date <- int(date('2021-05-27 01:00:00'));
		int end_date <- int(date('2021-05-28 00:00:00'));

		loop i from: beginnig_date to: end_date step: 5{
			list_of_date << i;
		}

		list<float> max_pollution;

		loop i over: list_of_date{
			float max_pollution_i <- 0.0;
			loop m over: measure where (each.int_date_measure = i){
				if m.NO2_concentration > max_pollution_i {
					max_pollution_i <- m.NO2_concentration;
				}
			}
			max_pollution << max_pollution_i;
		}

		matrix pollution <- append_horizontally(matrix(list_of_date), matrix(max_pollution));
		pollution <- transpose(pollution);


		save pollution to: "../results/Marseille/max_NO2_measured.csv" type: "csv";

		// mise en mémoire du cube de pollution NO2, O3, PM10, PM25 (24 rasters horaires)
		list<matrix<float>> NO2_rasters;
		list<matrix<float>> O3_rasters;
		list<matrix<float>> PM10_rasters;
		list<matrix<float>> PM25_rasters;

		list<float> NO2_max;
		list<float> O3_max;
		list<float> PM10_max;
		list<float> PM25_max;


		if measure_NO2 {
			// raster heure 0 manquant pour la journée du 27
			matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});
			NO2_rasters << pollution_raster_float;

			loop i from: 1 to: 23{

				string path_grid;
				if (i < 10){
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_NO2_202105270' + i + '_202105270' + i + '.tif';
				}
				else{
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_NO2_20210527' + i + '_20210527' + i + '.tif';
				}

				matrix my_data <- grid_file(path_grid) as_matrix({624, 725});

				matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});

				loop j from: 0 to: 623{
					loop k from: 0 to: 724{

						pollution_raster_float[j, k] <- float (my_data[j, k] get("grid_value"));

					}
				}
				write ('raster NO2 ' + i + ' chargé');
				write('max: ' + max(pollution_raster_float));
				NO2_max << max(pollution_raster_float);

				NO2_rasters << pollution_raster_float;
			}
			save NO2_max to: "../results/Marseille/max_NO2.csv" type: "csv";
		}

		if measure_O3 {

			matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});
			O3_rasters << pollution_raster_float;

			loop i from: 1 to: 23{

				string path_grid;
				if (i < 10){
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_O3_202105270' + i + '_202105270' + i + '.tif';
				}
				else{
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_O3_20210527' + i + '_20210527' + i + '.tif';
				}

				matrix my_data <- grid_file(path_grid) as_matrix({624, 725});

				matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});

				loop j from: 0 to: 623{
					loop k from: 0 to: 724{

						pollution_raster_float[j, k] <- float (my_data[j, k] get("grid_value"));

					}
				}
				write ('raster O3 ' + i + ' chargé');
				write('max: ' + max(pollution_raster_float));
				O3_max << max(pollution_raster_float);

				O3_rasters << pollution_raster_float;
			}
			save O3_max to: "../results/Marseille/max_O3.csv" type: "csv";
		}

		if measure_PM10 {

			matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});
			PM10_rasters << pollution_raster_float;

			loop i from: 1 to: 23{

				string path_grid;
				if (i < 10){
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_PM10_202105270' + i + '_202105270' + i + '.tif';
				}
				else{
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_PM10_20210527' + i + '_20210527' + i + '.tif';
				}

				matrix my_data <- grid_file(path_grid) as_matrix({624, 725});

				matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});

				loop j from: 0 to: 623{
					loop k from: 0 to: 724{

						pollution_raster_float[j, k] <- float (my_data[j, k] get("grid_value"));

					}
				}
				write ('raster PM10 ' + i + ' chargé');
				write('max: ' + max(pollution_raster_float));
				PM10_max << max(pollution_raster_float);

				PM10_rasters << pollution_raster_float;
			}
			save PM10_max to: "../results/Marseille/max_PM10.csv" type: "csv";
		}

		if measure_PM25 {

			matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});
			PM25_rasters << pollution_raster_float;

			loop i from: 1 to: 23{

				string path_grid;
				if (i < 10){
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_PM25_202105270' + i + '_202105270' + i + '.tif';
				}
				else{
					path_grid <- '../includes/Marseille/pollution_model/raster_dep13_PM25_20210527' + i + '_20210527' + i + '.tif';
				}

				matrix my_data <- grid_file(path_grid) as_matrix({624, 725});

				matrix<float> pollution_raster_float <- 0.0 as_matrix({624, 725});

				loop j from: 0 to: 623{
					loop k from: 0 to: 724{

						pollution_raster_float[j, k] <- float (my_data[j, k] get("grid_value"));

					}
				}
				write ('raster PM25 ' + i + ' chargé');
				write('max: ' + max(pollution_raster_float));
				PM25_max << max(pollution_raster_float);

				PM25_rasters << pollution_raster_float;
			}
			save PM25_max to: "../results/Marseille/max_PM25.csv" type: "csv";
		}
	}
}

species measure {
	int ID;
	string name_of_agent;
	float longitude min: min_x max: max_x - 0.1;
	float latitude min: min_y max: max_y - 0.1;
	string time_of_measure;
	int int_date_measure;
	float NO2_concentration;
	float O3_concentration;
	float PM10_concentration;
	float PM25_concentration;
}

experiment pollutant type: gui {

}

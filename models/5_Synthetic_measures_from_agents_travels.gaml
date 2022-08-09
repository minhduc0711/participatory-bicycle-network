/**
 * Name: Deplacementdevelos
 * Based on the internal empty template.
 * Author: nathancoisne
 * Tags:
 */


model Deplacementdevelos

/*
 * This model generates pollution measures from the trips generated by 'travel agents'. Pollution data are extracted from a hourly pollution model from AtmoSud (date: 27/05/2021)
 *
 */

import "params.gaml"

global {
	file bound <- shape_file("../includes/Marseille/boundary_Marseille.shp");

	geometry shape <- envelope(bound);

	// coordonees des rasters de pollution
	float min_x <- 889462.50000;
	float min_y <- 6236287.50000;
	float max_x <- 905062.50000;
	float max_y <- 6254412.50000;

	int compteur_ID <- 0;

	init {
		map<string, map<string, field>> pollution_raster_map <- map<string, map<string, field>>([
			"NO2"::[], "O3"::[], "PM10"::[], "PM25"::[]
		]);
		map<string, bool> is_pollutant_measured <- [
			"NO2"::measure_NO2,
			"O3"::measure_O3,
			"PM10"::measure_PM10,
			"PM25"::measure_PM25
		];
		map<string, bool> is_population_measured <- [
			"worker"::workers,
			"student"::students,
			"leisure"::leisures
		];

		if (test_population) {
			create worker from: csv_file( "../results/Marseille/synthetic_population_test/worker.csv",true);
			create student from: csv_file( "../results/Marseille/synthetic_population_test/student.csv",true);
			create leisure from: csv_file( "../results/Marseille/synthetic_population_test/leisure.csv",true);
		} else {
			create worker from: csv_file( "../results/Marseille/synthetic_population/worker.csv",true);
			create student from: csv_file( "../results/Marseille/synthetic_population/student.csv",true);
			create leisure from: csv_file( "../results/Marseille/synthetic_population/leisure.csv",true);
		}

		string pollution_raster_dir_path <- "../includes/Marseille/pollution_model/";
		loop pol_type over: is_pollutant_measured.keys {
			if is_pollutant_measured[pol_type] {
				string raster_dir_path <- pollution_raster_dir_path + pol_type + "/";
				file raster_dir <- folder(raster_dir_path);

				loop fname over: raster_dir {
					list<string> comps <- fname split_with ".";
					string ext <- comps[length(comps) - 1];
					string timestamp <- (comps[0] split_with "_")[4];
					date ts_date <- date(timestamp, "yyyyMMddHH");
					// TODO: rm the 2nd condition when generating trips for 3 days
					if ext = "tif" and ts_date.day = 27 {
						write "Reading from " + fname;
						field f <- field(grid_file(raster_dir_path + fname));
						pollution_raster_map[pol_type][timestamp] <- f;
					}
				}
			}
		}

		// Randomly select a small subset of agents who will be equipped with sensors
		map<string, int> population_sizes <- [
			"worker"::length(worker),
			"student"::length(student),
			"leisure"::length(leisure)
		];
		map<string, list<int>> people_with_sensors <- [
			"worker"::[], "student"::[], "leisure"::[]
		];
		if not entire_population {
			loop i from: 0 to: length(people_with_sensors) - 1 {
				string population <- people_with_sensors.keys[i];
				int n;
				if (i < length(people_with_sensors) - 1) {
					n <- round(population_sizes[population] / sum(population_sizes) * number_of_sensors);
				} else {
					// just to make sure everything sum up to number_of_sensors
					n <- number_of_sensors - sum(people_with_sensors collect length(each));
				}
				people_with_sensors[population] <- n among range(0, population_sizes[population]);
				write("Number of " + population + "s with sensors: " + n);
			}
		}

		bool rewrite <- true;
		loop population over: is_population_measured.keys {

			if is_population_measured[population] {
				write "generating measures for " + population;

				// TODO: why do measures need to be seperated in two directions?
				loop direction over: ["aller", "retour"] {
					string pos_shp_path <- "../results/Marseille/" + population + "/positions_" + direction + ".shp";
					create measure from: shape_file(pos_shp_path) with: [time_of_measure::(read("time")),
							name_of_agent::(read('agent'))]{
						int agent_id <- int((((name_of_agent split_with '[')[1]) split_with ']')[0]);
						if !entire_population and !(agent_id in people_with_sensors[population]) {
							do die;
						}

						ID <- compteur_ID;
						compteur_ID <- compteur_ID + 1;

						geometry CRS_2154 <- location CRS_transform("EPSG:2154");

						list<string> coord <- string(CRS_2154) split_with ",";

						latitude <- float(coord[1]);
						longitude <- float((coord[0] split_with "{")[0]);

						int cell_x <- int((longitude - min_x) / 25);
						int cell_y <- int((max_y - latitude) / 25);

						// Linearly interpolate the concentration value at
						// arbitrary timestamp using the 2 closest hourly values
						date d <- time_of_measure;
						date d0 <- d minus_minutes d.minute minus_seconds d.second;
						date d1 <- d0 add_hours 1;
						string t0 <- world.convert_date_to_str(d0);
						string t1 <- world.convert_date_to_str(d1);

						loop pol_type over: is_pollutant_measured.keys {
							if is_pollutant_measured[pol_type] {
								float p0 <- pollution_raster_map[pol_type][t0][cell_x, cell_y];
								float p1 <- pollution_raster_map[pol_type][t1][cell_x, cell_y];
								self.conc_map[pol_type] <- world.interp(d, d0, d1, p0, p1);
							}
						}

						string save_path <- entire_population ? "../results/Marseille/student/measures_student.csv" :
							"../results/Marseille/measures_" + number_of_sensors + ".csv";
						save [ID, name_of_agent, longitude, latitude, string(time_of_measure),
							conc_map["NO2"], conc_map["O3"], conc_map["PM10"], conc_map["PM25"]]
								to: save_path type: "csv" rewrite: rewrite;
						rewrite <- false;
					}
					ask measure{ do die; }
				}
			}
		}
	}

	// Converts a date object into a string in the "yyyyMMddHH" format,
	// which is how the pollution rasters are named.
	// At the moment, GAMA doesn't seem to have a built-in date2str op with custom format string
	string convert_date_to_str(date d) {
		string s <- string(d);
		s <- (s split_with ":")[0];
		s <- replace(s, " ", "");
		s <- replace(s, "-", "");
		return s;
	}

	// Linearly interpolates two floats corresponding to two dates
	float interp(date d, date d0, date d1, float y0, float y1) {
		int x <- int(d);
		int x0 <- int(d0);
		int x1 <- int(d1);
		return (y0 * (x1 - x) + y1 * (x - x0)) / (x1 - x0);
	}
}

species measure {
	int ID;
	string name_of_agent;
	float longitude min: min_x max: max_x - 0.1;
	float latitude min: min_y max: max_y - 0.1;
	date time_of_measure;
	float NO2_concentration;
	float O3_concentration;
	float PM10_concentration;
	float PM25_concentration;

	map<string, float> conc_map <- [
		"NO2"::-1.0, "O3"::-1.0, "PM10"::-1.0, "PM25"::-1.0
	];
}

species people skills: [moving] {
	int ID;
}

species worker parent: people {
}

species student parent: people{
}

species leisure parent: people{
}

experiment synthetic_measures type: gui {

}

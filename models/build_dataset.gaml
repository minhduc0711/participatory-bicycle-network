/**
 * Name: Deplacementdevelos
 * Based on the internal empty template.
 * Author: nathancoisne
 * Tags:
 */


model Deplacementdevelos


import "params.gaml"

global {
	// Extract the rasters' extent to align the rasters with agents' positions
	// Note that all rasters must share the same extent
	// file grid_data <- grid_file("../includes/aix.tif");
	string no2_dir <- pollution_rasters_dir + "NO2/";
	string random_raster <- no2_dir + first(folder(no2_dir));
	geometry raster_geom <- envelope(grid_file(random_raster));
	float min_x <- raster_geom.points[0].x;
	float min_y <- raster_geom.points[2].y;
	float max_x <- raster_geom.points[2].x;
	float max_y <- raster_geom.points[0].y;

	file bound <- shape_file(bounds_path);
	geometry shape <- envelope(bound);
	file shape_file_buildings_ign <- shape_file(includes_shp_dir + "buildings_ign.shp");
	file shape_file_roads_ign <- shape_file(includes_shp_dir + "roads_ign.shp");
	file shape_file_roads_osm <- shape_file(includes_shp_dir + "roads_osm.shp");
	file shape_file_vegetation <- shape_file(includes_shp_dir + "vegetation.shp");

	int compteur_ID <- 0;
	list<string> files_written;

	init {
		// Preparations for extracting environmental features
		create building_ign from: shape_file_buildings_ign with: [height::float(read("HAUTEUR"))];
		create road_ign from: shape_file_roads_ign;
		list<road_ign> rd_1_voie <- road_ign where (each.NB_VOIES = 1);
		list<road_ign> rd_2_voie <- road_ign where (each.NB_VOIES = 2);
		list<road_ign> rd_3_voie <- road_ign where (each.NB_VOIES = 3);
		list<road_ign> rd_4_voie <- road_ign where (each.NB_VOIES = 4);
		list<road_ign> rd_5_voie <- road_ign where (each.NB_VOIES = 5);
		list<road_ign> rd_6_voie <- road_ign where (each.NB_VOIES = 6);
		list<road_ign> list_rd_0_4_width <- road_ign where (each.LARGEUR <= 4.0);
		list<road_ign> list_rd_4_6_width <- road_ign where (each.LARGEUR > 4.0 and each.LARGEUR <= 6.0);
		list<road_ign> list_rd_6_8_width <- road_ign where (each.LARGEUR > 6.0 and each.LARGEUR <= 8.0);
		list<road_ign> list_rd_8_max_width <- road_ign where (each.LARGEUR > 8.0);

		create primary_road_osm from: shape_file_roads_osm;
		list<string> primary_classes <- ["primary", "motorway", "motorway_link", "trunk", "trunk_link"];
		ask primary_road_osm {
			if !(primary_classes contains fclass) {
				do die;
			}
		}

		create vegetation from: shape_file_vegetation;
		list<vegetation> list_bois <- vegetation where (each.NATURE = 'Bois');
		list<vegetation> list_foret <- vegetation where (each.NATURE = 'Forêt fermée de conifères' or each.NATURE = 'Forêt fermée de feuillus'
				or each.NATURE = 'Forêt fermée mixte' or each.NATURE = 'Forêt ouverte');
		list<vegetation> list_haie <- vegetation where (each.NATURE = 'Haie');

		// The target variables
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

		create worker  from: csv_file(population_csv_dir + "worker.csv",true);
		create student from: csv_file(population_csv_dir + "student.csv",true);
		create leisure from: csv_file(population_csv_dir + "leisure.csv",true);

		// Load the pollution rasters
		loop pol_type over: is_pollutant_measured.keys {
			if is_pollutant_measured[pol_type] {
				string raster_dir_path <- pollution_rasters_dir + pol_type + "/";
				file raster_dir <- folder(raster_dir_path);

				loop fname over: raster_dir {
					list<string> comps <- fname split_with ".";
					string ext <- comps[length(comps) - 1];
					string timestamp <- (comps[0] split_with "_")[4];
					date ts_date <- date(timestamp, "yyyyMMddHH");
					// TODO: remove the 2nd condition when generating trips for other dates
					if ext = "tif" and ts_date.day = 27 {
						write "Reading pollution raster: " + fname;
						field f <- field(grid_file(raster_dir_path + fname));
						pollution_raster_map[pol_type][timestamp] <- f;
					}
				}
			}
		}

		// Randomly select a subset of cyclists who will be equipped with sensors

		map<string, list<string>> people_with_sensors <- [
			"worker"::[], "student"::[], "leisure"::[]
		];
		map<string, list<string>> agent_names <- [];
		// Retrieve the names of all cyclist agents
		loop population over: is_population_measured.keys {
			string pos_csv_path <- generated_dir + population + "/positions_aller" + ".csv";
			matrix table <- matrix(csv_file(pos_csv_path));
			list<string> names <- remove_duplicates(table column_at 0);
			agent_names[population] <- names;
		}
		
		if not entire_population {
			// Distribute the sensors among different populations 
			// while maintaining the population ratio
			loop i from: 0 to: length(people_with_sensors) - 1 {
				string population <- people_with_sensors.keys[i];
				int n;
				if (i < length(people_with_sensors) - 1) {
					n <- round(length(agent_names[population]) / sum(agent_names collect length(each)) * number_of_sensors);
				} else {
					// just to make sure everything sum up to number_of_sensors
					n <- number_of_sensors - sum(people_with_sensors collect length(each));
				}
				people_with_sensors[population] <- sample(agent_names[population], n, false);
				write("Number of " + population + "s with sensors: " + n);
			}
		}
		write people_with_sensors;

		// Build the dataset
		loop population over: is_population_measured.keys {
			if is_population_measured[population] {
				write "generating measures for " + population;

				// TODO: why do measures need to be separated in two directions?
				loop direction over: ["aller", "retour"] {
					string pos_csv_path <- generated_dir + population + "/positions_" + direction + ".csv";
					matrix table <- matrix(csv_file(pos_csv_path));
					loop i from: 1 to: table.rows - 1 {
						string name_of_agent <- table[0, i];
//						int agent_id <- int(regex_matches(name_of_agent, "\\d+")[0]);
						if entire_population or (name_of_agent in people_with_sensors[population]) {
							int ID <- compteur_ID;
							compteur_ID <- compteur_ID + 1;

							float lon <- table[2, i];
							float lat <- table[3, i];
							// no clue how he knew to divide by 25
							int cell_x <- int((lon - min_x) / 25);
							int cell_y <- int((max_y - lat) / 25);

							// GENERATE FEATURES
							float road_0_4_width; // longueur de route dans le disque ayant comme attribut : largeur <= 4
							float road_4_6_width; // longueur de route dans le disque ayant comme attribut : 4 < largeur <= 6
							float road_6_8_width; // longueur de route dans le disque ayant comme attribut : 6 < largeur <= 8
							float road_8_max_width; // longueur de route dans le disque ayant comme attribut : 8 < largeur
							float voie_1;
							float voie_2;
							float voie_3;
							float voie_4;
							float voie_5;
							float voie_6;
							float buildings_volume;
							float distance_to_main_road;
							float bois; //surface de bois dans le disque
							float foret;
							float haie;

							point location_gama <- point(to_GAMA_CRS({lon, lat}, 'EPSG:2154'));
							geometry disque <- circle(50, location_gama);

							loop build over: building_ign overlapping disque{
								float surface_inter <- (build inter disque).area;
								buildings_volume <- buildings_volume + build.height * surface_inter;
							}

							loop rd over: rd_1_voie overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								voie_1 <- voie_1 + perimeter_inter;
							}

							loop rd over: rd_2_voie overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								voie_2 <- voie_2 + perimeter_inter;
							}

							loop rd over: rd_3_voie overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								voie_3 <- voie_3 + perimeter_inter;
							}

							loop rd over: rd_4_voie overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								voie_4 <- voie_4 + perimeter_inter;
							}

							loop rd over: rd_5_voie overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								voie_5 <- voie_5 + perimeter_inter;
							}

							loop rd over: rd_6_voie overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								voie_6 <- voie_6 + perimeter_inter;
							}

							loop rd over: list_rd_0_4_width overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								road_0_4_width <- road_0_4_width + perimeter_inter;
							}

							loop rd over: list_rd_4_6_width overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								road_4_6_width <- road_4_6_width + perimeter_inter;
							}

							loop rd over: list_rd_6_8_width overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								road_6_8_width <- road_6_8_width + perimeter_inter;
							}

							loop rd over: list_rd_8_max_width overlapping disque{
								float perimeter_inter <- (rd inter disque).perimeter;
								road_8_max_width <- road_8_max_width + perimeter_inter;
							}

							loop veg over: list_bois overlapping disque{
								float area_inter <- (veg inter disque).area;
								bois <- bois + area_inter;
							}

							loop veg over: list_foret overlapping disque{
								float area_inter <- (veg inter disque).area;
								foret <- foret + area_inter;
							}

							loop veg over: list_haie overlapping disque{
								float area_inter <- (veg inter disque).area;
								haie <- haie + area_inter;
							}

							distance_to_main_road <- location_gama distance_to (primary_road_osm closest_to location_gama);

							// GENERATE REGRESSION TARGETS
							// Linearly interpolate the concentration value at
							// arbitrary timestamp using the 2 closest hourly values
							date d <- date(table[1, i]);
							date d0 <- d minus_minutes d.minute minus_seconds d.second;
							date d1 <- d0 add_hours 1;
							string t0 <- world.convert_date_to_str(d0);
							string t1 <- world.convert_date_to_str(d1);

							map<string, float> conc_map <- [
								"NO2"::-1.0, "O3"::-1.0, "PM10"::-1.0, "PM25"::-1.0
							];
							loop pol_type over: is_pollutant_measured.keys {
								if is_pollutant_measured[pol_type] {
									float p0 <- pollution_raster_map[pol_type][t0][cell_x, cell_y];
									float p1 <- pollution_raster_map[pol_type][t1][cell_x, cell_y];
									conc_map[pol_type] <- world.interp(d, d0, d1, p0, p1);
								}
							}
							string save_path <- generated_dir + "measures_" +
									(entire_population ? population : number_of_sensors) + ".csv";
							// Rewrite the existing CSV files first
							bool rewrite <- false;
							if !(files_written contains save_path) {
								rewrite <- true;
								add save_path to: files_written;
							}
							save [ID, name_of_agent, lon, lat, string(d),
								buildings_volume, voie_1, voie_2, voie_3, voie_4, voie_5, voie_6,
								road_0_4_width, road_4_6_width, road_6_8_width, road_8_max_width,
								distance_to_main_road, bois, foret, haie,
								conc_map["NO2"], conc_map["O3"], conc_map["PM10"], conc_map["PM25"]]
									to: save_path type: "csv" rewrite: rewrite;
						}
					}
				}
			}
		}
	}

	// Converts a date object into a string in the "yyyyMMddHH" format,
	// which is how the pollution rasters are named.
	// At the moment, GAMA doesn't seem to have a built-in date2str op that accepts a custom format string
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

species road_ign {
	float LARGEUR;
	int NB_VOIES;
}

species primary_road_osm {
	string fclass;
}

species building_ign {
	int id;
	string type;
	string types_str;
	list<string> types;
	float height;
}

species vegetation {
	string NATURE; //Bois, Forêt fermée de conifères, Forêt fermée de feuillus, Forêt fermée mixte, Forêt ouverte, Haie, Lande ligneuse, Verger, Vigne (types BD TOPO)
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

experiment exp type: gui {
	output {
	 display "My display" { 
		species building_ign;
//		species disk;
	 }
	}
}

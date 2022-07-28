/**
 * Name: Deplacementdevelos
 * Based on the internal empty template.
 * Author: nathancoisne
 * Tags:
 */


model Deplacementdevelos

/* Génération d'une population synthétique de cyclistes
 * Trois classes sociales sont représentées : travailleurs, étudiants et trajets de loisi
 * Sources : Mobiliscope, données 'occupation des résidents par quartier'
 *           INSEE household surveys
 *
 *
 */

import "params.gaml"

global {

	file bound <- shape_file("../includes/" + city + "/boundary_" + city + ".shp");

	file shape_file_buildings; // building contenant les data osm, ign, pois

	file shape_file_quartiers; // shapefile des quartiers de la ville considérée, importée de Mobiliscope

	file residents_csv_file; // fichier contenant le nombre de résidents pour chaque quartier, importé de Mobiliscope

	geometry shape <- envelope(bound);

	// Etalonnage d'un modèle gravitaire pour fixer les trajets des agents (leur destination): + le coeff est grand + les trajets sont courts
	float worker_adaptative_coeff <- 0.00083;  // distance moyenne : 2000 m
	float student_adaptative_coeff <- 0.00095; // distance moyenne : 1600 m
	float leisure_adaptative_coeff <- 0.00083; // distance moyenne : 2000 m
	float delivery_adaptative_coeff <- 0.0005; // distance moyenne : 3000 m


	int hour_early_leisure_start <- 11;
	int hour_late_leisure_start <- 15;

	int hour_early_leisure_end <- 14;
	int hour_late_leisure_end <- 18;

	int hour_early_delivery_midi_start <- 11;
	int hour_late_delivery_midi_start <- 13;

	int hour_early_delivery_soir_start <- 18;
	int hour_late_delivery_soir_start <- 20;

	list<string> living_places <- ["house", "apartments", "dormitory", "hotel", "residential", "Résidentiel"];

	list<string> work_places <- ["industrial", "office", "construction", "garages", "hospital", "service", "Commercial et services", "commercial",
		"bakery", "bank", "bicycle_shop", "bookshop", "butcher", "cafe", "car_dealership", "community_centre", "courthouse",
		"dentist", "department_store", "doctors", "fire_station", "florist", "furniture_shop", "greengrocer", "guesthouse",
		"hairdresser", "kindergarten", "kiosk", "library", "mall", "optician", "pharmacy", "police", "post_office", "prison",
		"public_building", "retail", "supermarket", "town_hall", "travel_agent", "warehouse", "wastewater_plant", "water_works"];

	list<string> study_places <- ["university", "college", "school", "library"];

	list<string> eating_places <- ["fast_food", "restaurant"];

	list<string> leisure_places <- ["commercial", "kiosk", "chapel", "church", "service", "Sportif", "Commercial et services", "Religieux", "religious",
		"bar", "buddhist", "cafe", "car_wash", "christian", "christian_catholic", "christian_evangelical", "christian_orthodox", "christian_protestant",
		"cinema", "clothes", "convenience", "doityourself", "dog_park", "florist", "fort", "fountain", "garden_centre", "gift_shop", "golf_course", "jewish",
		"mall", "museum", "muslim_sunni", "newsagent", "nightclub", "park", "picnic_site", "pitch", "playground", "pub", "sports_centre", "stadium",
		"supermarket", "swimming_pool", "theatre"  ];

	list<string> tourism_places <- ["archaeological", "arts_centre", "artwork", "attraction", "castle", "chapel", "church", "Religieux", "religious", "buddhist",
		"christian", "christian_catholic", "christian_evangelical", "christian_orthodox", "christian_protestant", "fort", "fountain", "garden_centre",
		"gift_shop", "graveyard", "jewish", "memorial", "monument", "museum", "muslim_sunni", "park", "ruins", "stadium", "theatre", "tourist_info", "tower"];


	init {
		string includes_dir <- "../includes/" + city + "/";
		// building contenant les data osm, ign, pois
		shape_file_buildings <- shape_file(includes_dir + "buildings.shp");
		shape_file_quartiers <- shape_file(includes_dir + "sectors.shp");
		//infos de population résidente dans chaque quartier
		residents_csv_file <- csv_file(includes_dir + "occ_nb.csv", ",");

		matrix data <- matrix(residents_csv_file);
		create building from: shape_file_buildings with: [id::int(read("id"))] {

			types <- types_str split_with ",";
		}

		create quarter from: shape_file_quartiers with: [ID::int(read("CODE_SEC")), name::read("LIB"), centre::int(read("centre"))]{
			// Ignore the quarters that have very small or no overlap with the region of interest
			if not (self overlaps world) {
				do die;
			}
			coeff_surface <- (world inter self).area / self.shape.area;
			if coeff_surface < 0.1 {
				do die;
			}

			active_pop <- int(data[2, ID - 1]); // le nombre de travailleurs logeant dans le quartier = le nombre d'actifs présents dans le quartier à 4am
			students_pop <- int(data[3, ID - 1]);
			retired_pop <- int(data[5, ID - 1]);
			inactive_pop <- int(data[6, ID - 1]);
			without_job_pop <- int(data[4, ID - 1]);

			write("id : " + ID + " coeff : " + coeff_surface);

			if coeff_surface < 0.98 {
				active_pop <- int(active_pop * coeff_surface);
				students_pop <- int(students_pop * coeff_surface);
				retired_pop <- int(retired_pop * coeff_surface);
				inactive_pop <- int(inactive_pop * coeff_surface);
				without_job_pop <- int(without_job_pop * coeff_surface);
			}

			if (centre = 1){
				is_city_centre <- true;
				color <- #orange;
			}
			else{color <- #yellow;}
		}

		list<building> residential_buildings <- building where (not empty(living_places inter each.types));
		list<building> university_buildings <- building where (not empty(study_places inter each.types));
		list<building> work_buildings <- building where (not empty(work_places inter each.types));
		list<building> leisure_buildings <- building where (not empty(leisure_places inter each.types));
		list<building> eat_buildings <- building where (not empty(eating_places inter each.types));
		list<building> tourism_buildings <- building where (not empty(tourism_places inter each.types));

		// placement des agents par quartier

		int normalized_delivery_number;
		int number_of_delivery;

		if city = "Marseille"{number_of_delivery <- 850;}
		if city = "Toulouse"{number_of_delivery <- 570;}

		string file_path <- "../results/" + city + "/synthetic_population";
		if test_population{file_path <- file_path + "_test";}

		bool rewrite_csv_workers <- true;
		bool rewrite_csv_students <- true;
		bool rewrite_csv_leisure <- true;
		bool rewrite_csv_delivery_day <- true;
		bool rewrite_csv_delivery_night <- true;
		loop quart over: quarter {
			write("population quartier " + quart.ID);
			float cyclist_proportion;

			// définition de la proportion de cyclistes parmi la population totale
			if quart.is_city_centre{ // proportion de cyclistes en centre-ville deux fois plus élevée (3.9%) qu'en périphérie (2.2%)
				cyclist_proportion <- 0.039;
				normalized_delivery_number <- 2 * int(number_of_delivery / (length(quarter) + length(quarter where each.is_city_centre)));
			}

			else{
				cyclist_proportion <- 0.022;
				normalized_delivery_number <- int(number_of_delivery / (length(quarter) + length(quarter where each.is_city_centre)));
			}
			// TODO: For some reason, this number did not depend on the `coeff_surface` before
			normalized_delivery_number <- int(normalized_delivery_number * quart.coeff_surface);

			int number_of_workers;
			if city = "Marseille"{number_of_workers <- int(quart.active_pop * 0.013);} // source particulière : INSEE
			if city = "Toulouse"{number_of_workers <- int(quart.active_pop * cyclist_proportion);}

			int number_of_students <- int(quart.students_pop * cyclist_proportion);
			int number_of_leisures <- int((quart.retired_pop + quart.without_job_pop) * cyclist_proportion);
			
			float test_ratio <- 0.05;
			if test_population {
				number_of_workers <- int(number_of_workers   * test_ratio);
				number_of_students <- int(number_of_students * test_ratio);
				number_of_leisures <- int(number_of_leisures * test_ratio);
				normalized_delivery_number <- int(normalized_delivery_number * test_ratio);
			}
			building living_place <- nil;
			building destination_place <- nil;
			point starting_loc;

			int int_go;
			int int_home;
			int go_out_hour;
			int go_out_min;
			int go_home_hour;
			int go_home_min;

			list<building> quarter_residential_buildings <- residential_buildings where (each overlaps quart);
			// Generate worker population
			loop times: number_of_workers {
				living_place <- one_of(quarter_residential_buildings);
				starting_loc <- any_location_in(living_place);
				destination_place <- rnd_choice(gravitational_model(living_place, work_buildings where (each.location distance_to living_place < 15000 #m), worker_adaptative_coeff));

				int_go <- int(gauss(120, 50)); // distribution gaussienne de l'heure de départ entre 6am et 10am
				go_out_hour <- int(int_go / 60) + 6;
				go_out_min <- int((int_go - (go_out_hour - 6) * 60) / 5) * 5;

				int_home <- int(gauss(120, 50));
				go_home_hour <- int(int_home / 60) + 15;
				go_home_min <- int((int_home - (go_home_hour - 15) * 60) / 5) * 5;

				save [go_out_hour, go_out_min, go_home_hour, go_home_min, living_place.id, destination_place.id] to: file_path + "/worker.csv" type:"csv" rewrite: rewrite_csv_workers;
				rewrite_csv_workers <- false;
			}

			// Generate student population
			loop times: number_of_students {
				living_place <- one_of(quarter_residential_buildings);
				starting_loc <- any_location_in(living_place);
				destination_place <- rnd_choice(gravitational_model(living_place, university_buildings where (each.location distance_to living_place < 15000 #m), student_adaptative_coeff));

				int_go <- int(gauss(90, 40));
				go_out_hour <- int(int_go / 60) + 6;
				go_out_min <- int((int_go - (go_out_hour - 6) * 60) / 5) * 5;

				int_home <- int(gauss(90, 40));
				go_home_hour <- int(int_home / 60) + 15;
				go_home_min <- int((int_home - (go_home_hour - 15) * 60) / 5) * 5;

				save [go_out_hour, go_out_min, go_home_hour, go_home_min, living_place.id, destination_place.id] to: file_path + "/student.csv" type:"csv" rewrite: rewrite_csv_students;
			}

			// Generate 'leisure' population
			loop times: number_of_leisures {
				living_place <- one_of(quarter_residential_buildings);
				location <- any_location_in(living_place);
				destination_place <- rnd_choice(gravitational_model(living_place, leisure_buildings where (each.location distance_to living_place < 15000 #m), leisure_adaptative_coeff));

				go_out_hour <- rnd(9, 12);
				go_out_min <- rnd(0, 59, 5);

				go_home_hour <- rnd(go_out_hour + 2, 21);
				go_home_min <- rnd(0, 59, 5);

				save [go_out_hour, go_out_min, go_home_hour, go_home_min, living_place.id, destination_place.id] to: file_path + "/leisure.csv" type:"csv" rewrite: rewrite_csv_leisure;
				rewrite_csv_leisure <- false;
			}

			// Generate shippers' population
			building restaurant_1;
			building restaurant_2;
			building restaurant_3;
			building residential_place_1;
			building residential_place_2;
			building residential_place_3;

			loop times: normalized_delivery_number {
				living_place <- one_of(quarter_residential_buildings);
				starting_loc <- any_location_in(living_place);
				list<building> close_restos <- eat_buildings where (each.location distance_to living_place < 5000 #m);
				list<building> close_residential_buildings <- residential_buildings where (each.location distance_to living_place < 5000 #m);

				bool is_day <- rnd(1.0) <= 0.40;
				string delivery_save_path;
				bool rewrite_delivery_csv;
				if (is_day) {
					go_out_hour <- rnd(hour_early_delivery_midi_start, hour_late_delivery_midi_start - 1);
					go_out_min <- rnd(0, 59, 5);
					delivery_save_path <- file_path + "/delivery_midi.csv";
					rewrite_delivery_csv <- rewrite_csv_delivery_day;
				} else {
					go_out_hour <- rnd(hour_early_delivery_soir_start, hour_late_delivery_soir_start - 1);
					go_out_min <- rnd(0, 59, 5);
					delivery_save_path <- file_path + "/delivery_soir.csv";
					rewrite_delivery_csv <- rewrite_csv_delivery_night;
				}

				restaurant_1 <- rnd_choice(gravitational_model(living_place, close_restos, delivery_adaptative_coeff));
				residential_place_1 <- rnd_choice(gravitational_model(restaurant_1, close_residential_buildings, delivery_adaptative_coeff));

				restaurant_2 <- rnd_choice(gravitational_model(residential_place_1, close_restos, delivery_adaptative_coeff));
				residential_place_2 <- rnd_choice(gravitational_model(restaurant_2, close_residential_buildings, delivery_adaptative_coeff));

				restaurant_3 <- rnd_choice(gravitational_model(residential_place_2, close_restos, delivery_adaptative_coeff));
				residential_place_3 <- rnd_choice(gravitational_model(restaurant_3, close_residential_buildings, delivery_adaptative_coeff));

				save [go_out_hour, go_out_min, living_place.id, restaurant_1.id, residential_place_1.id, restaurant_2.id, residential_place_2.id, restaurant_3.id,
					 residential_place_3.id]
						 to: delivery_save_path type:"csv" rewrite: rewrite_delivery_csv;
				if (is_day) {
					rewrite_csv_delivery_day <- false;
				} else {
					rewrite_csv_delivery_night <- false;
				}
			}
		}

//		write("Population de cyclistes à " + city + " :");
//		write("nombre de travailleurs : " + length(worker));
//		write("nombre d'étudiants : " + length(student));
//		write("nombre d'agents loisir : " + length(leisure));
//		write("nombre d'agents livreurs : " + length(delivery));
	}

	map<building, float> gravitational_model(building starting_place,
			list<building> destination_to_choose, float adaptative_coeff) {
		// À partir d'une location de départ starting_place, choisit une destination parmi la liste destination_to_choose, selon un modèle gravitaire étalonné par adaptative_coeff
		list<float> proba_list;
		loop build over:destination_to_choose{
			proba_list << exp(- adaptative_coeff * (starting_place distance_to build));
		}

		return create_map(destination_to_choose, proba_list); // retourne une map avec en clé la liste de buildings candidats, et en valeur la probabilité d'affectation du building
	}
}

species building {
	int id;
	string type;
	string types_str;
	list<string> types;
	float height;
	rgb color <- #gray;

	aspect base {
		draw shape color: color ;
	}
}

species quarter {
	int ID;
	string name;

	float coeff_surface;

	int active_pop;
	int students_pop;
	int retired_pop;
	int inactive_pop;
	int without_job_pop;

	int centre;
	bool is_city_centre; // si true : proportion de vélos 2x plus importante

	rgb color;
	aspect base {
		draw shape width: 6;
	}
}

experiment population_generation type: gui {
	output{

		display quarters {
			species quarter;
			//species building;
		}

		// TODO: fix these plots
//		display travel_distance {
//			chart "Distribution de la distance de trajet des travailleurs" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0, 0}{
//				data "0 - 1 km" value: worker count (each.living_place distance_to each.destination_place < 1000 #m) color: #blue;
//
//				data "1 - 2 km" value: worker count (each.living_place distance_to each.destination_place >= 1000 #m and each.living_place distance_to each.destination_place < 2000 #m) color: #blue;
//
//				data "2 - 3 km" value: worker count (each.living_place distance_to each.destination_place >= 2000 #m and each.living_place distance_to each.destination_place < 3000 #m) color: #blue;
//
//				data "3 - 4 km" value: worker count (each.living_place distance_to each.destination_place >= 3000 #m and each.living_place distance_to each.destination_place < 4000 #m) color: #blue;
//
//				data "4 - 5 km" value: worker count (each.living_place distance_to each.destination_place >= 4000 #m and each.living_place distance_to each.destination_place < 5000 #m) color: #blue;
//
//				data "5 - 6 km" value: worker count (each.living_place distance_to each.destination_place >= 5000 #m and each.living_place distance_to each.destination_place < 6000 #m) color: #blue;
//
//				data "6 - 7 km" value: worker count (each.living_place distance_to each.destination_place >= 6000 #m and each.living_place distance_to each.destination_place < 7000 #m) color: #blue;
//
//				data "7 - 8 km" value: worker count (each.living_place distance_to each.destination_place >= 7000 #m and each.living_place distance_to each.destination_place < 8000 #m) color: #blue;
//
//				data "8 - 9 km" value: worker count (each.living_place distance_to each.destination_place >= 8000 #m and each.living_place distance_to each.destination_place < 9000 #m) color: #blue;
//
//				data "9 - 10 km" value: worker count (each.living_place distance_to each.destination_place >= 9000 #m and each.living_place distance_to each.destination_place < 10000 #m) color: #blue;
//
//				data "10 - 11 km" value: worker count (each.living_place distance_to each.destination_place >= 10000 #m and each.living_place distance_to each.destination_place < 11000 #m) color: #blue;
//
//				data "11 - 12 km" value: worker count (each.living_place distance_to each.destination_place >= 11000 #m and each.living_place distance_to each.destination_place < 12000 #m) color: #blue;
//
//				data "12 - 13 km" value: worker count (each.living_place distance_to each.destination_place >= 12000 #m and each.living_place distance_to each.destination_place < 13000 #m) color: #blue;
//
//				data "13 - 14 km" value: worker count (each.living_place distance_to each.destination_place >= 13000 #m and each.living_place distance_to each.destination_place < 14000 #m) color: #blue;
//
//				data "14 - 15 km" value: worker count (each.living_place distance_to each.destination_place >= 14000 #m and each.living_place distance_to each.destination_place < 15000 #m) color: #blue;
//
//				data "15 - 16 km" value: worker count (each.living_place distance_to each.destination_place >= 15000 #m and each.living_place distance_to each.destination_place < 16000 #m) color: #blue;
//
//				data "16 - 17 km" value: worker count (each.living_place distance_to each.destination_place >= 16000 #m and each.living_place distance_to each.destination_place < 17000 #m) color: #blue;
//
//				data "17 - 18 km" value: worker count (each.living_place distance_to each.destination_place >= 17000 #m and each.living_place distance_to each.destination_place < 18000 #m) color: #blue;
//
//				data "18 - 19 km" value: worker count (each.living_place distance_to each.destination_place >= 18000 #m and each.living_place distance_to each.destination_place < 19000 #m) color: #blue;
//
//				data "19 - 20 km" value: worker count (each.living_place distance_to each.destination_place >= 19000 #m and each.living_place distance_to each.destination_place < 20000 #m) color: #blue;
//			}
//
//			chart "Distribution de la distance de trajet des étudiants" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0, 0.5}{
//				data "0 - 1 km" value: student count (each.living_place distance_to each.destination_place < 1000 #m) color: #blue;
//
//				data "1 - 2 km" value: student count (each.living_place distance_to each.destination_place >= 1000 #m and each.living_place distance_to each.destination_place < 2000 #m) color: #blue;
//
//				data "2 - 3 km" value: student count (each.living_place distance_to each.destination_place >= 2000 #m and each.living_place distance_to each.destination_place < 3000 #m) color: #blue;
//
//				data "3 - 4 km" value: student count (each.living_place distance_to each.destination_place >= 3000 #m and each.living_place distance_to each.destination_place < 4000 #m) color: #blue;
//
//				data "4 - 5 km" value: student count (each.living_place distance_to each.destination_place >= 4000 #m and each.living_place distance_to each.destination_place < 5000 #m) color: #blue;
//
//				data "5 - 6 km" value: student count (each.living_place distance_to each.destination_place >= 5000 #m and each.living_place distance_to each.destination_place < 6000 #m) color: #blue;
//
//				data "6 - 7 km" value: student count (each.living_place distance_to each.destination_place >= 6000 #m and each.living_place distance_to each.destination_place < 7000 #m) color: #blue;
//
//				data "7 - 8 km" value: student count (each.living_place distance_to each.destination_place >= 7000 #m and each.living_place distance_to each.destination_place < 8000 #m) color: #blue;
//
//				data "8 - 9 km" value: student count (each.living_place distance_to each.destination_place >= 8000 #m and each.living_place distance_to each.destination_place < 9000 #m) color: #blue;
//
//				data "9 - 10 km" value: student count (each.living_place distance_to each.destination_place >= 9000 #m and each.living_place distance_to each.destination_place < 10000 #m) color: #blue;
//
//				data "10 - 11 km" value: student count (each.living_place distance_to each.destination_place >= 10000 #m and each.living_place distance_to each.destination_place < 11000 #m) color: #blue;
//
//				data "11 - 12 km" value: student count (each.living_place distance_to each.destination_place >= 11000 #m and each.living_place distance_to each.destination_place < 12000 #m) color: #blue;
//
//				data "12 - 13 km" value: student count (each.living_place distance_to each.destination_place >= 12000 #m and each.living_place distance_to each.destination_place < 13000 #m) color: #blue;
//
//				data "13 - 14 km" value: student count (each.living_place distance_to each.destination_place >= 13000 #m and each.living_place distance_to each.destination_place < 14000 #m) color: #blue;
//
//				data "14 - 15 km" value: student count (each.living_place distance_to each.destination_place >= 14000 #m and each.living_place distance_to each.destination_place < 15000 #m) color: #blue;
//
//				data "15 - 16 km" value: student count (each.living_place distance_to each.destination_place >= 15000 #m and each.living_place distance_to each.destination_place < 16000 #m) color: #blue;
//
//				data "16 - 17 km" value: student count (each.living_place distance_to each.destination_place >= 16000 #m and each.living_place distance_to each.destination_place < 17000 #m) color: #blue;
//
//				data "17 - 18 km" value: student count (each.living_place distance_to each.destination_place >= 17000 #m and each.living_place distance_to each.destination_place < 18000 #m) color: #blue;
//
//				data "18 - 19 km" value: student count (each.living_place distance_to each.destination_place >= 18000 #m and each.living_place distance_to each.destination_place < 19000 #m) color: #blue;
//
//				data "19 - 20 km" value: student count (each.living_place distance_to each.destination_place >= 19000 #m and each.living_place distance_to each.destination_place < 20000 #m) color: #blue;
//			}
//
//			chart "Distribution de la distance de trajet des leisure" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0.5, 0}{
//				data "0 - 1 km" value: leisure count (each.living_place distance_to each.destination_place < 1000 #m) color: #blue;
//
//				data "1 - 2 km" value: leisure count (each.living_place distance_to each.destination_place >= 1000 #m and each.living_place distance_to each.destination_place < 2000 #m) color: #blue;
//
//				data "2 - 3 km" value: leisure count (each.living_place distance_to each.destination_place >= 2000 #m and each.living_place distance_to each.destination_place < 3000 #m) color: #blue;
//
//				data "3 - 4 km" value: leisure count (each.living_place distance_to each.destination_place >= 3000 #m and each.living_place distance_to each.destination_place < 4000 #m) color: #blue;
//
//				data "4 - 5 km" value: leisure count (each.living_place distance_to each.destination_place >= 4000 #m and each.living_place distance_to each.destination_place < 5000 #m) color: #blue;
//
//				data "5 - 6 km" value: leisure count (each.living_place distance_to each.destination_place >= 5000 #m and each.living_place distance_to each.destination_place < 6000 #m) color: #blue;
//
//				data "6 - 7 km" value: leisure count (each.living_place distance_to each.destination_place >= 6000 #m and each.living_place distance_to each.destination_place < 7000 #m) color: #blue;
//
//				data "7 - 8 km" value: leisure count (each.living_place distance_to each.destination_place >= 7000 #m and each.living_place distance_to each.destination_place < 8000 #m) color: #blue;
//
//				data "8 - 9 km" value: leisure count (each.living_place distance_to each.destination_place >= 8000 #m and each.living_place distance_to each.destination_place < 9000 #m) color: #blue;
//
//				data "9 - 10 km" value: leisure count (each.living_place distance_to each.destination_place >= 9000 #m and each.living_place distance_to each.destination_place < 10000 #m) color: #blue;
//
//				data "10 - 11 km" value: leisure count (each.living_place distance_to each.destination_place >= 10000 #m and each.living_place distance_to each.destination_place < 11000 #m) color: #blue;
//
//				data "11 - 12 km" value: leisure count (each.living_place distance_to each.destination_place >= 11000 #m and each.living_place distance_to each.destination_place < 12000 #m) color: #blue;
//
//				data "12 - 13 km" value: leisure count (each.living_place distance_to each.destination_place >= 12000 #m and each.living_place distance_to each.destination_place < 13000 #m) color: #blue;
//
//				data "13 - 14 km" value: leisure count (each.living_place distance_to each.destination_place >= 13000 #m and each.living_place distance_to each.destination_place < 14000 #m) color: #blue;
//
//				data "14 - 15 km" value: leisure count (each.living_place distance_to each.destination_place >= 14000 #m and each.living_place distance_to each.destination_place < 15000 #m) color: #blue;
//
//				data "15 - 16 km" value: leisure count (each.living_place distance_to each.destination_place >= 15000 #m and each.living_place distance_to each.destination_place < 16000 #m) color: #blue;
//
//				data "16 - 17 km" value: leisure count (each.living_place distance_to each.destination_place >= 16000 #m and each.living_place distance_to each.destination_place < 17000 #m) color: #blue;
//
//				data "17 - 18 km" value: leisure count (each.living_place distance_to each.destination_place >= 17000 #m and each.living_place distance_to each.destination_place < 18000 #m) color: #blue;
//
//				data "18 - 19 km" value: leisure count (each.living_place distance_to each.destination_place >= 18000 #m and each.living_place distance_to each.destination_place < 19000 #m) color: #blue;
//
//				data "19 - 20 km" value: leisure count (each.living_place distance_to each.destination_place >= 19000 #m and each.living_place distance_to each.destination_place < 20000 #m) color: #blue;
//			}
//
//			chart "Distance moyenne des trajets en fonction du motif" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0.5, 0.5} {
//				list<float> travel_distance;
//
//				if(length(worker) != 0){
//					loop work over: worker{
//						travel_distance << work.living_place distance_to work.destination_place;
//					}
//					data "Travail" value: sum(travel_distance) / length(worker) color: #blue;
//				}
//
//				if(length(student) != 0){
//					travel_distance <- [];
//					loop stud over: student{
//						travel_distance << stud.living_place distance_to stud.destination_place;
//					}
//					data "Etude" value: sum(travel_distance) / length(student) color: #blue;
//				}
//
//				if(length(leisure) != 0){
//					travel_distance <- [];
//					loop leis over: leisure{
//						travel_distance << leis.living_place distance_to leis.destination_place;
//					}
//					data "Loisir" value: sum(travel_distance) / length(leisure) color: #blue;
//				}
//
//				if (length(delivery) != 0){
//					travel_distance <- [];
//					loop deli over: delivery {
//						travel_distance << deli.living_place distance_to deli.restaurant_1;
//					}
//					data "Distance domicile / restaurant 1" value: sum(travel_distance) / length(delivery) color: #blue;
//
//					travel_distance <- [];
//					loop deli over: delivery {
//						travel_distance << deli.restaurant_1 distance_to deli.residential_place_1;
//					}
//					data "Distance resto1 / resi1" value: sum(travel_distance) / length(delivery) color: #blue;
//				}
//			}
//		}
//
//		display hour_travel {
//			chart "Distribution de l'heure de départ des agents worker" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0, 0}{
//				loop i from: 0 to: 240 step: 5{
//					int hour_go <- int(i / 60);
//					data string(i) value: worker count (each.go_out_hour = int(i / 60) + 6 and each.go_out_min = int((i - (each.go_out_hour - 6) * 60) / 5) * 5) color: #blue;
//				}
//			}
//
//			chart "Distribution de l'heure de départ des agents student" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0.5, 0.5}{
//				loop i from: 0 to: 180 step: 5{
//					int hour_go <- int(i / 60);
//					data string(i) value: student count (each.go_out_hour = int(i / 60) + 6 and each.go_out_min = int((i - (each.go_out_hour - 6) * 60) / 5) * 5) color: #blue;
//				}
//			}
//		}
	}
}

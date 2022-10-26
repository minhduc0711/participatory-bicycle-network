/**
 * Name: Deplacementdevelos
 * Based on the internal empty template.
 * Author: nathancoisne
 * Tags:
 */


model Deplacementdevelos

/*
 * This model generates the daily trips (non-participatory trip = the shortest path) of a synthetic population of cyclists in Marseille
 * The living place, destination place and hour of leaving / coming home are already defined for each agent in the synthetic population
 *
 *
 */

import "params.gaml"

global {
	file shape_file_bounds <- shape_file(bounds_path);
	file shape_file_roads <- shape_file(cleaned_roads_path);
	file shape_file_buildings <- shape_file(cleaned_buildings_path);

	bool deliveries <- false;

	file worker_csv;

	file student_csv;

	file leisure_csv;

	file delivery_midi_csv;

	file delivery_soir_csv;
	list<string> files_written;

	geometry shape <- envelope(shape_file_bounds);

	float step <- 5#s;

	date starting_date <- date(2021, 5, 27, 7, 0);
	date stopping_date <- date(2021, 5, 29, 23, 0);

	float bicycle_speed <- 10 #km / #h;

	graph the_graph;
	bool paths_precomputed <- file_exists(sp_matrix_path);

	map<road,float> road_weights;

	reflex stop_simulation when: current_date = stopping_date {
		write "Simulation has reached the ending date of " + stopping_date;
		do pause;
	}

	init{
		worker_csv <- csv_file(population_csv_dir + "worker.csv", true);
		student_csv <- csv_file(population_csv_dir + "student.csv", true);
		leisure_csv <- csv_file(population_csv_dir + "leisure.csv", true);
		// delivery_midi_csv <- csv_file(population_csv_dir + "delivery_midi.csv",true);
		// delivery_soir_csv <- csv_file(population_csv_dir + "delivery_soir.csv",true);

		create building from: shape_file_buildings {
			types <- types_str split_with ",";
		}

		create road from: shape_file_roads with: [id::int(get("id")), fclass::read ("fclass"), speed_coeff::float(get("s_coeff")), maxspeed::int(get("maxspeed"))];

		the_graph <- as_edge_graph(road);
		ask road where not(each in the_graph.edges) {
			do die;
		}
		road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff); // speed_coeff depends on the type of road
		the_graph <- the_graph with_weights road_weights;
		if paths_precomputed {
			the_graph <- the_graph load_shortest_paths matrix(file(sp_matrix_path));
		}

		map<int,building> building_map <- building as_map (each.id::each);

		if workers{
			write("instanciate workers");

			create worker from: worker_csv with:[go_out_hour::int(get("go_out_hour")), go_out_min::int(get("go_out_min")), go_home_hour::int(get("go_home_hour")), go_home_min::int(get("go_home_min")),
				   id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{

				date_of_leaving_home <- date(2021, 5, 27, go_out_hour, go_out_min);
				date_of_leaving_dest <- date(2021, 5, 27, go_home_hour, go_home_min);

				living_place <- building_map[id_living_place];
				if living_place = nil {
					write "building " + id_living_place + " does not exist";
				}
				location <- any_location_in (living_place);
				destination_place <- building_map[id_destination_place];
				speed <- bicycle_speed;
				// TODO: remove these 2 lines
				// living_place <- building[10529];
				// destination_place <- building[13881];
				objective <- "resting";
				is_on_road <- false;
			}
		}

		if students{
			write("instanciate students");

			create student from: student_csv with:[go_out_hour::int(get("go_out_hour")), go_out_min::int(get("go_out_min")), go_home_hour::int(get("go_home_hour")), go_home_min::int(get("go_home_min")),
				   id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{

				date_of_leaving_home <- date(2021, 5, 27, go_out_hour, go_out_min);
				date_of_leaving_dest <- date(2021, 5, 27, go_home_hour, go_home_min);

				living_place <- building_map[id_living_place];
				location <- any_location_in (living_place);
				destination_place <- building_map[id_destination_place];
				speed <- bicycle_speed;

				objective <- "resting";
				is_on_road <- false;
			}
		}

		if leisures {
			write("instanciate leisures");
			create leisure from: leisure_csv with:[go_out_hour::int(get("go_out_hour")), go_out_min::int(get("go_out_min")), go_home_hour::int(get("go_home_hour")), go_home_min::int(get("go_home_min")),
				   id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{

				date_of_leaving_home <- date(2021, 5, 27, go_out_hour, go_out_min);
				date_of_leaving_dest <- date(2021, 5, 27, go_home_hour, go_home_min);

				living_place <- building_map[id_living_place];
				location <- any_location_in (living_place);
				destination_place <- building_map[id_destination_place];
				speed <- bicycle_speed;

				objective <- "resting";
				is_on_road <- false;
			}
		}
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
		draw shape * 0.5 color: color ;
	}
}

species road {
	int id;

	string fclass;

	int maxspeed;

	float speed_coeff;

	bool starting_road_aller;

	bool starting_road_retour;

	rgb color <- #orange;

	aspect base {
		draw shape color: color width: 1;
	}
}

species people skills: [moving] {
	rgb color;
	string positions_save_dir;

	int id_living_place;
	int id_destination_place;
	building living_place <- nil;
	building destination_place <- nil;

	path path_followed;

	int go_out_hour;
	int go_out_min;
	date date_of_leaving_home;

	date date_of_arriving_dest;

	path path_aller;
	list<road> list_of_roads_aller;
	list<position_agent> list_of_positions_aller;

	int go_home_hour;
	int go_home_min;
	date date_of_leaving_dest;

	date date_of_arriving_home;

	path path_retour;
	list<position_agent> list_of_positions_retour;
	list<road> list_of_roads_retour;

	bool is_on_road;

	string objective;

	point the_target <- nil;

	reflex time_to_leave when: current_date.hour = go_out_hour and current_date.minute = go_out_min and objective = "resting"{
		objective <- "working";
		the_target <- any_location_in (destination_place);


		// path_aller <- path_between(the_graph, location, the_target);

		// if path_aller != nil{
		// 	loop rd over: path_aller.edges{
		// 		list_of_roads_aller << road(int(rd));
		// 	}
		// }

		// list_of_roads_aller[0].starting_road_aller <- true;

		is_on_road <- true;
	}

	reflex time_to_go_home when: current_date.hour = go_home_hour and current_date.minute = go_home_min and objective = "working"{
		objective <- "resting";
		the_target <- any_location_in(living_place);


		// path_retour <- path_between(the_graph, location, the_target);

		// if path_retour != nil{
		// 	loop rd over: path_retour.edges{
		// 		list_of_roads_retour << road(int(rd));
		// 	}
		// }

		// list_of_roads_retour[0].starting_road_retour <- true;

		is_on_road <- true;
	}

	reflex move when: the_target != nil {
		point current_location <- location;

		path_followed <- goto(target: the_target, on: the_graph, return_path: true);
		if length(path_followed.edges) = 0 {
			write sample(current_location);
			write sample(the_target);
			write sample(objective);
			write sample(living_place);
			write sample(destination_place);
			ask world {
				do pause;
			}
		}

		do log_position;

		if the_target = location {
			the_target <- nil;
			is_on_road <- false;
			// if (objective = "working"){
			// 	date_of_arriving_dest <- copy(current_date);
			// }
			// if (objective = "resting"){
			// 	date_of_arriving_home <- copy(current_date);
			// }
		}
	}

	// Log the current position & date to a CSV file
	action log_position {
		string positions_save_path;
		if objective = "working"{
			positions_save_path <- positions_save_dir + "positions_aller.csv";
		} else if objective = "resting" {
			positions_save_path <- positions_save_dir + "positions_retour.csv";
		}

		// Rewrite the existing CSV files first
		bool rewrite <- false;
		if !(files_written contains positions_save_path) {
			rewrite <- true;
			add positions_save_path to: files_written;
		}

		point pt_2154 <- CRS_transform(location, "2154");
		float lon <- pt_2154.x;
		float lat <- pt_2154.y;
		string agent_name <- string(self);
		string date_of_presence <- string(current_date);
		save [agent_name, date_of_presence, lon, lat] to: positions_save_path type: "csv"
			rewrite: rewrite;
	}

	aspect base{
		draw circle(10) color: color border: #black;
	}
}

species worker parent: people {
	rgb color <- #black;
	string positions_save_dir <- "../generated/" + city + "/worker/";
}

species student parent: people{
	rgb color <- #green;
	string positions_save_dir <- "../generated/" + city + "/student/";
}

species leisure parent: people{
	rgb color <- #pink;
	string positions_save_dir <- "../generated/" + city + "/leisure/";
}

species position_agent {
	date date_of_presence;
	string name_of_agent;
}


experiment traffic type: gui {
	output{
		monitor clock value: current_date refresh: every(1#cycle);
		display city_display type: opengl {
			species worker aspect: base;
			species student aspect: base;
			species leisure aspect: base;
			species road aspect: base refresh: false;
			// species building aspect: base;
		}

		display nb_persons_on_road refresh: every(2#cycles){
			chart "Number of cyclists moving" type: series {
				data "Number of cyclists moving" value: (agents of_generic_species people) count (each.the_target != nil);
			}
		}
	}
}

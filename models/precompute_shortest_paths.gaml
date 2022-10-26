model precompute_shortest_paths

import "params.gaml"

global {
	file shape_file_buildings <- shape_file(cleaned_buildings_path); 
	file shape_file_roads <- shape_file(cleaned_roads_path);
	string result_csv_path <- "../generated/" + city + "/shortest_paths.csv";
	graph the_graph;
	init {
		create road from: shape_file_roads with: [id::int(get("id")), fclass::read ("fclass"), speed_coeff::float(get("s_coeff")), maxspeed::int(get("maxspeed"))];

		the_graph <- as_edge_graph(road);
		ask road where not(each in the_graph.edges) {
			do die;
		}
		map<road,float> road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff); // speed_coeff depends on the type of road
		the_graph <- the_graph with_weights road_weights;
		write sample(length(connected_components_of(the_graph)));
		write sample(length(the_graph.vertices));
		write sample(length(the_graph.edges));

//		the_graph <- the_graph with_shortest_path_algorithm #TransitNodeRouting;
//		 write "Computing all shortest paths";
//		 matrix ssp <- all_pairs_shortest_path(the_graph);
//		 save ssp type: "text" to: result_csv_path;
//		 write "Done";

		// Test using precomputed paths

		create building from: shape_file_buildings {
			types <- types_str split_with ",";
		}

		write "Not precomputed: ";
		create people number: 1;

		the_graph <- the_graph load_shortest_paths matrix(file(result_csv_path));

		write "Precomputed: ";
		create people number: 1;

	}
}
species people skills: [moving] {
	init {
		location <- any_location_in(building[0]);
		float t0 <- machine_time;
		path path_followed <- goto(target: any_location_in(building[25]), 
				on: the_graph, return_path: true);
		write sample(path_followed);
		float t1 <- machine_time;
		write "Time: " + string((t1 - t0) / 1e3);
	}
}
species road schedules: [] {
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

experiment name type: gui {
	output {}
}

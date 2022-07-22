/**
 * Name: Deplacementdevelos
 * Based on the internal empty template.
 * Author: nathancoisne
 * Tags:
 */


model Deplacementdevelos

/* Modélisation du déplacement d'une flotte de cyclistes équipés de capteurs de pollution
 * Sortie : une carte des zones mesurées est générée toutes les heures
 * Sortie : un compte rendu du trajet de chaque cycliste, avec des points de rendez-vous
 *
 */

import "params.gaml"

global {

	file bound <- shape_file("../includes/" + city + "/boundary_" + city + ".shp");

	file shape_file_buildings;

	file shape_file_roads;

	bool deliveries <- false;

	bool home_location <- true;

	file worker_csv;

	file student_csv;

	file leisure_csv;

	file delivery_midi_csv;

	file delivery_soir_csv;

	geometry shape <- envelope(bound);

	graph the_graph;

	list<string> study_places <- ["university", "college", "school", "library"];

	init{
		if city = "Marseille"{
			shape_file_buildings <- shape_file("../includes/Marseille/buildings.shp"); // building contenant les data osm, ign, pois
			shape_file_roads <- shape_file("../includes/Marseille/roads_cyclists.shp");

			if (test_population){
				write("Marseille : population test");
				worker_csv <- csv_file( "../results/Marseille/synthetic_population_test/worker.csv",true);

				student_csv <- csv_file( "../results/Marseille/synthetic_population_test/student.csv",true);

				leisure_csv <- csv_file( "../results/Marseille/synthetic_population_test/leisure.csv",true);

				delivery_midi_csv <- csv_file( "../results/Marseille/synthetic_population_test/delivery_midi.csv",true);

				delivery_soir_csv <- csv_file( "../results/Marseille/synthetic_population_test/delivery_soir.csv",true);
			}
			else{
				write("Marseille : population reelle");
				worker_csv <- csv_file( "../results/Marseille/synthetic_population/worker.csv",true);

				student_csv <- csv_file( "../results/Marseille/synthetic_population/student.csv",true);

				leisure_csv <- csv_file( "../results/Marseille/synthetic_population/leisure.csv",true);

				delivery_midi_csv <- csv_file( "../results/Marseille/synthetic_population/delivery_midi.csv",true);

				delivery_soir_csv <- csv_file( "../results/Marseille/synthetic_population/delivery_soir.csv",true);
			}
		}

		if city = "Toulouse"{
			shape_file_buildings <- shape_file("../includes/Toulouse/buildings_with_pois.shp"); // building contenant les data osm, ign, pois
			shape_file_roads <- shape_file("../includes/Toulouse/roads_cyclists.shp");

			if (test_population){
				write("Toulouse : population test");
				worker_csv <- csv_file( "../results/Toulouse/synthetic_population_test/worker.csv",true);

				student_csv <- csv_file( "../results/Toulouse/synthetic_population_test/student.csv",true);

				leisure_csv <- csv_file( "../results/Toulouse/synthetic_population_test/leisure.csv",true);

				delivery_midi_csv <- csv_file( "../results/Toulouse/synthetic_population_test/delivery_midi.csv",true);

				delivery_soir_csv <- csv_file( "../results/Toulouse/synthetic_population_test/delivery_soir.csv",true);
			}
			else{
				write("Toulouse : population reelle");
				worker_csv <- csv_file( "../results/Toulouse/synthetic_population/worker.csv",true);

				student_csv <- csv_file( "../results/Toulouse/synthetic_population/student.csv",true);

				leisure_csv <- csv_file( "../results/Toulouse/synthetic_population/leisure.csv",true);

				delivery_midi_csv <- csv_file( "../results/Toulouse/synthetic_population/delivery_midi.csv",true);

				delivery_soir_csv <- csv_file( "../results/Toulouse/synthetic_population/delivery_soir.csv",true);
			}
		}


		create building from: shape_file_buildings {
			types <- types_str split_with ",";

		}

		//list<building> university_buildings <- building where (not empty(study_places inter each.types));

		create road from: shape_file_roads with: [id::int(get("id")), fclass::read ("fclass"), speed_coeff::float(get("s_coeff")), maxspeed::int(get("maxspeed"))];

		the_graph <- as_edge_graph(road);
		the_graph <- the_graph;

		map<int,building> building_map <- building as_map (each.id::each);

		if workers{
			write("instanciate workers");
			create worker from: worker_csv with:[id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{

				if home_location{

					living_place <- building_map[id_living_place];
					location <- any_location_in (living_place);
				}
				else {
					destination_place <- building_map[id_destination_place];
					location <- any_location_in (destination_place);
				}

			}
		}

		if students{
			write("instanciate students");
			create student from: student_csv with:[id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{

				if home_location{

					living_place <- building_map[id_living_place];
					location <- any_location_in (living_place);
				}
				else {
					destination_place <- building_map[id_destination_place];
					location <- any_location_in (destination_place);
				}
			}
		}

		if leisures{
			write("instanciate leisures");
			create leisure from: leisure_csv with:[id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{

				if home_location{

					living_place <- building_map[id_living_place];
					location <- any_location_in (living_place);
				}
				else {
					destination_place <- building_map[id_destination_place];
					location <- any_location_in (destination_place);
				}
			}
		}


		if deliveries {
			write("instanciate deliveries");
			create delivery from: delivery_midi_csv with: [id_living_place::int(get("living_place.id"))]{

				living_place <- building_map[id_living_place];
				location <- any_location_in (living_place);


			}

			create delivery from: delivery_soir_csv with: [id_living_place::int(get("living_place.id"))]{

				living_place <- building_map[id_living_place];
				location <- any_location_in (living_place);

			}
		}

		/*
		   float min_dist <- university_buildings min_of (each distance_to student[0]);
		   float max_dist <- university_buildings max_of (each distance_to student[0]);

		   ask building {
		   if not (self in university_buildings){
		   do die;
		   }
		   float coeff_dist <- (self distance_to student[0] - min_dist) / (max_dist - min_dist);

		   color <- rgb(int(255 * coeff_dist), int(255 * (1 - coeff_dist)), 0);
		   }
		 *
		 */
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

species road  {
	int id;

	string fclass;

	int maxspeed;

	float speed_coeff;

	rgb color <- #orange;

	aspect base {
		draw shape color: color width: 1;
	}
}

species people skills: [moving] {
	rgb color;

	int id_living_place;
	int id_destination_place;

	building living_place;
	building destination_place;

	aspect base{
		draw circle(60) color: color border: #black;
	}
}

species worker parent: people {
	rgb color <- #black;
}

species student parent: people{
	rgb color <- #green;
}

species leisure parent: people{
	rgb color <- #blue;
}

species delivery skills: [moving]{
	rgb color <- #red;

	int id_living_place;
	building living_place <- nil;

	aspect base{
		draw circle(10) color: color border: #black;
	}
}



experiment bike_traffic type: gui {

	output{
		display city_display type: opengl{
			species building aspect: base;
			//species road aspect: base;
			species worker aspect: base;
			species student aspect: base;
			species leisure aspect: base;
			species delivery aspect: base;
		}

		display caract_road {
			chart "Distribution de la distance de trajet des travailleurs" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0, 0}{
				data "0 - 50 m" value: road count (each.shape.perimeter < 50 #m) color: #blue;

				data "50 - 100" value: road count (each.shape.perimeter > 50 #m and each.shape.perimeter < 100 #m) color: #blue;

				data "100 - 150" value: road count (each.shape.perimeter > 100 #m and each.shape.perimeter < 150 #m) color: #blue;

				data "150 - 200" value: road count (each.shape.perimeter > 150 #m and each.shape.perimeter < 200 #m) color: #blue;

			}

			chart "Distance moyenne des routes" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0.5, 0.5} {
				list<float> size;

				loop rd over: road{
					size << rd.shape.perimeter;
				}
				data "Travail" value: sum(size) / length(road) color: #blue;


			}
		}
	}







}

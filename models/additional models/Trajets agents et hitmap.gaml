/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/*
 * 
 * 
 */

global {
	
	file shape_file_buildings <- shape_file("../includes/SHP Marseille/buildings_v2.shp");
            
    file bound <- shape_file("../includes/boundary_marseille.shp");
                
    file shape_file_roads <- shape_file("../results/road/roads_hitmap_workers.shp");
	
	file grid_data <- file('../includes/raster_dep13_NO2_12_02_2018_analyse_32float_marseille.tif');
	
	bool test_population <- false;
	bool workers <- false;
    bool students <- false;
    bool leisures <- false;
    bool deliveries <- false;
    bool save_time_travel_agents <- false;
    bool save_hitmap <- false;
    bool save_indiv_travels <- false;
	           
    file worker_csv;
    
    file student_csv;
    
    file leisure_csv;
    
    file delivery_midi_csv;
    
    file delivery_soir_csv;
        
    geometry shape <- envelope(grid_data);
    
    float max_value;
	float min_value;
   	
    float step <- 5 #minute;
    
    date starting_date <- date("2020-09-02");
        
    float bicycle_speed <- 9 #km / #h;
	
    graph the_graph;
        
    map<road,float> road_weights;
        
    float transparency_pollution_cell <- 0.95;
    float transparency_mesured_pollution_cell <- 0.7;

	
	reflex save_agents when: current_date.hour = 23 and current_date.minute = 0 and save_time_travel_agents{
		ask worker{
			save [(hour_arrive_aller - go_out_hour) * 60 + min_arrive_aller - go_out_min, int(distance_travel)] to: "../results/worker/workers_hours_travel.csv" type:"csv" rewrite: false;
		}
		ask student{
			save [(hour_arrive_aller - go_out_hour) * 60 + min_arrive_aller - go_out_min, int(distance_travel)] to: "../results/student/students_hours_travel.csv" type:"csv" rewrite: false;
		}
		ask leisure{
			save [(hour_arrive_aller - go_out_hour) * 60 + min_arrive_aller - go_out_min, int(distance_travel)] to: "../results/leisure/leisures_hours_travel.csv" type:"csv" rewrite: false;
		}
	}
	
	reflex save_road_hitmap when: current_date.hour = 0 and current_date.minute = 10 and save_hitmap{
		if (test_population){
			save road to: "../results/road/roads_hitmap_agents_test.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
		}
		else{
			save road to: "../results/road/roads_hitmap_workers.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
		}
	}
             
    init{    	
    	max_value <- pollution_cell max_of (each.grid_value);
		min_value <- pollution_cell min_of (each.grid_value);
		ask pollution_cell {
			pollution <- (grid_value - min_value) / (max_value - min_value);
			color <- rgb(int(255 * pollution), int(255 * (1 - pollution)), 0);
			grid_value <- 9.9; //valeur pour : pas de donnée (un peu en dessous du minimum de concentration)
		}
		
    	create building from: shape_file_buildings {
    		types <- types_str split_with ",";

    	}
       	    	
    	create road from: shape_file_roads with: [id::int(get("id")), fclass::read ("fclass"), speed_coeff::float(get("s_coeff")), maxspeed::int(get("maxspeed")), number_of_agents::int(get("nb_agents"))]{
    		color <- rgb(255 * (number_of_agents / 140), 255 * (1 - number_of_agents / 140), 0);
    		width <- 1 + 20 * (number_of_agents / 140);
    		
    		
    	}
    	
    	road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff); // a speed coefficient of 1.15 = mean speed of 17.25 km/h, a speed coefficient of 0.8 = mean speed of 12 km/h, 0.33 --> 5 km/h
    	the_graph <- as_edge_graph(road);
		the_graph <- the_graph with_weights road_weights;    	
    	
    	map<int,building> building_map <- building as_map (each.id::each);
    	
    	if (test_population){
    		write("population test");
    		worker_csv <- csv_file( "../results/synthetic_population_test/worker.csv",true);
    
		    student_csv <- csv_file( "../results/synthetic_population_test/student.csv",true);
		    
		    leisure_csv <- csv_file( "../results/synthetic_population_test/leisure.csv",true);
		    
		    delivery_midi_csv <- csv_file( "../results/synthetic_population_test/delivery_midi.csv",true);
		    
		    delivery_soir_csv <- csv_file( "../results/synthetic_population_test/delivery_soir.csv",true);
    	}
    	else{
    		write("population reelle");
    		worker_csv <- csv_file( "../results/synthetic_population/worker.csv",true);
    
		    student_csv <- csv_file( "../results/synthetic_population/student.csv",true);
		    
		    leisure_csv <- csv_file( "../results/synthetic_population/leisure.csv",true);
		    
		    delivery_midi_csv <- csv_file( "../results/synthetic_population/delivery_midi.csv",true);
		    
		    delivery_soir_csv <- csv_file( "../results/synthetic_population/delivery_soir.csv",true);
    	}

		if workers{
	    	write("instanciate workers");
	    	create worker from: worker_csv with:[go_out_hour::int(get("go_out_hour")), go_home_hour::int(get("go_home_hour")), 
	    										id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{
	    																							   	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		destination_place <- building_map[id_destination_place];		
				speed <- bicycle_speed;
				
				distance_travel <- living_place distance_to destination_place;
	
	        	objective <- "resting";
	        	is_on_road <- false;
	        	counted_on_roads <- false;
	        	
	        	if (save_hitmap){
	        		path path_aller <- path_between(the_graph, location, any_location_in (destination_place)); // remplacer par le chemin choisi par l'API
	        		
	        		list<road> list_of_roads;
	        	
		        	if not counted_on_roads and path_aller != nil {
						loop rd over: path_aller.edges{
							road(int(rd)).number_of_agents <- road(int(rd)).number_of_agents + 1;
							list_of_roads << road(int(rd));
						}
						if (save_indiv_travels){
							if (test_population){
								save list_of_roads to: "../results/workers_test/trajet_worker" + int(self) + "_test.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
								}
							else{
								save list_of_roads to: "../results/workers/trajet_worker" + int(self) + ".shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
							}
							counted_on_roads <- true;
						}
					}
	        	}
	    	}
    	}
    	
    	if students{
	    	write("instanciate students");
	    	create student from: student_csv with:[go_out_hour::int(get("go_out_hour")), go_home_hour::int(get("go_home_hour")), 
	    										  id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{
	    																						   	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		destination_place <- building_map[id_destination_place];		
				speed <- bicycle_speed;
				
				distance_travel <- living_place distance_to destination_place;
	    		
	        	objective <- "resting";
	        	is_on_road <- false;
	        	counted_on_roads <- false;
	        	
	        	if (save_hitmap){
	        		path path_aller <- path_between(the_graph, location, any_location_in (destination_place));
	        	
		        	list<road> list_of_roads;
		        	
		        	if not counted_on_roads and path_aller != nil {
						loop rd over: path_aller.edges{
							road(int(rd)).number_of_agents <- road(int(rd)).number_of_agents + 1;
							list_of_roads << road(int(rd));
						}
						if (save_indiv_travels){
							if (test_population){
								save list_of_roads to: "../results/students_test/trajet_student" + int(self) + "_test.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
								}
							else{
								save list_of_roads to: "../results/students/trajet_student" + int(self) + ".shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
							}
							counted_on_roads <- true;
						}
					}
	        	}
	  	    }
	    }

		if leisures{
	    	write("instanciate leisures");
	    	create leisure from: leisure_csv with:[go_out_hour::int(get("go_out_hour")), go_home_hour::int(get("go_home_hour")), 
	    										  id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{
	    																						   	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		destination_place <- building_map[id_destination_place];		
				speed <- bicycle_speed;
	    		
	    		distance_travel <- living_place distance_to destination_place;
	    		
	        	objective <- "resting";
	        	is_on_road <- false;
	        	counted_on_roads <- false;
	        	
	        	if (save_hitmap){
	        		path path_aller <- path_between(the_graph, location, any_location_in (destination_place));
	        	
		        	list<road> list_of_roads;
		        	
		        	if not counted_on_roads and path_aller != nil {
						loop rd over: path_aller.edges{
							road(int(rd)).number_of_agents <- road(int(rd)).number_of_agents + 1;
							list_of_roads << road(int(rd));
						}
						if save_indiv_travels{
							if (test_population){
								save list_of_roads to: "../results/leisures_test/trajet_leisure" + int(self) + "_test.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
								}
							else{
								save list_of_roads to: "../results/leisures/trajet_leisure" + int(self) + ".shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "nb_agents"::number_of_agents] crs: "2154";
							}
							counted_on_roads <- true;
						}
					}
	        	}	
	    	}
	    }

    
    	if deliveries {
	    	write("instanciate deliveries");
			create delivery from: delivery_midi_csv with: [go_out_hour::int(get("go_out_hour_midi")), id_living_place::int(get("living_place.id")),
	   			id_restaurant_1::int(get("restaurant_1.id")), id_residential_place_1::int(get("residential_place_1.id")), id_residential_place_2::int(get("residential_place_2.id")),
	   			id_residential_place_3::int(get("residential_place_3.id")), id_restaurant_2::int(get("restaurant_2.id")), id_restaurant_3::int(get("restaurant_3.id"))]{
			   	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		
	    		list_of_destination <- [building_map[id_restaurant_1], building_map[id_residential_place_1], building_map[id_restaurant_2], building_map[id_residential_place_2], 
	    								building_map[id_restaurant_3], building_map[id_residential_place_3], living_place];
	    		
	    		objective <- "resting";
	    		is_on_road <- false;
	    		
				speed <- bicycle_speed;
			}   
			
	    	create delivery from: delivery_soir_csv with: [go_out_hour::int(get("go_out_hour_soir")), id_living_place::int(get("living_place.id")),
	   			id_restaurant_1::int(get("restaurant_1.id")), id_residential_place_1::int(get("residential_place_1.id")), id_residential_place_2::int(get("residential_place_2.id")),
	   			id_residential_place_3::int(get("residential_place_3.id")), id_restaurant_2::int(get("restaurant_2.id")), id_restaurant_3::int(get("restaurant_3.id"))]{
	   				
	   			if (int(self)!= 15){do die;}
	   				    			   	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		
	    		list_of_destination <- [building_map[id_restaurant_1], building_map[id_residential_place_1], building_map[id_restaurant_2], building_map[id_residential_place_2], 
	    								building_map[id_restaurant_3], building_map[id_residential_place_3], living_place];
	    		
	    		objective <- "resting";
	    		is_on_road <- false;
	    		
				speed <- speed;
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
    draw shape color: color ;
    }
}

species road  {
	int id;
	
	string fclass;
	
	int maxspeed;
	
	float speed_coeff;
	
	rgb color <- #black; 
	
	float width max: 10.0;	
	
	int number_of_agents;
	
    aspect base {
    draw shape color: color width: width;
    }
}

species people skills: [moving] {
	rgb color;
	
	int id_living_place;
	int id_destination_place;
	building living_place <- nil;
	building destination_place <- nil;
	
	float distance_travel;
		
	pollution_cell current_cell <- pollution_cell with_min_of (distance_to (self.location, each.location));
	float mesured_pollution min: 0.0 max: 1.0;
	pollution_cell most_polluted_cell <- current_cell;
	
	int nb_mesures;
	
	list<pollution_cell> visited_cells_locally;
	list<pollution_cell> visited_cells;
	
	path path_followed;
	list<geometry> segments_followed;
	
	int go_out_hour;
	int go_out_min <- rnd(0, 59, 5);
	int hour_arrive_aller;
	int min_arrive_aller;
	
	int go_home_hour;
	int go_home_min <- rnd(0, 59, 5);
	int hour_arrive_retour;
	int min_arrive_retour;
		
	bool is_on_road;
	bool counted_on_roads;
		
	string objective; 
	
	point the_target <- nil;
    
	aspect base{
		draw circle(6) color: color border: #black;
	}
}

species worker parent: people {
	rgb color <- #black;
}

species student parent: people{
	rgb color <- #lightgreen;
}

species leisure parent: people{
	rgb color <- #pink;
}

species delivery skills: [moving]{
	rgb color <- #red;
	
	int id_living_place;
	building living_place <- nil;
		
	pollution_cell current_cell <- pollution_cell with_min_of (distance_to (self.location, each.location));
	float mesured_pollution min: 0.0 max: 1.0;
	pollution_cell most_polluted_cell <- current_cell;
	
	int nb_mesures;
	
	list<pollution_cell> visited_cells_locally;
	list<pollution_cell> visited_cells;
	
	path path_followed;
	list<geometry> segments_followed;
	
	bool is_on_road;
		
	string objective; 
	
	point the_target <- nil;
	
	int id_restaurant_1;
	
	int id_restaurant_2;
	
	int id_restaurant_3;

	int id_residential_place_1;
	
	int id_residential_place_2;
	
	int id_residential_place_3;
	
	list<building> list_of_destination;
	
	int compteur_trajets;
	
	int compteur_waiting;
	int minute_waiting;
			
	int go_out_hour;
	int go_out_min <- rnd(0, 59, 5);
		
	reflex time_to_delivery when: (current_date.hour = go_out_hour and current_date.minute = go_out_min and objective  = "resting"){
							   	
		objective <- "end of waiting";
	
		the_target <- any_location_in(list_of_destination[0]);

		is_on_road <- true;
	}
		
	reflex prepare_for_waiting when: objective = "prepare for waiting"{
		minute_waiting <- rnd(0, 5, 5);
		compteur_waiting <- 0;
		objective <- "waiting";
	}
	
	reflex waiting when: objective = "waiting" {
		if compteur_waiting >= minute_waiting{
			compteur_trajets <- compteur_trajets + 1;
			if compteur_trajets = 6{
				objective <- "go home";
			}
			else if compteur_trajets < 6{
				objective <- "end of waiting";
			}
			the_target <- any_location_in(list_of_destination[compteur_trajets]);
			

		}
		
		else{compteur_waiting <- compteur_waiting + 5;}
		
	}
	
	reflex move when: objective in ["end of waiting", "go home"] {
		point current_location <- location;
		path_followed <- goto(target: the_target, on: the_graph, return_path: true);
		
		path local_path <- the_graph path_between(location, current_location); 
		list<geometry> segments <- local_path.segments;
		
		loop seg over: segments{
			visited_cells_locally <- visited_cells_locally + pollution_cell where (seg overlaps each and not (each in visited_cells_locally));
		}
		
		current_cell <- first(pollution_cell where (self.location overlaps each));
		
		loop cell over: visited_cells_locally {
			cell.nb_mesures <- cell.nb_mesures + 1;
			cell.float_mesured_pollution <- mesure_pollution(cell);
			if (cell.float_mesured_pollution > most_polluted_cell.pollution){
				most_polluted_cell <- cell;
			}
			cell.grid_value <- (max_value - min_value) * cell.float_mesured_pollution + min_value;
			
		}
		visited_cells <- visited_cells + visited_cells_locally where (not (each in visited_cells));
		nb_mesures <- length(visited_cells);
		visited_cells_locally <- [];
		
		if the_target = location and objective != "go home"{
			objective <- "prepare for waiting";
			
	    }
	 
	    if the_target = location and objective = "go home"{
	    	objective <- "resting";
	    	is_on_road <- false;
	    }
	  	 
	}
	
	
	float mesure_pollution(pollution_cell current_cell_){
    	return current_cell_.pollution; // pas de bruit
    }
    
	aspect base{
		draw circle(6) color: color border: #black;
	}
}

grid pollution_cell file: grid_data{
	float pollution min: 0.0 max: 1.0;

	float float_mesured_pollution min: 0.0 max: 1.0;
			
	int nb_mesures <- 0;
	
}

experiment bike_traffic type: gui {
       
    output{
    	display city_display type: opengl{
    		//species building aspect: base;
    		species road aspect: base;
    		//species worker aspect: base;
    		//species student aspect: base;
    		//species leisure aspect: base;
    		//species delivery aspect: base;	    	
    		
    	}
    	
    	display travel_distance {
    		chart "Types des routes ayant plus de 50 passages dans la journée" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0, 0}{

				data "primary" value: road count (each.number_of_agents >= 50 and each.fclass = "primary") color: #blue;
				data "secondary" value: road count (each.number_of_agents >= 50 and each.fclass = "secondary") color: #blue;
				data "tertiary" value: road count (each.number_of_agents >= 50 and each.fclass = "tertiary") color: #blue;
				data "cycleway" value: road count (each.number_of_agents >= 50 and each.fclass = "cycleway") color: #blue;

			}
			
			chart "Types des routes ayant plus de 80 passages dans la journée" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0.5, 0}{

				data "primary" value: road count (each.number_of_agents >= 75 and each.fclass = "primary") color: #blue;
				data "secondary" value: road count (each.number_of_agents >= 75 and each.fclass = "secondary") color: #blue;
				data "tertiary" value: road count (each.number_of_agents >= 75 and each.fclass = "tertiary") color: #blue;
				data "cycleway" value: road count (each.number_of_agents >= 75 and each.fclass = "cycleway") color: #blue;

			}
			
			chart "Types des routes ayant plus de 100 passages dans la journée" type: histogram background: #lightgrey size: {0.5, 0.5} position: {0, 0.5}{

				data "primary" value: road count (each.number_of_agents >= 100 and each.fclass = "primary") color: #blue;
				data "secondary" value: road count (each.number_of_agents >= 100 and each.fclass = "secondary") color: #blue;
				data "tertiary" value: road count (each.number_of_agents >= 100 and each.fclass = "tertiary") color: #blue;
				data "cycleway" value: road count (each.number_of_agents >= 100 and each.fclass = "cycleway") color: #blue;

			}
		}
	
	}
}
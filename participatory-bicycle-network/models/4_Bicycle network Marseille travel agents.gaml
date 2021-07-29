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

global {
	
	bool test_population <- false;
	
	file bound <- shape_file("../includes/Marseille/boundary_Marseille.shp");
	
	file shape_file_buildings;
                            
    file shape_file_roads;
      
	bool workers <- true;
    bool students <- true;
    bool leisures <- true;
    bool deliveries <- false;
    	           
    file worker_csv;
    
    file student_csv;
    
    file leisure_csv;
    
    file delivery_midi_csv;
    
    file delivery_soir_csv;
        
    geometry shape <- envelope(bound);
    
   	int time_step <- 5; // time step in seconds
   	
    float step <- time_step #s;
    
    date starting_date <- date(2021, 5, 27, 5, 30);
        
    float bicycle_speed <- 10 #km / #h;
	
    graph the_graph;
        
    map<road,float> road_weights;
    
    reflex save_trips when: current_date.hour = 23 and current_date.minute = 55{
    	
    	list<position_agent> list_of_positions_aller_workers;
    	list<position_agent> list_of_positions_retour_workers;
    	
    	ask worker {
    		loop pos over: list_of_positions_aller{
    			list_of_positions_aller_workers << pos;
    		}
    		
    		loop pos over: list_of_positions_retour{
    			list_of_positions_retour_workers << pos;
    		}
    	}
    	
    	save list_of_positions_aller_workers to: "../results/Marseille/worker/aller_worker/positions_aller_worker.shp" type: shp 
			attributes: ["time"::date_of_presence, "agent"::name_of_agent] crs: "2154";
			
		save list_of_positions_retour_workers to: "../results/Marseille/worker/retour_worker/positions_retour_worker.shp" type: shp 
			attributes: ["time"::date_of_presence, "agent"::name_of_agent] crs: "2154";
			
		
		list<position_agent> list_of_positions_aller_students;
    	list<position_agent> list_of_positions_retour_students;
    	
    	ask student {
    		loop pos over: list_of_positions_aller{
    			list_of_positions_aller_students << pos;
    		}
    		
    		loop pos over: list_of_positions_retour{
    			list_of_positions_retour_students << pos;
    		}
    	}
    	
    	save list_of_positions_aller_students to: "../results/Marseille/student/aller_student/positions_aller_student.shp" type: shp 
			attributes: ["time"::date_of_presence, "agent"::name_of_agent] crs: "2154";
			
		save list_of_positions_retour_students to: "../results/Marseille/student/retour_student/positions_retour_student.shp" type: shp 
			attributes: ["time"::date_of_presence, "agent"::name_of_agent] crs: "2154";
			
			
		list<position_agent> list_of_positions_aller_leisures;
    	list<position_agent> list_of_positions_retour_leisures;
    	
    	ask leisure {
    		loop pos over: list_of_positions_aller{
    			list_of_positions_aller_leisures << pos;
    		}
    		
    		loop pos over: list_of_positions_retour{
    			list_of_positions_retour_leisures << pos;
    		}
    	}
    	
    	save list_of_positions_aller_leisures to: "../results/Marseille/leisure/aller_leisure/positions_aller_leisure.shp" type: shp 
			attributes: ["time"::date_of_presence, "agent"::name_of_agent] crs: "2154";
			
		save list_of_positions_retour_leisures to: "../results/Marseille/leisure/retour_leisure/positions_retour_leisure.shp" type: shp 
			attributes: ["time"::date_of_presence, "agent"::name_of_agent] crs: "2154";
    	
    }

	reflex stop_simulation when: current_date.hour = 23 and current_date.minute = 55 {
		do pause;
	}


    init{    	
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
	
 
    	create building from: shape_file_buildings {
    		types <- types_str split_with ",";
    	}
       	    	
    	create road from: shape_file_roads with: [id::int(get("id")), fclass::read ("fclass"), speed_coeff::float(get("s_coeff")), maxspeed::int(get("maxspeed"))];
    	
    	road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff); // speed_coeff depends on the type of road
    	the_graph <- as_edge_graph(road);
		the_graph <- the_graph with_weights road_weights;    	
    	
    	map<int,building> building_map <- building as_map (each.id::each);

		if workers{
	    	write("instanciate workers");
	    	
	    	create worker from: worker_csv with:[go_out_hour::int(get("go_out_hour")), go_out_min::int(get("go_out_min")), go_home_hour::int(get("go_home_hour")), go_home_min::int(get("go_home_min")),
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

		if leisures{
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
    draw shape color: color ;
    }
}

species road  {
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

		path_aller <- path_between(the_graph, location, the_target);
						
		if path_aller != nil{
			loop rd over: path_aller.edges{
				list_of_roads_aller << road(int(rd));
			}
		}
		
		list_of_roads_aller[0].starting_road_aller <- true;
			
		is_on_road <- true;
	}
	
	reflex time_to_go_home when: current_date.hour = go_home_hour and current_date.minute = go_home_min and objective = "working"{
		objective <- "resting";
		the_target <- any_location_in (living_place);
		
		
		path_retour <- path_between(the_graph, location, the_target);
				
		if path_retour != nil{
			loop rd over: path_retour.edges{
				list_of_roads_retour << road(int(rd));
			}
		}	
		
		list_of_roads_retour[0].starting_road_retour <- true;
		
		is_on_road <- true;
	}
	
	reflex move when: the_target != nil {
		point current_location <- location;
		
		create position_agent{
			location <- current_location;
			date_of_presence <- current_date;
			name_of_agent <- string(myself);
		}
		
		if objective = "working"{
			list_of_positions_aller << last(position_agent);
		}
		if objective = "resting"{
			list_of_positions_retour << last(position_agent);
		}
		
		path_followed <- goto(target: the_target, on: the_graph, return_path: true);
		
		if the_target = location {
	    	the_target <- nil;
	    	is_on_road <- false;
	    	if (objective = "working"){
		    	date_of_arriving_dest <- date(2021, 5, 27, current_date.hour, current_date.minute, current_date.second);
		    	
	    	}
	    	if (objective = "resting"){
		    	date_of_arriving_home <- date(2021, 5, 27, current_date.hour, current_date.minute, current_date.second);
	    	}
	    }
		
    }
    
	aspect base{
		draw circle(10) color: color border: #black;
	}
}

species worker parent: people {
	rgb color <- #black;
}

species student parent: people{
	rgb color <- #green;
}

species leisure parent: people{
	rgb color <- #pink;
}

species position_agent {
	date date_of_presence;
	string name_of_agent;
}


experiment bike_traffic type: gui {
       
    output{
    	display city_display type: opengl{
    		//species building aspect: base;
    		species road aspect: base;
    		species worker aspect: base;
    		species student aspect: base;
    		species leisure aspect: base;
    	}

		display nb_persons_on_road refresh: every(2#cycles){
    		chart "Nombre d'agents sur les routes" type: series {
				data "Nombre d'agents sur les routes" value: worker count (each.is_on_road = true) + student count (each.is_on_road = true) + leisure count (each.is_on_road = true);
			}
    	}
    	
    	/*
    	display pollution type: opengl{
    		species pollution_cell aspect: pollution transparency: 0;
    	}
    
    	* 

    	display hour_travel {
    		chart "Distribution de l'heure de départ des agents worker" type: histogram background: #lightgrey{
    			loop i from: 0 to: 240 step: 5{
    				int hour_go <- int(i / 60);
    				data string(i) value: worker count (each.go_out_hour = int(i / 60) + 6 and each.go_out_min = int((i - (each.go_out_hour - 6) * 60) / 5) * 5) color: #blue;
    			}
    		}

    	}
    	* 
    	*/

		monitor "Date" value: current_date ;	
	}
	
	
	
	
	
	
	
}
/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/* 
 * This model generates the daily trips (non-participatory trip = the shortest path) of a synthetic population of cyclists in Marseille
 * From a pollution model of the city (hourly NO2 concentration grids), saves each hour the areas measured by the cyclists
 * Saves the meeting points made by cyclists throughout the day
 * Saves the travel times of each agent with the characteristics of the trips (pollution levels encountered)
 * 
 */

global {
	
	bool test_population <- false;
	
	file bound <- shape_file("../includes/Marseille/boundary_Marseille.shp");
	
	file shape_file_buildings;
                            
    file shape_file_roads;
    
    file grid_data <- grid_file("../includes/Marseille/pollution_model/raster_dep13_NO2_2021052705_2021052705.tif");
  
	int hour_count <- 5;
	
	bool workers <- false;
    bool students <- true;
    bool leisures <- false;
    bool deliveries <- false;
    
    bool save_hourly_pollution_data <- true;
    bool save_rdv <- false;
    bool save_time_travel_agents <- false;
	           
    file worker_csv;
    
    file student_csv;
    
    file leisure_csv;
    
    file delivery_midi_csv;
    
    file delivery_soir_csv;
        
    geometry shape <- envelope(grid_data);
    
    float max_value;
	float min_value;
	
   	int time_step <- 5; //time step in MINUTE
   	
    float step <- time_step #minute;
    
    date starting_date <- date(2021, 5, 27, 5, 30);
        
    float bicycle_speed <- 9 #km / #h;
	
    graph the_graph;
        
    map<road,float> road_weights;
        
   	reflex save_mesured_cells when: current_date.minute = 0 and current_date.hour != 0 and save_hourly_pollution_data {
	   	string travelling_population;
	   	if (workers){travelling_population <- "workers_";}
	   	
	   	if (students){
	   		if travelling_population != nil{travelling_population <- travelling_population + "students_";} else{travelling_population <- "students_";}}
	   		
	   	if (leisures){
	   		if travelling_population != nil{travelling_population <- travelling_population + "leisures";} else{travelling_population <- "leisures";}}
	   		
	   	ask pollution_cell { 
	   		grid_value <- (max_value - min_value) * float_measured_pollution + min_value; 
	   	}
	   		
	    save pollution_cell to:"../results/Marseille/measures/pollution_grid_" + travelling_population + (current_date.hour - 1) + "-" + current_date.hour + ".tif" type:geotiff;
	    write("pollution grid saved " + (current_date.hour - 1) + "-" + current_date.hour);
	}

	reflex update_pollution_grid when: current_date.minute = 0 and current_date.hour != 0 and hour_count != 23 and save_hourly_pollution_data{
		
		hour_count <- hour_count + 1;
		if (hour_count<10){
			grid_data <- grid_file('../includes/Marseille/pollution_model/raster_dep13_NO2_202105270' + string(hour_count) + '_202105270' + string(hour_count) + '.tif');
		}
		else{
			grid_data <- grid_file('../includes/Marseille/pollution_model/raster_dep13_NO2_20210527' + string(hour_count) + '_20210527' + string(hour_count) + '.tif');
		}
		write("file : heure " + string(hour_count));
    	matrix my_data <- grid_data as_matrix({pollution_cell max_of each.grid_x + 1, pollution_cell max_of each.grid_y + 1});
    	
    	ask pollution_cell {
    		if (float(my_data[grid_x,grid_y] get("grid_value")) > 0){
            	grid_value <- float (my_data[grid_x,grid_y] get("grid_value"));
            }
            else{
            	grid_value <- 0.0;
            }
        }  
        
        max_value <- 153.9;
		min_value <- 0.0;
		
		ask pollution_cell {
			pollution <- (grid_value - min_value) / (max_value - min_value);
			color <- rgb(int(255 * pollution), int(255 * (1 - pollution)), 0);
			grid_value <- 0.0; //valeur pour : pas de donnée (un peu en dessous du minimum de concentration)
			
		}
  	}
	
	reflex save_rdv when: current_date.minute = 0 and current_date.hour != 0 and save_rdv{
		string travelling_population;
	   	if (workers){travelling_population <- "workers_";}
	   	
	   	if (students){
	   		if travelling_population != nil{travelling_population <- travelling_population + "students_";} else{travelling_population <- "students_";}}
	   		
	   	if (leisures){
	   		if travelling_population != nil{travelling_population <- travelling_population + "leisures";} else{travelling_population <- "leisures";}}
	   			    
	    save rdv to: "../results/Marseille/rdv/rdv_" + travelling_population + (current_date.hour - 1) + "-" + current_date.hour + ".shp" type: shp;
	    write("rdv saved " + (current_date.hour - 1) + "-" + current_date.hour);
	    ask rdv {do die;}
	}		
	
	reflex stop_simulation when: current_date.hour = 23 and current_date.minute = 55 {
		if save_hourly_pollution_data{
			string travelling_population;
		   	if (workers){
		   		travelling_population <- "workers_";
		   	}
		   	
		   	if (students){
		   		if travelling_population != nil{travelling_population <- travelling_population + "students_";} else{travelling_population <- "students_";}}
		   		
		   	if (leisures){
		   		if travelling_population != nil{travelling_population <- travelling_population + "leisures";} else{travelling_population <- "leisures";}}
		   		
		    save pollution_cell to:"../results/Marseille/measures/pollution_grid_" + travelling_population + (current_date.hour) + "-0.tif" type:geotiff;
		    write("pollution grid saved " + (current_date.hour) + "-0");
		    
		    save rdv to: "../results/Marseille/rdv/rdv_" + travelling_population + (current_date.hour - 1) + "-" + current_date.hour + ".shp" type: shp;
	    	write("rdv saved " + (current_date.hour - 1) + "-" + current_date.hour);
		}
		
		if save_rdv{
			string travelling_population;
		   	if (workers){travelling_population <- "workers_";}
		   	
		   	if (students){
		   		if travelling_population != nil{travelling_population <- travelling_population + "students_";} else{travelling_population <- "students_";}}
		   		
		   	if (leisures){
		   		if travelling_population != nil{travelling_population <- travelling_population + "leisures";} else{travelling_population <- "leisures";}}
		   			    
		    save rdv to: "../results/Marseille/rdv/rdv_" + travelling_population + (current_date.hour - 1) + "-" + current_date.hour + ".shp" type: shp;
		    write("rdv saved " + (current_date.hour - 1) + "-" + current_date.hour);
		}
		
		do pause;
	}


	reflex save_agents when: current_date.hour = 23 and current_date.minute = 55 and save_time_travel_agents{
		if workers {
			ask worker{
				save [(hour_arrive_aller - go_out_hour) * 60 + min_arrive_aller - go_out_min, int(distance_travel), (max_value - min_value) * mean_pollution + min_value, (max_value - min_value) * max_pollution + min_value] to: "../results/Marseille/worker/workers_indiv.csv" type:"csv" rewrite: false;
			}
		}
		
		if students{
			ask student{
				save [(hour_arrive_aller - go_out_hour) * 60 + min_arrive_aller - go_out_min, int(distance_travel), (max_value - min_value) * mean_pollution + min_value, (max_value - min_value) * max_pollution + min_value] to: "../results/Marseille/student/students_indiv.csv" type:"csv" rewrite: false;
			}
		}
		
		if leisures{
			ask leisure{
				save [(hour_arrive_aller - go_out_hour) * 60 + min_arrive_aller - go_out_min, int(distance_travel), (max_value - min_value) * mean_pollution + min_value, (max_value - min_value) * max_pollution + min_value] to: "../results/Marseille/leisure/leisures_indiv.csv" type:"csv" rewrite: false;
			}
		}
	}
	
	reflex add_rdv when: save_rdv{

		list<string> agents_rdv <- []; //liste des agents qui ont fait un rdv par pas de temps
		
		ask pollution_cell{
			point loc <- location;
			if length(rendez_vous) > 1 and rendez_vous inter agents_rdv = []{
				
				create rdv{location <- loc;}
		
				loop ag over: rendez_vous {
					agents_rdv << ag;
				}		
			}
			rendez_vous <- [];
		}
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
	

    	grid_data <- grid_file('../includes/Marseille/pollution_model/raster_dep13_NO2_2021052705_2021052705.tif');
    	write("file : heure " + string(hour_count));
    	matrix my_data <- grid_data as_matrix({pollution_cell max_of each.grid_x + 1, pollution_cell max_of each.grid_y + 1});

    	ask pollution_cell {
    		if (float(my_data[grid_x,grid_y] get("grid_value")) > 0){
            	grid_value <- float (my_data[grid_x,grid_y] get("grid_value"));
            }
            else{
            	grid_value <- 0.0;
            }
        }        
   
		max_value <- 153.9;
		min_value <- 0.0;
		
		ask pollution_cell {
			pollution <- (grid_value - min_value) / (max_value - min_value);
			color <- rgb(int(255 * pollution), int(255 * (1 - pollution)), 0);
			grid_value <- 0.0; //valeur pour : pas de donnée (un peu en dessous du minimum de concentration)
			nb_mesures <- 0;
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
	    																							   	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		destination_place <- building_map[id_destination_place];		
				speed <- bicycle_speed;
				
				distance_travel <- living_place distance_to destination_place;
	
	        	objective <- "resting";
	        	is_on_road <- false;
	    	}
    	}
    	
    	if students{
	    	write("instanciate students");
	    	
	    	create student from: student_csv with:[go_out_hour::int(get("go_out_hour")), go_out_min::int(get("go_out_min")), go_home_hour::int(get("go_home_hour")), go_home_min::int(get("go_home_min")),
	    										id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{
	    												
				//if  not (int(self) in [0]){do die;}	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		destination_place <- building_map[id_destination_place];		
				speed <- bicycle_speed;
				
				distance_travel <- living_place distance_to destination_place;
	    		
	        	objective <- "resting";
	        	is_on_road <- false;
	  	    }
	    }

		if leisures{
	    	write("instanciate leisures");
	    	create leisure from: leisure_csv with:[go_out_hour::int(get("go_out_hour")), go_out_min::int(get("go_out_min")), go_home_hour::int(get("go_home_hour")), go_home_min::int(get("go_home_min")),
	    										id_living_place::int(get("living_place.id")), id_destination_place::int(get("destination_place.id"))]{
	    																						   	
	    		living_place <- building_map[id_living_place];																				 
	    		location <- any_location_in (living_place);
	    		destination_place <- building_map[id_destination_place];		
				speed <- bicycle_speed;
	    		
	    		distance_travel <- living_place distance_to destination_place;
	    		
	        	objective <- "resting";
	        	is_on_road <- false;
	    	}
	    }

    
    	if deliveries {
	    	write("instanciate deliveries");
			create delivery from: delivery_midi_csv with: [go_out_hour::int(get("go_out_hour_midi")), go_out_min::int(get("go_out_min_midi")), id_living_place::int(get("living_place.id")),
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
			
	    	create delivery from: delivery_soir_csv with: [go_out_hour::int(get("go_out_hour_soir")), go_out_min::int(get("go_out_min_soir")), id_living_place::int(get("living_place.id")),
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
	
	float distance_travel;
		
	float mesured_pollution min: 0.0 max: 1.0;
	
	int nb_mesures;
	float mean_pollution min: 0.0 max: 1.0;
	float max_pollution min: 0.0 max: 1.0;
		
	list<pollution_cell> visited_cells_locally;
	
	path path_followed;
	list<geometry> segments_followed;
	
	int go_out_hour;
	int go_out_min;
	int hour_arrive_aller;
	int min_arrive_aller;
	
	int go_home_hour;
	int go_home_min;
	int hour_arrive_retour;
	int min_arrive_retour;
		
	bool is_on_road;
		
	string objective; 
	
	point the_target <- nil;
	
	reflex time_to_leave when: current_date.hour = go_out_hour and current_date.minute = go_out_min and objective = "resting"{
		objective <- "working";
		the_target <- any_location_in (destination_place);
		list<geometry> total_segments <- path_between(the_graph, location, the_target).segments;
		segments_followed <- segments_followed + total_segments where (not (each in segments_followed));
	
		is_on_road <- true;
	}
	
	reflex time_to_go_home when: current_date.hour = go_home_hour and current_date.minute = go_home_min and objective = "working"{
		objective <- "resting";
		the_target <- any_location_in (living_place);
		list<geometry> total_segments <- path_between(the_graph, location, the_target).segments;
		segments_followed <- segments_followed + total_segments where (not (each in segments_followed));

		is_on_road <- true;
	}
	
	reflex move when: the_target != nil {
		point current_location <- location;
		
		path_followed <- goto(target: the_target, on: the_graph, return_path: true);		
					
		path local_path <- the_graph path_between(location, current_location); 
		list<geometry> segments <- local_path.segments;
		
		loop seg over: segments{
			visited_cells_locally <- visited_cells_locally + pollution_cell where (seg overlaps each and not (each in visited_cells_locally));
		}
				
		list<pollution_cell> neighbors_cell <- [];
		
		loop cell_locally over: visited_cells_locally {
			
			create measure {
				measured_cell_id <- int(cell_locally);
				cell_locally.nb_mesures <- cell_locally.nb_mesures + 1;
			}
			
			cell_locally.float_measured_pollution <- mesure_pollution(cell_locally);
			
			//données agent
			nb_mesures <- nb_mesures + 1;	
			mean_pollution <- (mean_pollution * (nb_mesures - 1) + cell_locally.float_measured_pollution) / nb_mesures;
			
			if (cell_locally.float_measured_pollution > max_pollution){
				max_pollution <- cell_locally.float_measured_pollution;
			}
			//fin données agent
					
			if(save_rdv){neighbors_cell <- neighbors_cell + cell_locally.neighbors where not (each in neighbors_cell);}
		}
		
		if(save_rdv){
			loop c over: neighbors_cell{
				if not (string(self) in c.rendez_vous){
					c.rendez_vous << string(self);	//rendez_vous est une liste qui contient les agents proches de la cellule (rdv possible)
				}			
			}
		}
			
		visited_cells_locally <- [];
		
		if the_target = location {
	    	the_target <- nil;
	    	is_on_road <- false;
	    	if (objective = "working"){
		    	hour_arrive_aller <- current_date.hour;
		    	min_arrive_aller <- current_date.minute;
	    	}
	    	if (objective = "resting"){
		    	hour_arrive_retour <- current_date.hour;
		    	min_arrive_retour <- current_date.minute;
	    	}
	    }
    }
    
    float mesure_pollution(pollution_cell current_cell_){
    	return current_cell_.pollution; // pas de bruit
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

species delivery skills: [moving]{
	rgb color <- #red;
	
	int id_living_place;
	building living_place <- nil;
		
	float mesured_pollution min: 0.0 max: 1.0;
	
	int nb_mesures;
	float mean_pollution min: 0.0 max: 1.0;
	float max_pollution min: 0.0 max: 1.0;
		
	list<pollution_cell> visited_cells_locally;
	
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
	int go_out_min;
		
	reflex time_to_delivery when: (current_date.hour = go_out_hour and current_date.minute = go_out_min and objective  = "resting"){
							   	
		objective <- "end of waiting";
	
		the_target <- any_location_in(list_of_destination[0]);

		is_on_road <- true;
	}
		
	reflex prepare_for_waiting when: objective = "prepare for waiting"{
		minute_waiting <- rnd(0, time_step, time_step);
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
		
		else{compteur_waiting <- compteur_waiting + time_step;}
		
	}
	
	reflex move when: objective in ["end of waiting", "go home"] {
		point current_location <- location;
		
		path_followed <- goto(target: the_target, on: the_graph, return_path: true);		
					
		path local_path <- the_graph path_between(location, current_location); 
		list<geometry> segments <- local_path.segments;
		
		loop seg over: segments{
			visited_cells_locally <- visited_cells_locally + pollution_cell where (seg overlaps each and not (each in visited_cells_locally));
		}
				
		list<pollution_cell> neighbors_cell;
		
		loop cell_locally over: visited_cells_locally {
			cell_locally.nb_mesures <- cell_locally.nb_mesures + 1;
			cell_locally.float_measured_pollution <- mesure_pollution(cell_locally);
			nb_mesures <- nb_mesures + 1;
			
			mean_pollution <- (mean_pollution * (nb_mesures - 1) + cell_locally.float_measured_pollution) / nb_mesures;
			
			if (cell_locally.float_measured_pollution > max_pollution){
				max_pollution <- cell_locally.float_measured_pollution;
			}
			
			neighbors_cell <- neighbors_cell + cell_locally.neighbors where not (each in neighbors_cell);
		}
		
		
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

grid pollution_cell file: grid_data neighbors: 8{
	float pollution min: 0.0 max: 1.0;

	float float_measured_pollution min: 0.0 max: 1.0;
	
	list<string> rendez_vous;
			
	int nb_mesures <- 0;
	
	reflex reset_measure when: nb_mesures = 0 {
		float_measured_pollution <- 0.0;
	}
			
	aspect pollution{
		draw square(25) color: color border: #black;
	}
}

species measure {
	int measured_cell_id;
		
	int count;
	
	int expiration_time <- 60; // temps au bout duquel la mesure n'est plus considérée en MINUTE
	
	reflex expiration_measure {
		count <- count + 1;
	}
	
	reflex when: count = int(expiration_time / time_step){
		pollution_cell[measured_cell_id].nb_mesures <- pollution_cell[measured_cell_id].nb_mesures - 1;
		do die;
	}
}

species rdv {

}

experiment bike_traffic type: gui {
       
    output{
    	display city_display type: opengl{
    		//species building aspect: base;
    		species road aspect: base;
    		species worker aspect: base;
    		species student aspect: base;
    		species leisure aspect: base;
    		species delivery aspect: base;	    	
    	}

		display nb_persons_on_road refresh: every(2#cycles){
    		chart "Nombre d'agents sur les routes" type: series {
				data "Nombre d'agents sur les routes" value: worker count (each.is_on_road = true) + student count (each.is_on_road = true) + leisure count (each.is_on_road = true) + delivery count (each.is_on_road = true);
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
		monitor "Nombre de rendez-vous" value: length(rdv);
	}
}
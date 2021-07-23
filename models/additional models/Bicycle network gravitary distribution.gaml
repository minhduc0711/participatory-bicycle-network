/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/* En se basant sur le shp de "road traffic, on modélise :
 * 1) le déplacement quotidien d'habitants en vélo
 * puis :
 * 2) une grille de pollution statique
 * 
 * On analyse la représentativité du réseau de mesures par rapport à 
 * cet état de pollution
 * 
 */

global {
    file shape_file_buildings <- shape_file("../includes/Marseille/SHP Quartier/buildings.shp");
    file shape_file_roads <- shape_file("../includes/Marseille/SHP Quartier/roads.shp");
    file bound <- shape_file("../includes/Marseille/boundary.shp");
    
    
    file grid_data <- file('../includes/Marseille/raster_dep13_NO2_12_02_2018_analyse_32float_quartier.tif');
    
    
    geometry shape <- envelope(grid_data);  
    float max_value;
	float min_value;
    
    
    int working_agents <- 200;
    int student_agents <- 0;
    int leisure_agents <- 0;

    int hour_early_work_start <- 6;
	int hour_late_work_start <- 8;
	
	int hour_early_work_end <- 16;
	int hour_late_work_end <- 20;

	int hour_early_study_start <- 9;
	int hour_late_study_start <- 12;
	
	int hour_early_study_end <- 13;
	int hour_late_study_end <- 16;
	
	int hour_early_leisure_start <- 11;
	int hour_late_leisure_start <- 15;
	
	int hour_early_leisure_end <- 14;
	int hour_late_leisure_end <- 18;
	    
    float step <- 1 #minute;
    
    date starting_date <- date("2020-09-02");
        
    float speed <- 10 #km / #h;

    graph the_graph;
        
    map<road,float> road_weights;
        
    float transparency_pollution_cell <- 0.95;
    float transparency_mesured_pollution_cell <- 0.7;
    
	list<string> living_places <- ["house", "apartments", "dormitory", "hotel", "residential", "Résidentiel"];
    list<string> work_places <- ["industrial", "office", "construction", "garages", "hospital", "service", "Commercial et services", "commercial"];
    list<string> study_places <- ["university", "college", "school"];
    list<string> leisure_places <- ["commercial", "kiosk", "chapel", "church", "service", "Sportif", "Commercial et services", "Religieux", "religious"];
    
   	reflex save_and_stop_simulation when: date("2020-09-03") = current_date{
		
		write("workers data saved");
    	save pollution_cell to:"../results/mesured_grid.tif" type:geotiff;
    	write("pollution grid saved");
		do pause;
	}
       
        
    init{    	
    	max_value <- pollution_cell max_of (each.grid_value);
		min_value <- pollution_cell min_of (each.grid_value);
		ask pollution_cell {
			pollution <- (grid_value - min_value) / (max_value - min_value);
			color <- rgb(int(255 * pollution), int(255 * (1 - pollution)), 0);
			grid_value <- min_value;
		}
		
    	create building from: shape_file_buildings with: [capacity::int(read("nb_logemen"))]{
    		types <- types_str split_with ",";


				if (types[0] in(leisure_places)){
	    			color <- #pink;
	    		}
    			
	    		if (types[0] in(living_places)){
	    			color <- #orange;
	    		}
	    		
	    		if (types[0] in(study_places)){
    			color <- #green;
    			}
	    		
	    		if (types[0] in(work_places)){
	    			color <- #blue;
	    		}
    	}
    	    	
    	create road from: shape_file_roads with: [fclass::read ("fclass"), maxspeed::int(get("maxspeed"))]{
    		if fclass="cycleway"{
    			speed_coeff <- 1.5;
    		}
    		if fclass="tertiary"{
    			speed_coeff <- 1.3;
    		}
    		if fclass="secondary"{
    			speed_coeff <- 1.3;
    		}
    		if fclass="secondary_link"{
    			speed_coeff <- 1.3;
    		}
    		if fclass="residential"{
    			speed_coeff <- 1.2;
    		}
    		if fclass="unclassified"{
    			speed_coeff <- 1.0;
    		}
    		if fclass="primary"{
    			speed_coeff <- 1.3;
    		} 
    		if fclass="primary_link"{
    			speed_coeff <- 1.3;
    		} 		
    		if fclass="pedestrian"{
    			speed_coeff <- 0.5;
    		}
    		if fclass="footway"{
    			speed_coeff <- 0.5;
    		}
    	}
    	
    	road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
    	the_graph <- as_edge_graph(road);
		the_graph <- the_graph with_weights road_weights;    	
    		
    	list<building> residential_buildings <- building where (each.capacity > 0 and not empty(living_places inter each.types));
    	list<building> university_buildings <- building where (not empty(study_places inter each.types));
    	list<building> industrial_buildings <- building where (not empty(work_places inter each.types));
    	list<building> leisure_buildings <- building where (not empty(leisure_places inter each.types));
    	
    	write length(industrial_buildings);
    	
    	create worker number: working_agents{
			speed <- speed;
    		living_place <- one_of (residential_buildings where (each.capacity > each.nb_habitants));
    		location <- any_location_in (living_place);
    		living_place.nb_habitants <- living_place.nb_habitants + 1;
    		destination_place <- rnd_choice(gravitational_model(living_place, industrial_buildings));
    		
			go_out_hour <- rnd(hour_early_work_start, hour_late_work_start - 1);
        	go_home_hour <- rnd(hour_early_work_end, hour_late_work_end - 1);  
        	objective <- "resting";
        	is_on_road <- false;
    	}
    	create student number: student_agents{
    		speed <- speed;
			living_place <- one_of (residential_buildings where (each.capacity > each.nb_habitants));
			location <- any_location_in (living_place);
    		living_place.nb_habitants <- living_place.nb_habitants + 1;
    		
    		destination_place <- rnd_choice(gravitational_model(living_place, university_buildings));
    		
			go_out_hour <- rnd(hour_early_study_start, hour_late_study_start - 1);
        	go_home_hour <- rnd(hour_early_study_end, hour_late_study_end - 1);  
        	objective <- "resting";
        	is_on_road <- false;
    	}
    	create leisure number: leisure_agents{
    		speed <- speed;
    		living_place <- one_of (residential_buildings where (each.capacity > each.nb_habitants));
    		location <- any_location_in (living_place);
    		living_place.nb_habitants <- living_place.nb_habitants + 1;
    		
    		destination_place <- rnd_choice(gravitational_model(living_place, leisure_buildings));
    		
			go_out_hour <- rnd(hour_early_leisure_start, hour_late_leisure_start - 1);
        	go_home_hour <- rnd(hour_early_leisure_end, hour_late_leisure_end - 1);  
        	objective <- "resting";
        	is_on_road <- false;
    	}    	    	
    }
    list<people> l_people <- list(worker) + list(student) + list(leisure);
}
species building {
    string type; 
    string types_str;
    list<string> types;
    float height;
	int capacity;
	int nb_etages;
    rgb color <- #gray;
    
    int nb_habitants;
    
    aspect base {
    draw shape color: color ;
    }
}

species road  {
	string fclass;
	//list<worker> worker_on_road update: worker where (each.location distance_to self.location < 100 and each.the_target != nil);	
	//list<student> student_on_road update: student where (each.location distance_to self.location < 100 and each.the_target != nil);	
	//list<leisure> leisure_on_road update: leisure where (each.location distance_to self.location < 100 and each.the_target != nil);	
	
	//int nb_people_on_road update: length(worker_on_road) + length(student_on_road) + length(leisure_on_road);	
	
	int id;
	
	int maxspeed;
	
	float speed_coeff <- 1.0;
	
    int colorValue <- int(255*(speed_coeff - 1)) update: int(255*(speed_coeff - 1));
	rgb color <- rgb(max([0, 255 - colorValue]), min([255, colorValue]),0)  update: rgb(max([0, 255 - colorValue]), min([255, colorValue]),0) ;
	
    aspect base {
    draw shape color: color width: 2;
    }
}

species people skills: [moving] {
	rgb color;
	building living_place <- nil;
	building destination_place <- nil;
		
	pollution_cell current_cell <- pollution_cell with_min_of (distance_to (self.location, each.location));
	float mesured_pollution min: 0.0 max: 1.0;
	pollution_cell most_polluted_cell <- current_cell;
	
	int nb_mesures;
	
	list<pollution_cell> visited_cells_locally;
	list<pollution_cell> visited_cells;
	
	path path_followed;
	list<geometry> segments_followed;
	
	int go_out_hour;
	int go_out_min <- rnd(0, 59, 1);
	int go_home_hour;
	int go_home_min <- rnd(0, 59, 1);
		
	bool is_on_road;
		
	string objective; 
	
	point the_target <- nil;
	
	reflex time_to_leave when: current_date.hour = go_out_hour and current_date.minute = go_out_min and objective = "resting"{
		objective <- "working";
		the_target <- any_location_in (destination_place);
		list<geometry> total_segments <- path_between(the_graph, location, the_target).segments;
		segments_followed <- segments_followed + total_segments where (not (each in segments_followed));
		//save total_segments to: "../results/agent" + int(self) + ".shp" type: shp rewrite: false;
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
		
		//current_cell <- one_of (visited_cells_locally);
		current_cell <- pollution_cell with_min_of (distance_to (self.location, each.location));
		
		loop cell over: visited_cells_locally {
			cell.nb_mesures <- cell.nb_mesures + 1;
			cell.float_mesured_pollution <- mesure_pollution(cell);
			if (cell.float_mesured_pollution > most_polluted_cell.pollution){
				most_polluted_cell <- cell;
			}
			cell.grid_value <- (max_value - min_value) * cell.float_mesured_pollution + min_value;
			cell.mesured_color <- rgb(int(255 * cell.float_mesured_pollution), int(255 * (1 - cell.float_mesured_pollution)), 0);
		}
		visited_cells <- visited_cells + visited_cells_locally where (not (each in visited_cells));
		nb_mesures <- length(visited_cells);
		visited_cells_locally <- [];
		
		if the_target = location {
	    	the_target <- nil;
	    	is_on_road <- false;
	    }
	    
		save [current_date.hour, current_date.minute, living_place.location.x, living_place.location.y, destination_place.location.x, destination_place.location.y, 
			location.x, location.y, (max_value - min_value) * current_cell.pollution + min_value, most_polluted_cell.location.x, 
			(max_value - min_value) * most_polluted_cell.pollution + min_value] to: "../results/agent" + int(self) + ".csv" type:"csv" rewrite: false;
    }
    
    float mesure_pollution(pollution_cell current_cell_){
    	return current_cell_.pollution; // pas de bruit
    }
    
    
    map<building, float> gravitational_model(building starting_place, list<building> destination_to_choose){
    	
    	float max_surface <- destination_to_choose[0].shape.area;
    	float min_surface <- destination_to_choose[0].shape.area;
    	
    	loop build over:destination_to_choose{
    		if (build.shape.area > max_surface){
    			max_surface <- build.shape.area;
    		}
    		if (build.shape.area < min_surface){
    			min_surface <- build.shape.area;
    		}
    	}
    	
    	list<float> proba_list;
    	//write("debut du calcul");
    	loop build over:destination_to_choose{
    		//write(exp(- 0.015 * (starting_place distance_to build)));
    		//write(int(build));
    		proba_list << exp(- 0.005 * (starting_place distance_to build));
    	}
    		
    	return create_map(destination_to_choose, proba_list); //retourne une map avec en clé la liste de buildings candidats, et en valeur la probabilité d'affectation du building
    }
    
    
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

grid pollution_cell file: grid_data{
	float pollution min: 0.0 max: 1.0;
	
	float float_mesured_pollution min: 0.0 max: 1.0;
	rgb mesured_color <- #white;
	int nb_mesures <- 0;
	
	aspect pollution{
		draw square(25) color: color border: #black;
	}
	
	aspect mesured_pollution{
		draw square(25) color: mesured_color border: #black;
	}
}

experiment bike_traffic type: gui {
    parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
    parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
    parameter "Number of working agents" var: working_agents category: "Worker";
    parameter "Number of student agents" var: student_agents category: "Student";
    parameter "Number of leisure agents" var: leisure_agents category: "Leisure";
    
    parameter "Earliest hour to start work" var: hour_early_work_start category: "Worker" min: 2 max: 8;
    parameter "Latest hour to start work" var: hour_late_work_start category: "Worker" min: 8 max: 12;
    parameter "Earliest hour to end work" var: hour_early_work_end category: "Worker" min: 12 max: 16;
    parameter "Latest hour to end work" var: hour_late_work_end category: "Worker" min: 16 max: 23;
    
    parameter "Earliest hour to start study" var: hour_early_study_start category: "Student" min: 6 max: 12;
    parameter "Latest hour to start study" var: hour_late_study_start category: "Student" min: 10 max: 16;
    parameter "Earliest hour to end study" var: hour_early_study_end category: "Student" min: 13 max: 19;
    parameter "Latest hour to end study" var: hour_late_study_end category: "Student" min: 16 max: 21;
    
    parameter "Earliest hour to start leisure" var: hour_early_leisure_start category: "Leisure" min: 8 max: 13;
    parameter "Latest hour to start leisure" var: hour_late_leisure_start category: "Leisure" min: 12 max: 18;
    parameter "Earliest hour to end leisure" var: hour_early_leisure_end category: "Leisure" min: 11 max: 17;
    parameter "Latest hour to end leisure" var: hour_late_leisure_end category: "Leisure" min: 15 max: 21;
    
    parameter "Transparency of the pollution cells" var: transparency_pollution_cell category: "Pollution grid" min: 0.0 max: 1.0;
    parameter "Transparency of the mesured pollution cells" var: transparency_mesured_pollution_cell category: "Pollution grid" min: 0.0 max: 1.0;
    
    output{
    	display city_display type: opengl{
    		species building aspect: base;
    		species road aspect: base;
    		species worker aspect: base;
    		species student aspect: base;
    		species leisure aspect: base;	    	
    		species pollution_cell aspect: pollution transparency: transparency_pollution_cell;
    		
    	}
    	
    	display nb_persons_on_road refresh: every(5#cycles) {
    		chart "Nombre d'agents sur les routes" type: series {
				data "Nombre d'agents sur les routes" value: worker count (each.is_on_road = true) + student count (each.is_on_road = true) + leisure count (each.is_on_road = true);
			}
    	}
    	
    	display mesured_pollution refresh: every(5#cycles){
    		species pollution_cell aspect: mesured_pollution transparency: transparency_mesured_pollution_cell;
    	}
    	
    	display travel_distance refresh: every(10#cycles) {
    		chart "Distribution de la distance de trajet des agents" type: histogram background: #lightgrey{
				data "0 - 1 km" value: worker count (each.living_place distance_to each.destination_place < 150 #m) 
				+ student count (each.living_place distance_to each.destination_place < 150 #m) 
				+ leisure count (each.living_place distance_to each.destination_place < 150 #m) color: #blue;
				
				data "1 - 2 km" value: worker count (each.living_place distance_to each.destination_place >= 150 #m and each.living_place distance_to each.destination_place < 300 #m) 
				+ student count (each.living_place distance_to each.destination_place >= 150 #m and each.living_place distance_to each.destination_place < 300 #m) 
				+ leisure count (each.living_place distance_to each.destination_place >= 150 #m and each.living_place distance_to each.destination_place < 300 #m) color: #blue;
				
				data "2 - 3 km" value: worker count (each.living_place distance_to each.destination_place >= 300 #m and each.living_place distance_to each.destination_place < 450 #m) 
				+ student count (each.living_place distance_to each.destination_place >= 300 #m and each.living_place distance_to each.destination_place < 450 #m) 
				+ leisure count (each.living_place distance_to each.destination_place >= 300 #m and each.living_place distance_to each.destination_place < 450 #m) color: #blue;
				
				data "3 - 4 km" value: worker count (each.living_place distance_to each.destination_place >= 450 #m and each.living_place distance_to each.destination_place < 600 #m) 
				+ student count (each.living_place distance_to each.destination_place >= 450 #m and each.living_place distance_to each.destination_place < 600 #m) 
				+ leisure count (each.living_place distance_to each.destination_place >= 450 #m and each.living_place distance_to each.destination_place < 600 #m) color: #blue;
				
				data "4 - 5 km" value: worker count (each.living_place distance_to each.destination_place >= 600 #m and each.living_place distance_to each.destination_place < 750 #m) 
				+ student count (each.living_place distance_to each.destination_place >= 600 #m and each.living_place distance_to each.destination_place < 750 #m) 
				+ leisure count (each.living_place distance_to each.destination_place >= 600 #m and each.living_place distance_to each.destination_place < 750 #m) color: #blue;
				
				data "5 - 6 km" value: worker count (each.living_place distance_to each.destination_place >= 750 #m and each.living_place distance_to each.destination_place < 900 #m) 
				+ student count (each.living_place distance_to each.destination_place >= 750 #m and each.living_place distance_to each.destination_place < 900 #m) 
				+ leisure count (each.living_place distance_to each.destination_place >= 750 #m and each.living_place distance_to each.destination_place < 900 #m) color: #blue;
				
				data "6 - 7 km" value: worker count (each.living_place distance_to each.destination_place >= 900 #m and each.living_place distance_to each.destination_place < 1050 #m) 
				+ student count (each.living_place distance_to each.destination_place >= 900 #m and each.living_place distance_to each.destination_place < 1050 #m) 
				+ leisure count (each.living_place distance_to each.destination_place >= 900 #m and each.living_place distance_to each.destination_place < 1050 #m) color: #blue;
				
				data "7 - 8 km" value: worker count (each.living_place distance_to each.destination_place >= 1050 #m and each.living_place distance_to each.destination_place < 1200 #m) 
				+ student count (each.living_place distance_to each.destination_place >= 1050 #m and each.living_place distance_to each.destination_place < 1200 #m) 
				+ leisure count (each.living_place distance_to each.destination_place >= 1050 #m and each.living_place distance_to each.destination_place < 1200 #m) color: #blue;
				
			}	
    	}
		monitor "Date" value: current_date ;		
	}
}







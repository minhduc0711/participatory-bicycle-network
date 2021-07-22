/***
* Part of the SWITCH Project
* Author: Patrick Taillandier
* Tags: gis, OSM data
***/

model switch_utilities_gis
/*
 * Bases de données requises : 
 * https://download.geofabrik.de/europe/france.html
 * https://geoservices.ign.fr/documentation/diffusion/telechargement-donnees-libres.html#bd-topo
 * 
 */
 
global {
	
	string dataset_path <- "../includes/";
		
	file shape_file_roads <- shape_file("../includes/SHP Marseille/roads.shp");
	
	file elevation_data <- grid_file('../includes/DEM_Marseille.tif');
							
	geometry shape <- envelope(elevation_data);
	
	graph the_graph;
            
    int nb_for_road_shapefile_split <- 20000;
    
	
	init {
		float max_value <- elevation_cell max_of (each.grid_value);
		float min_value <- elevation_cell min_of (each.grid_value);
		ask elevation_cell {
			normalized_elevation <- (grid_value) / (max_value);
			if grid_value < -1{
				color <- #black;
			}
			else{
				color <- rgb(int(255 * normalized_elevation), int(255 * (normalized_elevation)), int(255 * (normalized_elevation)));
				
			}
		}
				
		write "Start the pre-processing process";

    	create road from: shape_file_roads with: [id::int(get("id")), fclass::get("fclass"), speed_coeff::float(get("s_coeff")),maxspeed::int(get("maxspeed"))]{
    		point first <- first(shape.points);
			point last <- last(shape.points);
    		if (not (first overlaps world)) or (not (last overlaps world)) {
				do die;
			}
			
			if length(shape.points) > 1{
				float altitude_first <- (elevation_cell where (first overlaps each))[0].grid_value; //(distance_to (first, each.location))).grid_value;
	    		float altitude_last <- (elevation_cell where (last overlaps each))[0].grid_value; //(distance_to (last, each.location))).grid_value;	
	    		
	    		if (altitude_last > -3 and altitude_first > -3 and shape.perimeter > 0){
    				slope <- sin((altitude_last - altitude_first) / shape.perimeter) * 180 / #pi;
    			}
	    	}
    	}
    	
		write "Number of roads created : "+ length(road);    	
		
		write("Saving roads");   
		 	
		save road to:"../includes/SHP Marseille/roads_slope.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed, "slope"::slope];
			
		
		write("over");

	}
	
}

grid elevation_cell file: elevation_data {
	float normalized_elevation min:0.0 max: 1.0;
}


species road  {
	int id;
	int maxspeed;
	string fclass;
	float speed_coeff;
	float slope;
		
	rgb color <- #red;
	
    aspect base {
    draw shape color: color width: 2;
    }
}


experiment generateGISdata type: gui {
	output {
		display map type: opengl draw_env: false{
			species elevation_cell;
			species road;
		}
	}
}
/***
* Part of the SWITCH Project
* Author: Patrick Taillandier
* Tags: gis, OSM data
***/

model switch_utilities_gis
/*
 * Ajoute un coefficient de vitesse correspondant à un poids dans le graphe des routes (coefficient de vitesse élevé = vitesse élevée à vélo)
 * Ajoute la vitesse du cycliste sur chaque portion de route 
 * Supprime les routes inaccessibles à vélo
 */
 
global {
	
	string city <- "Marseille";
	
	string dataset_path <- "../includes/" + city + "/";
		
	//define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "boudary_" + city + ".shp");

	file shape_file_roads <- shape_file(dataset_path + "roads.shp");	
				
	geometry shape <- envelope(data_file);
	
	graph the_graph;
        
    map<road,float> road_weights;
	
	init {
		write "Start the pre-processing process";
				
    	
    	create road from: shape_file_roads with: [id::int(get("id")), fclass::get("fclass"), maxspeed::int(get("maxspeed"))]{
    		
    		if fclass = "motorway" or fclass = "motorway_link"{do die;} //routes innacessibles aux vélos
			
			if fclass="trunk" or fclass="primary" or fclass="secondary" or fclass="tertiary" or fclass="bridleway" or fclass="cycleway"
			   or fclass="trunk_link" or fclass="primary_link" or fclass="secondary_link" {
    			speed_coeff <- 1.7;
    			speed <- 17 #km / #h;
    		}
			
			if fclass="unclassified" or fclass="residential" or fclass="service" or fclass="track" {
    			speed_coeff <- 1.2;
    			speed <- 12 #km / #h;
    		}
    		
    		if fclass="living_street" or fclass="pedestrian" or fclass="footway" or fclass="path" or fclass="steps" or fclass="unknown" {
    			speed_coeff <- 0.4;
    			speed <- 4 #km / #h;
    		}
    		
    	}
    	
		write "Number of roads created : "+ length(road);    	
				
		write("Saving roads");    	
		
		save road to: dataset_path + "roads_cyclists.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "mean_speed"::speed, "maxspeed"::maxspeed];
		
		write("over");
		
	}
}


species road  {
	int id;
	int maxspeed;
	string fclass;
	
	float speed_coeff <- 0.33;
	float speed <- 5 #km / #h;
		
    aspect base {
    draw shape width: 2;
    }
}

experiment generateGISdata type: gui {
	output {
		display map type: opengl draw_env: false{
			species road;
		}
	}
}

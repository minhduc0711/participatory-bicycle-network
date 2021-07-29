/***
* Part of the SWITCH Project
* Author: Patrick Taillandier
* Tags: gis, OSM data
***/

model switch_utilities_gis
/*
 * Ajoute un coefficient de vitesse correspondant à un poids dans le graphe des routes (coefficient de vitesse élevé = vitesse élevée à vélo) généré par le modèle 1
 * Ajoute la vitesse du cycliste sur chaque portion de route 
 * Supprime les routes inaccessibles à vélo
 */
 
global {
	
	string city <- "Marseille";
	
	string dataset_path <- "../includes/" + city + "/";
		
	//define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "boundary_" + city + ".shp");

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
    		}
			
			if fclass="unclassified" or fclass="residential" or fclass="service" or fclass="track" {
    			speed_coeff <- 1.2;
    		}
    		
    		if fclass="living_street" or fclass="pedestrian" or fclass="footway" or fclass="path" or fclass="steps" or fclass="unknown" {
    			speed_coeff <- 0.4;
    		}
    		
    	}
    	
		write "Number of roads created : "+ length(road);    	
				
		write("Saving roads");    	
		
		save road to: dataset_path + "roads_cyclists.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "s_coeff"::speed_coeff, "maxspeed"::maxspeed];
		
		write("over");
		
	}
}


species road  {
	int id;
	int maxspeed;
	string fclass;
	
	float speed_coeff <- 0.33;
		
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

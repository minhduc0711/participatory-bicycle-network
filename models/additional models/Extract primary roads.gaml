/***
* Part of the SWITCH Project
* Author: Patrick Taillandier
* Tags: gis, OSM data
***/

model switch_utilities_gis
/*
 * Génère un .shp contenant les routes principales dans la zone de Marseille
 * 
 */
 
global {
	
	string dataset_path <- "../includes/";
	
	//define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "boundary_marseille.shp");

	file shape_file_roads <- shape_file(dataset_path + "SHP Marseille/roads.shp");
	
	
	string boundary_name_field <-"NOM_COM_M";  //"nom_comm";
	
	float simplification_dist <- 1.0;
	//optional
			
	int nb_for_road_shapefile_split <- 20000;
	
	
	geometry shape <- envelope(data_file);
	
	graph the_graph;
        
    map<road,float> road_weights;
	
	init {
		write "Start the pre-processing process";
		create Boundary from: data_file {
			if (boundary_name_field != "") {
				string n <- shape get boundary_name_field;
				if (n != nil and n != "") {
					name <- n;
				}
			}
			if (simplification_dist > 0) {
				shape <- shape simplification simplification_dist;
			}
		}
				
    	
    	create road from: shape_file_roads with: [id::int(get("osm_id")), fclass::get("fclass"), maxspeed::int(get("maxspeed"))]{
    		if not (self overlaps world) {
				do die;
			}
			
			if not (fclass in ["motorway", "motorway_link", "primary", "primary_link", "trunk", "trunk_link"]){
				do die;
			}
			
			if fclass="cycleway"{
    			speed_coeff <- 2.0;
    		}
    		if fclass="tertiary"{
    			speed_coeff <- 1.8;
    		}
    		if fclass="secondary"{
    			speed_coeff <- 1.8;
    		}
    		if fclass="secondary_link"{
    			speed_coeff <- 1.8;
    		}
    		if fclass="residential"{
    			speed_coeff <- 1.9;
    		}
    		if fclass="unclassified"{
    			speed_coeff <- 1.7;
    		}
    		if fclass="primary"{
    			speed_coeff <- 1.7;
    		} 		
    		if fclass="pedestrian"{
    			speed_coeff <- 1.0;
    		}
    		if fclass="footway"{
    			speed_coeff <- 1.0;
    		}
    		
    		colorValue <- int(255*(speed_coeff - 1)); //route rapide (speed coeff = 2) : verte. route lente (speed coeff = 1) : rouge
			color <- rgb(max([0, 255 - colorValue]), min([255, colorValue]),0);
    		
    		list<Boundary> bds <- (Boundary overlapping location);
			if empty(bds){do die;} 
			else {
				boundary <- first(bds);
			}
    	}
    	
		write "Number of roads created : "+ length(road);    	
				
		write("Saving roads");    	
		map<Boundary, list<road>> roads_per_boundary <- road group_by (each.boundary);
		loop bd over: roads_per_boundary.keys {
			list<road> bds <- roads_per_boundary[bd];
			if (length(bds) > nb_for_road_shapefile_split) {
				int i <- 1;
				loop while: not empty(bds)  {
					list<road> bds_ <- nb_for_road_shapefile_split first bds;
					save bds_ to:(dataset_path+ bd.name +"/roads_" +i+".shp") type: shp attributes: ["id"::id,"sub_area"::boundary.name,"fclass"::fclass, "maxspeed"::maxspeed];
					bds <- bds - bds_;
					i <- i + 1;
				}
			} else {
				save bds to:dataset_path+ bd.name +"/primary_roads.shp" type: shp attributes: ["id"::id,"sub_area"::boundary.name,"fclass"::fclass, "maxspeed"::maxspeed];
			}
		}
		write("over");
		
	}
}


species road  {
	Boundary boundary;
	int id;
	int maxspeed;
	string fclass;
	
	float speed_coeff <- 1.0;
	
    int colorValue <- int(255*(speed_coeff - 1)) update: int(255*(speed_coeff - 1)); //route rapide (speed coeff = 2) : verte. route lente (speed coeff = 1) : rouge
	rgb color <- rgb(max([0, 255 - colorValue]), min([255, colorValue]),0)  update: rgb(max([0, 255 - colorValue]), min([255, colorValue]),0) ;
	
    aspect base {
    draw shape color: color width: 2;
    }
}

species Boundary {
	aspect default {
		draw shape color: #gray border: #black;
	}
}

experiment generateGISdata type: gui {
	output {
		display map type: opengl draw_env: false{
			species road;
		}
	}
}

/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/*
 * Génère un raster contenant l'information de distance à la route principale
 * 
 */

global {
    file shape_file_buildings <- shape_file("../includes/Marseille/buildings_ign.shp");
                                
    file shape_file_main_roads <- shape_file("../includes/Marseille/SHP Marseille/primary_roads.shp");    
                   
    file grid_data <- file('../includes/Marseille/raster_dep13_NO2_12_02_2018_analyse_32float_marseille.tif');
    
    geometry shape <- envelope(grid_data); 
    
    bool distance_roads <- false; //true : retourne un raster donnant la distance à la route principale
    bool volume_buildings <- true;
        
    init{
    	
    	if distance_roads{
	    	create road from: shape_file_main_roads {
	 
	    	}
	    	
			ask environment_grid {
				grid_value <- 100 #km;
				
				loop rd over: road{
					float distance <- self.location distance_to rd.location;
					if distance < grid_value{
						grid_value <- distance;
					}
				}
			}
			save environment_grid to:"../results/Marseille/distance_grid.tif" type:geotiff;
			
		}
		
		if volume_buildings{
			create building from: shape_file_buildings with: [height::float(read("HAUTEUR"))];
			
			ask environment_grid {
				grid_value <- 0.0;
				
				loop build over: building overlapping self{
					float surface_inter <- (build inter self).area;
					grid_value <- grid_value + build.height * surface_inter;
				}
			}
			save environment_grid to:"../includes/Marseille/environment/buildings_volume.tif" type:geotiff;
		}
    }
    
}

species road  {
	string fclass;
	
	int maxspeed;
	
	int number_of_agents;
	
	float speed_coeff <- 1.0;
	
	rgb color <- #red;
	
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
    draw shape color: color ;
    }
}

grid environment_grid file: grid_data{
			
}

experiment bike_traffic type: gui {
 
}







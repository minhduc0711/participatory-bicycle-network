/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/* 
 * This model generates the environment close to the measures point
 * 
 */
 
import "params.gaml"

global {
    
    file bound <- shape_file("../includes/Marseille/boundary_Marseille.shp");
    
    geometry shape <- envelope(bound);
    
    file shape_file_buildings <- shape_file("../includes/Marseille/buildings_ign.shp");
    
    file shape_file_vegetation <- shape_file("../includes/Marseille/environment/ZONE_DE_VEGETATION.shp");
    
    file roads_ign <- shape_file("../includes/Marseille/environment/roads_ign.shp");
    
    file primary_roads <- shape_file("../includes/Marseille/environment/primary_roads.shp");
    
	file measures_csv <- csv_file("../results/Marseille/measures_" + number_of_sensors + ".csv",true);

    init{    	

    	create building from: shape_file_buildings with: [height::float(read("HAUTEUR"))];
    	
    	create road from: roads_ign;
    	list<road> rd_1_voie <- road where (each.NB_VOIES = 1);
    	list<road> rd_2_voie <- road where (each.NB_VOIES = 2);
    	list<road> rd_3_voie <- road where (each.NB_VOIES = 3);
    	list<road> rd_4_voie <- road where (each.NB_VOIES = 4);
    	list<road> rd_5_voie <- road where (each.NB_VOIES = 5);
    	list<road> rd_6_voie <- road where (each.NB_VOIES = 6);
    	
    	list<road> list_rd_0_4_width <- road where (each.LARGEUR <= 4.0);
    	list<road> list_rd_4_6_width <- road where (each.LARGEUR > 4.0 and each.LARGEUR <= 6.0);
    	list<road> list_rd_6_8_width <- road where (each.LARGEUR > 6.0 and each.LARGEUR <= 8.0);
    	list<road> list_rd_8_max_width <- road where (each.LARGEUR > 8.0);
    	
    	create primary_road from: primary_roads;
    	
    	create vegetation from: shape_file_vegetation;
    	
    	list<vegetation> list_bois <- vegetation where (each.NATURE = 'Bois');
    	list<vegetation> list_foret <- vegetation where (each.NATURE = 'Forêt fermée de conifères' or each.NATURE = 'Forêt fermée de feuillus'
    												     or each.NATURE = 'Forêt fermée mixte' or each.NATURE = 'Forêt ouverte');
    	list<vegetation> list_haie <- vegetation where (each.NATURE = 'Haie');
    	    		
	    	create measure from: measures_csv{
	    		write(self.ID);
	    		location <- point(to_GAMA_CRS({self.longitude, self.latitude}, 'EPSG:2154'));
	    		geometry disque <- circle(50, location);
	    		
	    		create environment {
	    			ID <- myself.ID;
	    			name_of_agent <- myself.name_of_agent;
	    			longitude <- myself.longitude;
	    			latitude <- myself.latitude;
	    			
	    			loop build over: building overlapping disque{
						float surface_inter <- (build inter disque).area;
						buildings_volume <- buildings_volume + build.height * surface_inter;
					}
					
					loop rd over: rd_1_voie overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						voie_1 <- voie_1 + perimeter_inter;
					}
					
					loop rd over: rd_2_voie overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						voie_2 <- voie_2 + perimeter_inter;
					}
					
					loop rd over: rd_3_voie overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						voie_3 <- voie_3 + perimeter_inter;
					}
					
					loop rd over: rd_4_voie overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						voie_4 <- voie_4 + perimeter_inter;
					}
					
					loop rd over: rd_5_voie overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						voie_5 <- voie_5 + perimeter_inter;
					}
					
					loop rd over: rd_6_voie overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						voie_6 <- voie_6 + perimeter_inter;
					}
					
					loop rd over: list_rd_0_4_width overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						road_0_4_width <- road_0_4_width + perimeter_inter;
					}
					
					loop rd over: list_rd_4_6_width overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						road_4_6_width <- road_4_6_width + perimeter_inter;
					}
					
					loop rd over: list_rd_6_8_width overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						road_6_8_width <- road_6_8_width + perimeter_inter;
					}
					
					loop rd over: list_rd_8_max_width overlapping disque{
						float perimeter_inter <- (rd inter disque).perimeter;
						road_8_max_width <- road_8_max_width + perimeter_inter;
					}
					
					loop veg over: list_bois overlapping disque{
						float area_inter <- (veg inter disque).area;
						bois <- bois + area_inter;
					}
					
					loop veg over: list_foret overlapping disque{
						float area_inter <- (veg inter disque).area;
						foret <- foret + area_inter;
					}
					
					loop veg over: list_haie overlapping disque{
						float area_inter <- (veg inter disque).area;
						haie <- haie + area_inter;
					}
					
					distance_to_main_road <- myself distance_to (primary_road closest_to myself);
					
	    		}
	    	}
	    	
	    	ask environment {
		    			save [ID, name_of_agent, longitude, latitude, buildings_volume, voie_1, voie_2, voie_3, voie_4, voie_5, voie_6, road_0_4_width, road_4_6_width, road_6_8_width, road_8_max_width, distance_to_main_road, bois, foret, haie]
	    				to: "../results/Marseille/environment_of_measures_" + number_of_sensors + "_sensors.csv" type:"csv" rewrite: false;   
		    }  
		
    	
    	
	}

}

species measure { // seulement besoin de la localisation de la mesure, etant donne que l'environnement est suppose stationnaire
	int ID;
	string name_of_agent;
	float longitude;
	float latitude;
}

species environment{ // flotants correspondant à l'environnement dans un disque de 50m de rayon centré sur la mesure
	int ID; // ID égal à celui de la mesure
	string name_of_agent;
	float longitude;
	float latitude;
	
	float road_0_4_width; // longueur de route dans le disque ayant comme attribut : largeur <= 4 
	float road_4_6_width; // longueur de route dans le disque ayant comme attribut : 4 < largeur <= 6 
	float road_6_8_width; // longueur de route dans le disque ayant comme attribut : 6 < largeur <= 8 
	float road_8_max_width; // longueur de route dans le disque ayant comme attribut : 8 < largeur
	float voie_1;
	float voie_2;
	float voie_3;
	float voie_4;
	float voie_5;
	float voie_6;
	float buildings_volume;
	float distance_to_main_road;
	float bois; //surface de bois dans le disque
	float foret;
	float haie;
}

species road {
	float LARGEUR;
	int NB_VOIES;
}

species primary_road{
}

species building {
	int id;
    string type; 
    string types_str;
    list<string> types;
    float height;        
}

species vegetation {
	string NATURE; //Bois, Forêt fermée de conifères, Forêt fermée de feuillus, Forêt fermée mixte, Forêt ouverte, Haie, Lande ligneuse, Verger, Vigne (types BD TOPO)
}



experiment environment_measures type: gui {
}
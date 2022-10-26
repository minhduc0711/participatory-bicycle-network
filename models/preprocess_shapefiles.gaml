/***
 * Part of the SWITCH Project
 * Author: Nathan Coisne, code inspired from Patrick Taillandier
 * Tags: gis, OSM data
 ***/

model switch_utilities_gis
/*
 * Genere les fichiers buildings.shp et roads.shp pour la zone choisie
 *
 * Données requises pour générer les fichiers buildings.shp et roads.shp d'une ville quelconque :
 * https://download.geofabrik.de/europe/france.html pour le shp 'initial' des builings
 * https://geoservices.ign.fr/documentation/diffusion/telechargement-donnees-libres.html#bd-topo pour le shapefile à partir duquel on extrait les attributs qu'on donne aux buildings initiaux
 * Les frontières de la zone considérée
 *
 *
 */
import "params.gaml"

global {
	file shape_file_bounds <- shape_file(bounds_path);
	//define the initial building shapefile, extracted from OSM database
	file shape_file_buildings_osm <- shape_file(includes_shp_dir + "buildings_osm.shp");
	//define the OSM points of interest buildings, for more types
	file shape_file_buildings_poi <- shape_file(includes_shp_dir + "buildings_poi.shp");
	//define the building shapefile with many types, extracted from IGN database
	file shape_file_buildings_ign <- shape_file(includes_shp_dir + "buildings_ign.shp");
	//define the initial building shapefile, extracted from OSM database
	file shape_file_roads <- shape_file(includes_shp_dir + "roads_osm.shp");


	list<string> shop_places <- ["commercial", "kiosk", "chapel", "church", "service", "Commercial et services", "Religieux", "religious"];
	list<string> sport_places <- ["Sportif"];
	list<string> living_places <- ["house", "apartments", "dormitory", "hotel", "residential", "Résidentiel"];
	list<string> work_places <- ["industrial", "office", "construction", "garages", "hospital"];
	list<string> study_places <- ["university", "college", "school"];
	list<string> leisure_places <- ["commercial", "kiosk", "chapel", "church", "service", "Sportif", "Commercial et services", "Religieux", "religious"];

	float min_area_buildings <- 20.0;
	bool parallel <- true;

	geometry shape <- envelope(shape_file_bounds);

	graph the_graph;

	map<road,float> road_weights;

	init {
		write "Start the pre-processing process";
		create boundary from: shape_file_bounds;

		list<int> list_of_id;
		if !file_exists(cleaned_buildings_path) {
			create building from: shape_file_buildings_osm with: [type::get ("type"), id::int(get("osm_id"))]{
				if !(self overlaps boundary[0]) {
					do die;
				}
				list_of_id << id;
				if (type != nil and type != ""){
					types << type;
				}
			}


			ask building where (each.shape.area < min_area_buildings) {
				do die;
			}

			write "Number of buildings created : "+ length(building);

			create building_ign from: shape_file_buildings_ign {
				if !(self overlaps boundary[0]) {
					do die;
				}
			}

			write "Number of buildings ign created : "+ length(building_ign);

			ask building parallel: parallel {
				list<building_ign> neigh <- building_ign overlapping self;
				if not empty(neigh) {
					building_ign bestCand;
					if (length(neigh) = 1) {
						bestCand <- first(neigh);
					} else {
						bestCand <- neigh with_max_of (each inter self).area;
						if (bestCand = nil) {
							bestCand <- neigh with_min_of (each.location distance_to location);
						}
						if (bestCand = nil){
							write("aucun building correspondant a ce building ign");
						}
					}
					if (bestCand.USAGE1 != nil and bestCand.USAGE1 != ""){
						types << bestCand.USAGE1;
					}
					else if (bestCand.USAGE2 != nil and bestCand.USAGE2 != ""){
						types << bestCand.USAGE2;
					}

					if (bestCand.HAUTEUR != nil and bestCand.HAUTEUR > 0){
						height <- bestCand.HAUTEUR;
					}
				}
			}

			create building from: shape_file_buildings_poi with: [id::int(read("osm_id")), type::read("fclass")]{
				if !(self overlaps boundary[0]) {
					do die;
				}

				if !(id in list_of_id) {
					list_of_id << id;
					types_str <- type;
					types << type;
				} else { // fclass devient le type du bâtiment déjà existant
					building real_building <- building first_with (each.id = self.id);
					real_building.type <- type;
					real_building.types << type;
					real_building.types_str <- type + "," + real_building.types_str;
					do die;
				}
			}

			ask building where empty(each.types) {
				do die;
			}

			ask building parallel: parallel {
				type <- first(types); //si le building a déjà un type dans le shapefile initial : on le garde en position 1. Sinon on prend celui de building_ign (USAGE1 ou USAGE2)

				types_str <- type;

				if (length(types) > 1) {
					loop i from: 1 to: length(types) - 1 {
						types_str <-types_str + "," + types[i] ;
					}
				}
			}

			ask building_ign{
				do die;
			}

			write("Saving buildings");
			save building to: cleaned_buildings_path type: shp 
				attributes: ["id"::id,"type"::type, "types_str"::types_str ,"height"::height];
		} else {
			create building from: shape_file(cleaned_buildings_path);
			write "buildings are already cleaned. Nothing to do.";
		}

		if !file_exists(cleaned_roads_path) {
			write("cleaning roads");
//			list<geometry> clean_lines <- clean_network(shape_file_roads.contents,3.0 , true, true); // peut prendre beaucoup de temps pour des zones étendues

			create road from: shape_file_roads with: [id::int(get("osm_id")), fclass::get("fclass"), maxspeed::int(get("maxspeed"))]{
				if !(self overlaps boundary[0]) {
					do die;
				}

				if fclass = "motorway" or fclass = "motorway_link"{do die;} //routes innacessibles aux vélos

				if fclass="trunk" or fclass="primary" or fclass="secondary" or 
						fclass="tertiary" or fclass="bridleway" or fclass="cycleway"
						or fclass="trunk_link" or fclass="primary_link" or fclass="secondary_link" {
					speed_coeff <- 1.7;
				}

				if fclass="unclassified" or fclass="residential" or fclass="service" or fclass="track" {
					speed_coeff <- 1.2;
				}

				if fclass="living_street" or fclass="pedestrian" or fclass="footway" or 
						fclass="path" or fclass="steps" or fclass="unknown" {
					speed_coeff <- 0.4;
				}
			}
			// Remove small disconnected subgraphs
			graph road_graph <- main_connected_component(as_edge_graph(road));
			ask road where !(each in road_graph.edges) {
				do die;
			}

			write("Saving roads");
			save road to: cleaned_roads_path type: shp attributes: ["id"::id, "fclass"::fclass,
				"maxspeed"::maxspeed, "s_coeff"::speed_coeff];
		} else {
			create road from: shape_file(cleaned_roads_path);
			write "Roads are already cleaned. Nothing to do.";
		}
	}
}

species building_ign {
	/*nature du bati; valeurs possibles:
	 * Indifférenciée | Arc de triomphe | Arène ou théâtre antique | Industriel, agricole ou commercial |
	 Chapelle | Château | Eglise | Fort, blockhaus, casemate | Monument | Serre | Silo | Tour, donjon | Tribune | Moulin à vent
	 */
	string NATURE;

	/*
	 * Usage du bati; valeurs possibles:  Agricole | Annexe | Commercial et services | Industriel | Religieux | Sportif | Résidentiel |
	 Indifférencié
	 */
	string USAGE1; //usage principale
	string USAGE2; //usage secondaire
	int NB_LOGTS; //nombre de logements;
	int NB_ETAGES;// nombre d'étages
	float HAUTEUR;
}
species building {
	string type;
	list<string> types;
	string types_str;
	float height;
	int id;

	aspect base {
		draw shape color: #gray;
	}
}

species road {
	int id;
	int maxspeed;
	string fclass;
	float speed_coeff <- 0.33;

	aspect base {
		draw shape color: color width: 2;
	}
}

species boundary {}

experiment preprocess type: gui {
	output {
		display city_display type: opengl {
			species road aspect: base refresh: false;
			species building aspect: base refresh: false;
		}
	}
}

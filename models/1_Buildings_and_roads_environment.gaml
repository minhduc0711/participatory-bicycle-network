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

global {

	string city <- "Marseille";

	string dataset_path <- "../includes/" + city + "/";

	//define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "boundary_" + city + ".shp");

	//define the initial building shapefile, extracted from OSM database
	file shape_file_buildings <- shape_file(dataset_path + "buildings_" + city + ".shp");

	//define the OSM points of interest buildings, for more types
	file shape_file_pois <- shape_file("../includes/" + city + "/points_of_interest.shp");

	//define the building shapefile with many types, extracted from IGN database
	file ign_file <-  shape_file(dataset_path + "buildings_ign.shp");

	//define the initial building shapefile, extracted from OSM database
	file shape_file_roads <- shape_file(dataset_path + "roads_" + city + ".shp");


	list<string> shop_places <- ["commercial", "kiosk", "chapel", "church", "service", "Commercial et services", "Religieux", "religious"];
	list<string> sport_places <- ["Sportif"];

	float min_area_buildings <- 20.0;
	int nb_for_building_shapefile_split <- 50000;
	int nb_for_road_shapefile_split <- 20000;

	list<string> living_places <- ["house", "apartments", "dormitory", "hotel", "residential", "Résidentiel"];
	list<string> work_places <- ["industrial", "office", "construction", "garages", "hospital"];
	list<string> study_places <- ["university", "college", "school"];
	list<string> leisure_places <- ["commercial", "kiosk", "chapel", "church", "service", "Sportif", "Commercial et services", "Religieux", "religious"];

	bool parallel <- true;

	bool buildings <- false;
	bool roads <- true;


	geometry shape <- envelope(data_file);

	graph the_graph;

	map<road,float> road_weights;

	init {
		write "Start the pre-processing process";

		list<int> list_of_id;
		if buildings{
			create Building from: shape_file_buildings with: [type::get ("type"), id::int(get("osm_id"))]{
				if not (self overlaps world) {
					do die;
				}
				list_of_id << id;
				if (type != nil and type != ""){
					types << type;
				}
			}

			write "Number of buildings created : "+ length(Building);

			ask Building where (each.shape.area < min_area_buildings) {
				do die;
			}

			write "Small building removed";


			create Building_ign from: ign_file {
				if not (self overlaps world) {
					do die;
				}
			}

			write "Number of buildings ign created : "+ length(Building_ign);

			ask Building parallel: parallel {
				list<Building_ign> neigh <- Building_ign overlapping self;
				if not empty(neigh) {
					Building_ign bestCand;
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

			create Building from: shape_file_pois with: [id::int(read("osm_id")), type::read("fclass")]{
				if not (self overlaps world){
					do die;
				}

				if not (id in list_of_id){

					list_of_id << id;

					types_str <- type;
					types << type;

				}

				else{ // fclass devient le type du bâtiment déjà existant
					Building real_building <- Building  first_with (each.id = self.id);
					real_building.type <- type;
					real_building.types << type;
					real_building.types_str <- type + "," + real_building.types_str;
					do die;
				}
			}


			ask Building where empty(each.types){
				do die;
			}

			ask Building parallel: parallel {
				type <- first(types); //si le building a déjà un type dans le shapefile initial : on le garde en position 1. Sinon on prend celui de building_ign (USAGE1 ou USAGE2)

				types_str <- type;

				if (length(types) > 1) {
					loop i from: 1 to: length(types) - 1 {
						types_str <-types_str + "," + types[i] ;
					}
				}
			}

			ask Building_ign{
				do die;
			}

			write("All buildings created and typed. Start cleaning roads");
		}


		if roads{
			write("cleaning roads");
			list<geometry> clean_lines <- clean_network(shape_file_roads.contents,3.0 , true, true); // peut prendre beaucoup de temps pour des zones étendues
			write("road shapefile cleaned");

			create road from: clean_lines with: [id::int(get("osm_id")), fclass::get("fclass"), maxspeed::int(get("maxspeed"))]{
				if not (self overlaps world) {
					do die;
				}
			}
			write "Number of roads created : "+ length(road);

		}

		if buildings{
			write("Saving buildings");
			save Building to: dataset_path + "buildings.shp" type: shp attributes: ["id"::id,"type"::type, "types_str"::types_str ,"height"::height];


		}

		if roads{
			write("Saving roads");
			save road to: dataset_path + "roads.shp" type: shp attributes: ["id"::id,"fclass"::fclass, "maxspeed"::maxspeed];

		}
	}
}

species Building_ign {
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
species Building {
	string type;
	list<string> types;
	string types_str;
	float height;
	int id;
}

species road  {
	int id;
	int maxspeed;
	string fclass;

	aspect base {
		draw shape color: color width: 2;
	}
}


experiment generateGISdata type: gui {
}

/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/* 
 * This model generates a regression between the pollution level given by "Synthetc measures from agents' travels" and the environment indicators generated in "Measures' environment"
 * The model is not completed because of the lack of a temporal indicator, essential for this simulation (the pollutant contration varies throughout the day).
 * One attempt of temporal indicator in this model is the direct use of the measurement date, without success.
 * 
 */
 
import "params.gaml"
 

global {
		
	file measures_csv;

	file environment_csv;

    file measures_to_predict_csv;

	file environment_for_prediction_csv;
	
    init{ 

       	//matrice de régression routes largeur: DATE, longueur de route 0-4, 4-6, 6-8, 8-max, NO2
    	//matrice de régression routes voies: DATE, voies 1, 2, 3, 4, 5, 6, NO2
    	//matrice de régression bâtiments: DATE, buildings_volume, NO2
		//matrice de régression végétation: DATE, bois, foret, haie, NO2
    	    	
    		measures_csv <- csv_file("../results/Marseille/measures_" + number_of_sensors + ".csv",true);
    		environment_csv <- csv_file("../results/Marseille/environment_of_measures_" + number_of_sensors + "_sensors.csv",true);
    		
    		create measure from: measures_csv;
    		create environment from: environment_csv;
    		    		
    		list<float> pollution_NO2;
    		list<float> pollution_O3;
    		list<float> pollution_PM10;
    		list<float> pollution_PM25;
    		
    		list<float> ind_date;
    		
    		loop m over: measure {
    			pollution_NO2 << m.NO2_concentration;
    			pollution_O3 << m.O3_concentration;
    			pollution_PM10 << m.PM10_concentration;
    			pollution_PM25 << m.PM25_concentration;
    			string time_m <- (((m.time_of_measure split_with "'(")[1]) split_with ")'")[0];
    			ind_date << float(date(time_m));
    		}
    		    	    		
    		list<float> ind_voies_1;
    		list<float> ind_voies_2;
    		list<float> ind_voies_3;
    		list<float> ind_voies_4;
    		list<float> ind_voies_5;
    		list<float> ind_voies_6;
    		
    		list<float> ind_buildings_volume;
    		
    		list<float> ind_dist_main_roads;
    		
    		list<float> ind_road_0_4_width;
			list<float> ind_road_4_6_width;
			list<float> ind_road_6_8_width;
			list<float> ind_road_8_max_width;
			
			list<float> ind_bois;
			list<float> ind_foret;
			list<float> ind_haie;
    		
    		loop env over: environment {
    			ind_voies_1 << env.voie_1;
    			
    			ind_voies_2 << env.voie_2;
    			ind_voies_3 << env.voie_3;
    			ind_voies_4 << env.voie_4;
    			ind_voies_5 << env.voie_5;
    			ind_voies_6 << env.voie_6;
    			
    			ind_buildings_volume << env.buildings_volume;
    			
    			ind_dist_main_roads << env.distance_to_main_road;
    			
    			ind_road_0_4_width << env.road_0_4_width;
    			ind_road_4_6_width << env.road_4_6_width;
    			ind_road_6_8_width << env.road_6_8_width;
    			ind_road_8_max_width << env.road_8_max_width;
    			
    			ind_bois << env.bois;
    			ind_foret << env.foret;
    			ind_haie << env.haie;
    		}
    		    		
    		matrix regression_matrix_NO2 <- matrix(ind_voies_1, ind_voies_2, ind_voies_3, ind_voies_4, ind_voies_5, ind_voies_6, ind_buildings_volume, 
    											   ind_dist_main_roads, ind_bois, ind_foret, ind_haie, pollution_NO2);
    							       	    		
    		regression NO2_regression <- build(regression_matrix_NO2);
    		
    		write("regressions generees. debut de la prediction des trajets restants");
    		
    		ask measure{do die;}
    		ask environment{do die;}
    		
    		// prediction des trajets non réalisés à partir de l'environnement de ces trajets
    		
    		measures_to_predict_csv <- csv_file("../results/Marseille/measures_to_predict_" + number_of_test_travels + ".csv",true);
    		environment_for_prediction_csv <- csv_file("../results/Marseille/environment_of_measures_to_predict_" + number_of_test_travels + ".csv",true);
    		
    		create measure from: measures_to_predict_csv; // mesures à prédire pour les agents student restants
    		create environment from: environment_for_prediction_csv;
    		
    		loop env over: environment {
    			measure associated_measure <- measure first_with (each.ID = env.ID);
    			string time_m <- (((associated_measure.time_of_measure split_with "'(")[1]) split_with ")'")[0];
    			float predict_date <- float(date(time_m));
    			associated_measure.predicted_NO2_concentration <- predict(NO2_regression, [env.voie_1, env.voie_2, env.voie_3, env.voie_4, env.voie_5, env.voie_6, 
    																	  env.buildings_volume, env.distance_to_main_road, env.bois, env.foret, env.haie]);
    		}
    		
    		ask measure{
			
				save [ID, name_of_agent, longitude, latitude, time_of_measure, NO2_concentration, predicted_NO2_concentration, O3_concentration, 
					  predicted_O3_concentration, PM10_concentration, predicted_PM10_concentration, PM25_concentration, predicted_PM25_concentration] 
	    		to: "../results/Marseille/" + number_of_test_travels + "_measures_predicted_" + number_of_sensors + "_sensors.csv" type:"csv" rewrite: false;
	    				
	    	}
	}

}

species measure {
	int ID;
	string name_of_agent;
	float longitude;
	float latitude;
	string time_of_measure;
	float NO2_concentration;
	float O3_concentration;
	float PM10_concentration;
	float PM25_concentration;
	
	float predicted_NO2_concentration;
	float predicted_O3_concentration;
	float predicted_PM10_concentration;
	float predicted_PM25_concentration;
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

species position_travel {
	
}
experiment regression_prediction type: gui {

}
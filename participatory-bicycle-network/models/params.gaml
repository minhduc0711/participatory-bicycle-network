/**
* Name: params
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model params



global {
	string city <- "Marseille";	
	
	bool test_population <- true; // permet de générer une population test 20 fois moins peuplée que la population réelle
	
    bool entire_population <- false; //true pour générer les mesures de tous les agents (pour vérifier des expositions de populations avec le modèle Agents' exposition)
    
    bool workers <- true;
    bool students <- true;
    bool leisures <- true;
    
    bool measure_NO2 <- true;
    bool measure_O3 <- true;
    bool measure_PM10 <- true;
    bool measure_PM25 <- true;
    
    int number_of_sensors <- 50; //represente le nombre de cyclistes équipés de capteurs dans la ville
    
    int number_of_test_travels <- 5; //represente le nombre de cyclistes dont les niveaux de pollution rencontrés seront prédits
    
}
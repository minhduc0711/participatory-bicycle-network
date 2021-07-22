/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/* 
 * This model calculates every population's exposition to each pollutant, thanks to measures generated in 'synthetic measures from agents' travels'
 * 
 */

global {
		
    file measures_csv;
    bool workers <- false; // une seule population en 'true' à la fois pour le stockage des mesures par type d'agent
    bool students <- true;
    bool leisures <- false;

    init{    	
    	
    	if workers{
    		write("loading workers measures");
    		
    		measures_csv <- csv_file("../results/Marseille/worker/workers_measures.csv",true);
    		
    		create measure from: measures_csv{
	    		
	    		if(self.ID = 100000 or self.ID = 200000 or self.ID = 300000 or self.ID = 400000 or self.ID = 500000) {write(self.ID);}	    	
	    		
	    	}
	    	
	    	write("calcul exposition of workers");
	    	
	    	loop i from: 0 to: 3600{
	    		
	    		write(i);
	    		
	    		list<measure> list_of_measures <- measure where (each.name_of_agent = 'worker[' + i + ']');
	    		list<float> list_of_NO2;
	    		list<float> list_of_O3;
	    		list<float> list_of_PM10;
	    		list<float> list_of_PM25;
	    		
	    		loop m over: list_of_measures{
	    			if (m.NO2_concentration > 0) {list_of_NO2 << m.NO2_concentration;}
	    			if (m.O3_concentration > 0) {list_of_O3 << m.O3_concentration;}
	    			if (m.PM10_concentration > 0) {list_of_PM10 << m.PM10_concentration;}
	    			if (m.PM25_concentration > 0) {list_of_PM25 << m.PM25_concentration;}
	    		}
	    		
	    		create worker{
	    			name_of_agent <- 'worker[' + i + ']';
	    			
	    			NO2_mean_exposition <- mean (list_of_NO2);
	    			O3_mean_exposition <- mean (list_of_O3);
	    			PM10_mean_exposition <- mean (list_of_PM10);
	    			PM25_mean_exposition <- mean (list_of_PM25);
	    			
	    			NO2_max <- max (list_of_NO2);
	    			O3_max <- max (list_of_O3);
	    			PM10_max <- max (list_of_PM10);
	    			PM25_max <- max (list_of_PM25);
	    			
	    		}	
	    	}
	    	ask worker {
		    			save [name_of_agent, NO2_mean_exposition, NO2_max, O3_mean_exposition, O3_max, PM10_mean_exposition, PM10_max, PM25_mean_exposition, PM25_max] 
	    				to: "../results/Marseille/worker/workers_exposition.csv" type:"csv" rewrite: false;
		    	}
    	}
    	
    	if students{
    		write("loading students measures");
    		
    		measures_csv <- csv_file("../results/Marseille/student/students_measures.csv",true);
    		
    		create measure from: measures_csv{
	    		
	    		if(self.ID = 100000 or self.ID = 200000 or self.ID = 300000 or self.ID = 400000 or self.ID = 500000) {write(self.ID);}	    	
	    		
	    	}
	    	
	    	write("calcul exposition of students");
	    	
	    	loop i from: 0 to: 2236{
	    		
	    		write(i);
	    		
	    		list<measure> list_of_measures <- measure where (each.name_of_agent = 'student[' + i + ']');
	    		list<float> list_of_NO2;
	    		list<float> list_of_O3;
	    		list<float> list_of_PM10;
	    		list<float> list_of_PM25;
	    		
	    		loop m over: list_of_measures{
	    			if (m.NO2_concentration > 0) {list_of_NO2 << m.NO2_concentration;}
	    			if (m.O3_concentration > 0) {list_of_O3 << m.O3_concentration;}
	    			if (m.PM10_concentration > 0) {list_of_PM10 << m.PM10_concentration;}
	    			if (m.PM25_concentration > 0) {list_of_PM25 << m.PM25_concentration;}
	    		}
	    		
	    		create student{
	    			name_of_agent <- 'student[' + i + ']';
	    			
	    			NO2_mean_exposition <- mean (list_of_NO2);
	    			O3_mean_exposition <- mean (list_of_O3);
	    			PM10_mean_exposition <- mean (list_of_PM10);
	    			PM25_mean_exposition <- mean (list_of_PM25);
	    			
	    			NO2_max <- max (list_of_NO2);
	    			O3_max <- max (list_of_O3);
	    			PM10_max <- max (list_of_PM10);
	    			PM25_max <- max (list_of_PM25);
	    			
	    		}	
	    	}
	    	ask student {
		    			save [name_of_agent, NO2_mean_exposition, NO2_max, O3_mean_exposition, O3_max, PM10_mean_exposition, PM10_max, PM25_mean_exposition, PM25_max] 
	    				to: "../results/Marseille/student/students_exposition.csv" type:"csv" rewrite: false;
		    	}
    	}
    	
    	if leisures{
    		write("loading leisures measures");
    		
    		measures_csv <- csv_file("../results/Marseille/worker/leisures_measures.csv",true);
    		
    		create measure from: measures_csv{
	    		
	    		if(self.ID = 100000 or self.ID = 200000 or self.ID = 300000 or self.ID = 400000 or self.ID = 500000) {write(self.ID);}	    	
	    		
	    	}
	    	
	    	write("calcul exposition of leisures");
	    	
	    	loop i from: 0 to: 7527{
	    		
	    		write(i);
	    		
	    		list<measure> list_of_measures <- measure where (each.name_of_agent = 'leisure[' + i + ']');
	    		list<float> list_of_NO2;
	    		list<float> list_of_O3;
	    		list<float> list_of_PM10;
	    		list<float> list_of_PM25;
	    		
	    		loop m over: list_of_measures{
	    			if (m.NO2_concentration > 0) {list_of_NO2 << m.NO2_concentration;}
	    			if (m.O3_concentration > 0) {list_of_O3 << m.O3_concentration;}
	    			if (m.PM10_concentration > 0) {list_of_PM10 << m.PM10_concentration;}
	    			if (m.PM25_concentration > 0) {list_of_PM25 << m.PM25_concentration;}
	    		}
	    		
	    		create leisure{
	    			name_of_agent <- 'leisure[' + i + ']';
	    			
	    			NO2_mean_exposition <- mean (list_of_NO2);
	    			O3_mean_exposition <- mean (list_of_O3);
	    			PM10_mean_exposition <- mean (list_of_PM10);
	    			PM25_mean_exposition <- mean (list_of_PM25);
	    			
	    			NO2_max <- max (list_of_NO2);
	    			O3_max <- max (list_of_O3);
	    			PM10_max <- max (list_of_PM10);
	    			PM25_max <- max (list_of_PM25);
	    			
	    		}	
	    	}
	    	ask leisure {
		    			save [name_of_agent, NO2_mean_exposition, NO2_max, O3_mean_exposition, O3_max, PM10_mean_exposition, PM10_max, PM25_mean_exposition, PM25_max] 
	    				to: "../results/Marseille/leisure/leisures_exposition.csv" type:"csv" rewrite: false;
		    	}
    	}
	}

}

species measure { // seulement besoin de la localisation de la mesure, etant donne que l'environnement est suppose stationnaire
	string name_of_agent;
	int ID;
	float NO2_concentration;
	float O3_concentration;
	float PM10_concentration;
	float PM25_concentration;
}

species people {
	string name_of_agent;
	
	float NO2_mean_exposition;
	float O3_mean_exposition;
	float PM10_mean_exposition;
	float PM25_mean_exposition; 
	
	float NO2_max;
	float O3_max;
	float PM10_max;
	float PM25_max;
}

species worker parent: people{

}

species student parent: people{
	
}

species leisure parent: people{
	
}

experiment bike_traffic type: gui {
	output{
    	display exposition {
    		chart "Exposition moyenne des étudiants" type: histogram background: #lightgrey{
    			data "0 - 40 um/m3" value: student count (each.NO2_mean_exposition < 40) ;
    			
    			data "40 - 80 um/m3" value: student count (each.NO2_mean_exposition >= 40 and each.NO2_mean_exposition < 80);
    			
    			data "80 - 120 um/m3" value: student count (each.NO2_mean_exposition >= 80 and each.NO2_mean_exposition < 120);

				data "120 - 160 um/m3" value: student count (each.NO2_mean_exposition >= 120 and each.NO2_mean_exposition < 160);
				
				data "160 - 200 um/m3" value: student count (each.NO2_mean_exposition >= 160 and each.NO2_mean_exposition < 200);
    		}

    	}
	}

}
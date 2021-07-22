/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/* 
 * This model generates travels' characteristics (duration and length for comparison with real world data
 * 
 */

global {
		
	file bound <- shape_file("../includes/Marseille/boundary_Marseille.shp");
		  	
	bool workers <- true;
    bool students <- false; // une seule population à la fois 
    bool leisures <- false;           	

    init{ 
    	
    	if workers{
	    	write("workers travels");
	    	loop i from: 0 to: 3600 {
	    		write(i);
	    		
	    		list<position> list_of_positions_aller <- [];
	    		create travel{
		    		create position from: shape_file("../results/Marseille/worker/aller_worker/positions/aller_worker[" + i + "].shp") with: [time_of_measure::(read("time"))]{
	
		    			list_of_positions_aller << self;
		    		}
		    		float milliseconds <- first(list_of_positions_aller).time_of_measure milliseconds_between last(list_of_positions_aller).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(list_of_positions_aller), last(list_of_positions_aller)));
		  			
		  			float dist;		
			    	create road from: shape_file("../results/Marseille/worker/aller_worker/trajets/aller_worker[" + i + "].shp"){
			    		dist <- dist + self.shape.perimeter;
			    	}
			    	
			    	distance <- int(dist);
		    	}
		    	
		    	list<position> list_of_positions_retour <- [];
	    		create travel{
		    		create position from: shape_file("../results/Marseille/worker/retour_worker/positions/retour_worker[" + i + "].shp") with: [time_of_measure::(read("time"))]{
	
		    			list_of_positions_retour << self;
		    		}
		    		float milliseconds <- first(list_of_positions_retour).time_of_measure milliseconds_between last(list_of_positions_retour).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(list_of_positions_retour), last(list_of_positions_retour)));
		  			
		  			float dist;		
			    	create road from: shape_file("../results/Marseille/worker/retour_worker/trajets/retour_worker[" + i + "].shp"){
			    		dist <- dist + self.shape.perimeter;
			    	}
			    	
			    	distance <- int(dist);
		    	}	
	    	}
	    	ask travel{
				save [distance_vol_oiseau, distance, duration] to: "../results/Marseille/worker/workers_travel_time.csv" type:"csv" rewrite: false;
			}
    	}
    	
    	if students{
	    	write("students travels");
	    	loop i from: 0 to: 2236 {
	    		write(i);
	    		
	    		list<position> list_of_positions_aller <- [];
	    		create travel{
		    		create position from: shape_file("../results/Marseille/student/aller_student/positions/aller_student[" + i + "].shp") with: [time_of_measure::(read("time"))]{
	
		    			list_of_positions_aller << self;
		    		}
		    		float milliseconds <- first(list_of_positions_aller).time_of_measure milliseconds_between last(list_of_positions_aller).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(list_of_positions_aller), last(list_of_positions_aller)));
		  			
		  			float dist;		
			    	create road from: shape_file("../results/Marseille/student/aller_student/trajets/aller_student[" + i + "].shp"){
			    		dist <- dist + self.shape.perimeter;
			    	}
			    	
			    	distance <- int(dist);
		    	}
		    	
		    	list<position> list_of_positions_retour <- [];
	    		create travel{
		    		create position from: shape_file("../results/Marseille/student/retour_student/positions/retour_student[" + i + "].shp") with: [time_of_measure::(read("time"))]{
	
		    			list_of_positions_retour << self;
		    		}
		    		float milliseconds <- first(list_of_positions_retour).time_of_measure milliseconds_between last(list_of_positions_retour).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(list_of_positions_retour), last(list_of_positions_retour)));
		  			
		  			float dist;		
			    	create road from: shape_file("../results/Marseille/student/aller_student/trajets/aller_student[" + i + "].shp"){
			    		dist <- dist + self.shape.perimeter;
			    	}
			    	
			    	distance <- int(dist);
		    	}	
	    	}
	    	ask travel{
				save [distance_vol_oiseau, distance, duration] to: "../results/Marseille/student/students_travel_time.csv" type:"csv" rewrite: false;
			}
    	}
    }
}

species travel {
	int duration; //temps de trajet en secondes
	
	int distance_vol_oiseau; //distance du trajet à vol d'oiseau en metres
	
	int distance;
}

species position {
	date time_of_measure;
}

species road  {
	string fclass;
	rgb color <- #blue;
}


experiment bike_traffic type: gui {
	output{

	}	
}
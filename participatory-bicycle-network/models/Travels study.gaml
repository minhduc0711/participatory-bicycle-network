/**
* Name: Deplacementdevelos
* Based on the internal empty template. 
* Author: nathancoisne
* Tags: 
*/


model Deplacementdevelos

/* 
 * This model generates travels' characteristics (duration and length for comparison with real world data)
 * 
 */

global {
		
	file bound <- shape_file("../includes/Marseille/boundary_Marseille.shp");
		  	
	bool workers <- true;
    bool students <- true;
    bool leisures <- true;           	

    init{ 
    	
    	create worker from: csv_file( "../results/Marseille/synthetic_population/worker.csv",true);
		create student from: csv_file( "../results/Marseille/synthetic_population/student.csv",true);
		create leisure from: csv_file( "../results/Marseille/synthetic_population/leisure.csv",true);
		
		
		int number_of_workers <- length(worker);
		int number_of_students <- length(student);
		int number_of_leisures <- length(leisure);
    	
    	if workers{
	    	write("workers travels");
	
	    	create position from: shape_file("../results/Marseille/worker/aller_worker/positions_aller_worker.shp") with: [time_of_measure::read("time"), name_agent::read("agent")];
	    	
	    	list<list<position>> list_of_positions_aller;
			
			loop i from: 0 to: number_of_workers - 1{
				list_of_positions_aller << [];
			}
			
			loop pos over: position{
				int number_of_agent <- int((((pos.name_agent split_with '[')[1]) split_with ']')[0]);
				list_of_positions_aller[number_of_agent] << pos;
			}
			
			loop trav over: list_of_positions_aller{
				
				create travel{
					name_agent <- trav[0].name_agent;
					
					float milliseconds <- first(trav).time_of_measure milliseconds_between last(trav).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(trav), last(trav)));
		  			
		  			save [name_agent, duration, distance_vol_oiseau] to: "../results/Marseille/worker/travel_study.csv" type: "csv" rewrite: false;
			    }
			}
			ask position{do die;}
			
			create position from: shape_file("../results/Marseille/worker/retour_worker/positions_retour_worker.shp") with: [time_of_measure::read("time"), name_agent::read("agent")];
	    	
	    	list<list<position>> list_of_positions_retour;
			
			loop i from: 0 to: number_of_workers - 1{
				list_of_positions_retour << [];
			}
			
			loop pos over: position{
				int number_of_agent <- int((((pos.name_agent split_with '[')[1]) split_with ']')[0]);
				list_of_positions_retour[number_of_agent] << pos;
			}
			
			loop trav over: list_of_positions_retour{
				
				create travel{
					name_agent <- trav[0].name_agent;
					
					float milliseconds <- first(trav).time_of_measure milliseconds_between last(trav).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(trav), last(trav)));
		  			
		  			save [name_agent, duration, distance_vol_oiseau] to: "../results/Marseille/worker/travel_study.csv" type: "csv" rewrite: false;
			    }
			}
			ask position{do die;}
    	}
    	
    	if students{
	    	write("students travels");
	
	    	create position from: shape_file("../results/Marseille/student/aller_student/positions_aller_student.shp") with: [time_of_measure::read("time"), name_agent::read("agent")];
	    	
	    	list<list<position>> list_of_positions_aller;
			
			loop i from: 0 to: number_of_students - 1{
				list_of_positions_aller << [];
			}
			
			loop pos over: position{
				int number_of_agent <- int((((pos.name_agent split_with '[')[1]) split_with ']')[0]);
				list_of_positions_aller[number_of_agent] << pos;
			}
			
			loop trav over: list_of_positions_aller{
				
				create travel{
					name_agent <- trav[0].name_agent;
					
					float milliseconds <- first(trav).time_of_measure milliseconds_between last(trav).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(trav), last(trav)));
		  			
		  			save [name_agent, duration, distance_vol_oiseau] to: "../results/Marseille/student/travel_study.csv" type: "csv" rewrite: false;
			    }
			}
			ask position{do die;}
			
			create position from: shape_file("../results/Marseille/student/retour_student/positions_retour_student.shp") with: [time_of_measure::read("time"), name_agent::read("agent")];
	    	
	    	list<list<position>> list_of_positions_retour;
			
			loop i from: 0 to: number_of_students - 1{
				list_of_positions_retour << [];
			}
			
			loop pos over: position{
				int number_of_agent <- int((((pos.name_agent split_with '[')[1]) split_with ']')[0]);
				list_of_positions_retour[number_of_agent] << pos;
			}
			
			loop trav over: list_of_positions_retour{
				
				create travel{
					name_agent <- trav[0].name_agent;
					
					float milliseconds <- first(trav).time_of_measure milliseconds_between last(trav).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(trav), last(trav)));
		  			
		  			save [name_agent, duration, distance_vol_oiseau] to: "../results/Marseille/student/travel_study.csv" type: "csv" rewrite: false;
			    }
			}
			ask position{do die;}
    	}
    
    	if leisures{
	    	write("leisures travels");
	
	    	create position from: shape_file("../results/Marseille/leisure/aller_leisure/positions_aller_leisure.shp") with: [time_of_measure::read("time"), name_agent::read("agent")];
	    	
	    	list<list<position>> list_of_positions_aller;
			
			loop i from: 0 to: number_of_leisures - 1{
				list_of_positions_aller << [];
			}
			
			loop pos over: position{
				int number_of_agent <- int((((pos.name_agent split_with '[')[1]) split_with ']')[0]);
				list_of_positions_aller[number_of_agent] << pos;
			}
			
			loop trav over: list_of_positions_aller{
				
				create travel{
					name_agent <- trav[0].name_agent;
					
					float milliseconds <- first(trav).time_of_measure milliseconds_between last(trav).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(trav), last(trav)));
		  			
		  			save [name_agent, duration, distance_vol_oiseau] to: "../results/Marseille/leisure/travel_study.csv" type: "csv" rewrite: false;
			    }
			}
			ask position{do die;}
			
			create position from: shape_file("../results/Marseille/leisure/retour_leisure/positions_retour_leisure.shp") with: [time_of_measure::read("time"), name_agent::read("agent")];
	    	
	    	list<list<position>> list_of_positions_retour;
			
			loop i from: 0 to: number_of_leisures - 1{
				list_of_positions_retour << [];
			}
			
			loop pos over: position{
				int number_of_agent <- int((((pos.name_agent split_with '[')[1]) split_with ']')[0]);
				list_of_positions_retour[number_of_agent] << pos;
			}
			
			loop trav over: list_of_positions_retour{
				
				create travel{
					name_agent <- trav[0].name_agent;
					
					float milliseconds <- first(trav).time_of_measure milliseconds_between last(trav).time_of_measure;
		    		
		    		duration <- int(milliseconds / 1000);
		  			
		  			distance_vol_oiseau <- int(distance_to(first(trav), last(trav)));
		  			
		  			save [name_agent, duration, distance_vol_oiseau] to: "../results/Marseille/leisure/travel_study.csv" type: "csv" rewrite: false;
			    }
			}
			ask position{do die;}
    	}
    }
}

species travel {
	string name_agent;
	int duration; //temps de trajet en secondes
	
	int distance_vol_oiseau; //distance du trajet à vol d'oiseau en metres
}

species position {
	date time_of_measure;
	string name_agent;
	int number_agent;
}

species road  {
	string fclass;
	rgb color <- #blue;
}

species people skills: [moving] {
	int ID;
}

species worker parent: people {
}

species student parent: people{
}

species leisure parent: people{
}

experiment time_of_travel type: gui {

}
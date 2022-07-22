/**
* Name: NewModel
* Based on the internal empty template. 
* Author: minhduc0711
* Tags: 
*/


model NewModel

/* Insert your model definition here */

global {
	matrix my_data;
	init {
		string path_grid <- 
			'../includes/Marseille/pollution_model/raster_dep13_NO2_2021052701_2021052701.tif';
		my_data <- grid_file(path_grid) as_matrix({624, 725});
		write my_data;
	}
}

experiment name type: gui {

	
	// Define parameters here if necessary
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
	// Define inspectors, browsers and displays here
	
	// inspect one_or_several_agents;
	//
	// display "My display" { 
	//		species one_species;
	//		species another_species;
	// 		grid a_grid;
	// 		...
	// }

	}
}
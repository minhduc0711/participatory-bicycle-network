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

	init{

		file measures_csv_worker <- csv_file("../results/Marseille/worker/measures_worker.csv",true);
		file measures_csv_student <- csv_file("../results/Marseille/student/measures_student.csv",true);
		file measures_csv_leisure <- csv_file("../results/Marseille/leisure/measures_leisure.csv",true);

		create measure from: measures_csv_worker;

		list<float> list_of_NO2_worker;
		list<float> list_of_O3_worker;
		list<float> list_of_PM10_worker;
		list<float> list_of_PM25_worker;

		loop m over: measure{
			if (m.NO2_concentration > 0) {list_of_NO2_worker << m.NO2_concentration;}
			if (m.O3_concentration > 0) {list_of_O3_worker << m.O3_concentration;}
			if (m.PM10_concentration > 0) {list_of_PM10_worker << m.PM10_concentration;}
			if (m.PM25_concentration > 0) {list_of_PM25_worker << m.PM25_concentration;}
		}

		create worker{

			NO2_mean_exposition <- mean (list_of_NO2_worker);
			O3_mean_exposition <- mean (list_of_O3_worker);
			PM10_mean_exposition <- mean (list_of_PM10_worker);
			PM25_mean_exposition <- mean (list_of_PM25_worker);

		}

		ask measure{do die;}

		create measure from: measures_csv_student;

		list<float> list_of_NO2_student;
		list<float> list_of_O3_student;
		list<float> list_of_PM10_student;
		list<float> list_of_PM25_student;

		loop m over: measure{
			if (m.NO2_concentration > 0) {list_of_NO2_student << m.NO2_concentration;}
			if (m.O3_concentration > 0) {list_of_O3_student << m.O3_concentration;}
			if (m.PM10_concentration > 0) {list_of_PM10_student << m.PM10_concentration;}
			if (m.PM25_concentration > 0) {list_of_PM25_student << m.PM25_concentration;}
		}

		create student{

			NO2_mean_exposition <- mean (list_of_NO2_student);
			O3_mean_exposition <- mean (list_of_O3_student);
			PM10_mean_exposition <- mean (list_of_PM10_student);
			PM25_mean_exposition <- mean (list_of_PM25_student);

		}

		ask measure{do die;}

		create measure from: measures_csv_leisure;

		list<float> list_of_NO2_leisure;
		list<float> list_of_O3_leisure;
		list<float> list_of_PM10_leisure;
		list<float> list_of_PM25_leisure;

		loop m over: measure{
			if (m.NO2_concentration > 0) {list_of_NO2_leisure << m.NO2_concentration;}
			if (m.O3_concentration > 0) {list_of_O3_leisure << m.O3_concentration;}
			if (m.PM10_concentration > 0) {list_of_PM10_leisure << m.PM10_concentration;}
			if (m.PM25_concentration > 0) {list_of_PM25_leisure << m.PM25_concentration;}
		}

		create leisure{

			NO2_mean_exposition <- mean (list_of_NO2_leisure);
			O3_mean_exposition <- mean (list_of_O3_leisure);
			PM10_mean_exposition <- mean (list_of_PM10_leisure);
			PM25_mean_exposition <- mean (list_of_PM25_leisure);

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

experiment exposition type: gui {
	/*
	   output{
	   display exposition_stud {
	   chart "Exposition moyenne des étudiants" type: histogram background: #lightgrey{
	   data "0 - 40 um/m3" value: student count (each.NO2_mean_exposition < 40) ;

	   data "40 - 80 um/m3" value: student count (each.NO2_mean_exposition >= 40 and each.NO2_mean_exposition < 80);

	   data "80 - 120 um/m3" value: student count (each.NO2_mean_exposition >= 80 and each.NO2_mean_exposition < 120);

	   data "120 - 160 um/m3" value: student count (each.NO2_mean_exposition >= 120 and each.NO2_mean_exposition < 160);

	   data "160 - 200 um/m3" value: student count (each.NO2_mean_exposition >= 160 and each.NO2_mean_exposition < 200);
	   }

	   }
	   }

	   output{
	   display exposition_work {
	   chart "Exposition moyenne des travailleurs" type: histogram background: #lightgrey{
	   data "0 - 40 um/m3" value: worker count (each.NO2_mean_exposition < 40) ;

	   data "40 - 80 um/m3" value: worker count (each.NO2_mean_exposition >= 40 and each.NO2_mean_exposition < 80);

	   data "80 - 120 um/m3" value: worker count (each.NO2_mean_exposition >= 80 and each.NO2_mean_exposition < 120);

	   data "120 - 160 um/m3" value: worker count (each.NO2_mean_exposition >= 120 and each.NO2_mean_exposition < 160);

	   data "160 - 200 um/m3" value: worker count (each.NO2_mean_exposition >= 160 and each.NO2_mean_exposition < 200);
	   }

	   }
	   }

	   output{
	   display exposition_leisure {
	   chart "Exposition moyenne des déplacements loisir" type: histogram background: #lightgrey{
	   data "0 - 40 um/m3" value: leisure count (each.NO2_mean_exposition < 40) ;

	   data "40 - 80 um/m3" value: leisure count (each.NO2_mean_exposition >= 40 and each.NO2_mean_exposition < 80);

	   data "80 - 120 um/m3" value: leisure count (each.NO2_mean_exposition >= 80 and each.NO2_mean_exposition < 120);

	   data "120 - 160 um/m3" value: leisure count (each.NO2_mean_exposition >= 120 and each.NO2_mean_exposition < 160);

	   data "160 - 200 um/m3" value: leisure count (each.NO2_mean_exposition >= 160 and each.NO2_mean_exposition < 200);
	   }

	   }
	   }
	 *
	 */

	output{
		display exposition_population {
			chart "Exposition moyenne des populations en NO2" type: histogram background: #lightgrey position: {0.0, 0.0} size: {0.5, 0.5}{
				data "worker" value: worker[0].NO2_mean_exposition;
				data "student" value: student[0].NO2_mean_exposition;
				data "leisure" value: leisure[0].NO2_mean_exposition;
			}

			chart "Exposition moyenne des populations en O3" type: histogram background: #lightgrey position: {0.0, 0.5} size: {0.5, 0.5}{
				data "worker" value: worker[0].O3_mean_exposition;
				data "student" value: student[0].O3_mean_exposition;
				data "leisure" value: leisure[0].O3_mean_exposition;
			}

			chart "Exposition moyenne des populations en PM10" type: histogram background: #lightgrey position: {0.5, 0.0} size: {0.5, 0.5}{
				data "worker" value: worker[0].PM10_mean_exposition;
				data "student" value: student[0].PM10_mean_exposition;
				data "leisure" value: leisure[0].PM10_mean_exposition;
			}

			chart "Exposition moyenne des populations en PM25" type: histogram background: #lightgrey position: {0.5, 0.5} size: {0.5, 0.5}{
				data "worker" value: worker[0].PM25_mean_exposition;
				data "student" value: student[0].PM25_mean_exposition;
				data "leisure" value: leisure[0].PM25_mean_exposition;
			}

		}
	}


}

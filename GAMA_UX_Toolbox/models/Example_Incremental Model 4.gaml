/**
* Name: Movement on Graph
* Author: GAMA team
* Description: 4th part of the tutorial : Incremental Model
* Tags: tutorial, chart, graph, gis
*/
 
model model4 
 
global {
	int nb_people <- 100;
    float agent_speed <- 5.0 #km/#h;			
	float step <- 1 #minutes;
	file roads_shapefile <- file("../includes/GIS/road.shp");
	file buildings_shapefile <- file("../includes/GIS/building.shp");
	geometry shape <- envelope(roads_shapefile);
	graph road_network;
	float staying_coeff update: 10.0 ^ (1 + min([abs(current_date.hour - 9), abs(current_date.hour - 12), abs(current_date.hour - 18)]));

	image_file play <- image_file("../includes/images/play.png");
	image_file stop <- image_file("../includes/images/stop.png");
	
	// [User Pause and Resume] adding a toggle for mouse control toggle
	action toggle {
		if paused {
			do resume;
		} else {
			do pause;
		}

	}
	
	
	init {
		// [User Pause and Resume] create the toggle
		create sign;
		create road from: roads_shapefile;
		road_network <- as_edge_graph(road);
		create building from: buildings_shapefile; 
		create people number:nb_people {
			speed <- agent_speed;
			location <- any_location_in(one_of(building));
		}

	}

}

// [User Pause and Resume] create the species for button
species sign skills: [moving] {
	image_file icon <- stop;
//	point location <- centroid(world);
	point location <- {100, 100};


	aspect default {
		draw (world.paused ? play : stop) size: {100, 100};
	}

	}

species people skills:[moving]{		
	bool is_infected <- false;
	point target;
	int staying_counter;
	
	reflex staying when: target = nil {
		staying_counter <- staying_counter + 1;
		if flip(staying_counter / staying_coeff) {
			target <- any_location_in (one_of(building));
		}
	}
		
	reflex move when: target != nil{
		do goto target:target on: road_network;
		if (location = target) {
			target <- nil;
			staying_counter <- 0;
		} 
	}

	aspect default{
		draw circle(5) color: #red;
	}
}

species road {
	aspect default {
		draw shape color: #black;
	}
}

species building {
	aspect default {
		draw shape color: #gray border: #black;
	}
}

experiment main_experiment type:gui{
	output {
		display map {
			species road ;
			species building ;
			species people ;	
			// [User Pause and Resume] display the sign and assign an event
			species sign;
			event #mouse_down {
				if ((#user_location distance_to sign[0]) < 50) {
					ask world {
						do toggle;
					}
				}
			}
		}
	}
}
/**
* Name: GAMA UX Toolbox
* Author: Jin
* Description: based on Tutorials/Incremental Model, Visualization adn User Interaction/Moving Agents, User Pause and Resume
* Tags: 
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

	// [User Pause and Resume] load toggle image files
	image_file play <- image_file("../includes/images/play.png");
	image_file stop <- image_file("../includes/images/stop.png");
	
	// [Moving Agents] initialize variables for stroing moved agents
	list<being> moved_agents ;
	geometry zone <- circle(100);
	bool can_drop;
	
	// [User Pause and Resume] adding a toggle for mouse control toggle
	action toggle {
		if paused {
			do resume;
		} else {
			do pause;
		}

	}
	
	// [Moving Agents] define actions
	
	action kill 
	{
		ask moved_agents
		{
			do die;
		}

		moved_agents <- [];
	}

	action duplicate 
	{
		geometry available_space <- (zone at_location #user_location) - (union(moved_agents) + 10);
		create being number: length(moved_agents) with: (location: any_location_in(available_space));
	}

	action click 
	{
		if (empty(moved_agents))
		{
			moved_agents <- being inside (zone at_location #user_location);
			ask moved_agents
			{
				difference <- #user_location - location;
				color <- # olive;
			}

		} else if (can_drop)
		{
			ask moved_agents
			{
				color <- # burlywood;
			}

			moved_agents <- [];
		}

	}

	action move 
	{
		can_drop <- true;
		list<being> other_agents <- (being inside (zone at_location #user_location)) - moved_agents;
		geometry occupied <- geometry(other_agents);
		ask moved_agents
		{
			location <- #user_location - difference;
			if (occupied intersects self)
			{
				color <- # red;
				can_drop <- false;
			} else
			{
				color <- # olive;
			}

		}

	}
	
	
	init {
		// [User Pause and Resume] create the toggle
		create sign;
		
		// [Moving Agents] create 100 beings
		create being number: 100;
		
		// draw the environment
		create road from: roads_shapefile;
		road_network <- as_edge_graph(road);
		create building from: buildings_shapefile; 
		
		// draw 2d people
		create people number:nb_people {
			speed <- agent_speed;
			location <- any_location_in(one_of(building));
		}

	}

}

// [User Pause and Resume] define the species

species being skills: [moving]
{
	geometry shape <- square(10);
	point difference <- { 0, 0 };
	rgb color <- # blue;
	reflex r
	{
//		if (!(moved_agents contains self))
//		{
//			do wander amplitude: 30.0;
//		}

	}

	aspect default
	{
		draw shape color: color at: location + {1,0,1};
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
	// [Moving Agents] define fonts and color
	font regular <- font("Helvetica", 14, # bold);
	rgb c1 <- rgb(#darkseagreen, 120);
	rgb c2 <- rgb(#firebrick, 120);
			
	output {
		display map type: 3d {

			
			
			// [Moving Agents] display target set
			graphics "Full target" 
			{
				int size <- length(moved_agents);
				if (size > 0)
				{
					draw zone at: #user_location wireframe: false border: false color: (can_drop ? c1 : c2);
					draw string(size) at: #user_location + { -30, -30 } font: regular color: # white;
					draw "'r': remove" at: #user_location + { -30, 0 } font: regular color: # white;
					draw "'c': copy" at: #user_location + { -30, 30 } font: regular color: # white;
				} else {
					draw zone at: #user_location wireframe: false border: false color: #wheat;
				}
			}
			
			// [Moving Agents] add being to the display
			species being;
			event #mouse_move action: move;
			event #mouse_up action: click;
			event 'r' action: kill;
			event 'c' action: duplicate;
			
			
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
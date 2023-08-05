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



	// [User Pause and Resume Start] load toggle image files
	image_file play <- image_file("../includes/images/play.png");
	image_file stop <- image_file("../includes/images/stop.png");
	
	image_file add <- image_file("../includes/images/add.jpg");
	
	
	// [User Pause and Resume] adding a toggle for mouse control toggle
	action toggle {
		if paused {
			do resume;
		} else {
			do pause;
		}

	}
	// [User Pause and Resume Ends]
	
	// [Moving Agents Start] initialize variables for stroing moved agents
	list<being> moved_agents ;
	geometry zone <- circle(100);
	bool can_drop;
	
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
				color <- # pink;
			}

		} else if (can_drop)
		{
			ask moved_agents
			{
				color <- # purple;
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
	action add_being 
	{
    create being number: 1 { 
      location <- {10,10};       
    } 	}
	// [Moving Agents Ends] define actions ends
	
	//[Tools Panel] current button action type
	int action_type <- -1;	
	//[Tools Panel] images used for the buttons
	list<file> images <- [
		file("../includes/images/building1.png"),
		file("../includes/images/building2.png"),
		file("../includes/images/building3.png"),
		file("../includes/images/eraser.png")
	]; 
	// [Tools Panel] button_activate action
	action button_activate_act {
		button selected_but <- first(button overlapping (circle(1) at_location #user_location));
		if(selected_but != nil) {
			ask selected_but {
				ask button {bord_col<-#black;}
				if (action_type != id) {
					action_type<-id;
					bord_col<-#red;
					write "changing action_type to:"+ id ;
				} else {
					action_type<- -1;
					write "changing action_type to:"+ id ;
				}
			}
		}
	}
	// [Tools Panel] modified from cell_magagement
	action mode_management {
				switch action_type {
					match 0 {color <- #red; write "Action Type:"+action_type;}
					match 1 {color <- #white; write "Action Type:"+action_type;}
					match 2 {color <- #yellow; write "Action Type:"+action_type;}
					match 3 {color <- #black; write "Action Type:"+action_type;}
				}
				
			}

	
	init {
		// [User Pause and Resume] create the toggle
		create pause_resume_button;
		create add_species_button;
		
		
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
	reflex debug {
		// write color;
	}
	aspect default
	{
		draw shape color: color at: location + {1,0,1};
	}

}

// [User Pause and Resume] create the species for button
species pause_resume_button skills: [moving] {
	image_file icon <- stop;
//	point location <- centroid(world);
	point location <- {600, 50};
	aspect default {
		draw (world.paused ? play : stop) size: {100, 100};
		}
	reflex debug {
		// write self.location;
		write "pause_resume_button";
		
		}
	}
	
// [User Pause and Resume] create the species for button
species add_species_button {
	image_file icon <- add;
//	point location <- centroid(world);
	point location <- {750, 50};
	aspect default {
		draw (add) size: {100, 100};
		}
	reflex debug {
		write "clicked add_species_button";
		}
	}
	
// [Tools Panel] define buttons in a grid // TODO: CAN Make it a father species and inherit child buttons?
// https://gama-platform.org/wiki/GridSpecies
//grid button width:4 height:1
grid button width:6 height:1
 
{
	int id <- int(self);
	rgb bord_col<-#green;
	aspect normal {
		draw rectangle(100,100).contour + (5) color: bord_col;
		draw image_file(images[id]) size:{100,100} ;
	}
}



// [Base Model Start]
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
// [Base Model End]


experiment main_experiment type:gui{
	// [Moving Agents] define fonts and color
	font regular <- font("Helvetica", 14, # bold);
	rgb c1 <- rgb(#darkseagreen, 120);
	rgb c2 <- rgb(#firebrick, 120);
			
	output {
		display map type: opengl {
			// [Moving Agents] display target set
			graphics "Full target" 
			{
				int size <- length(moved_agents);
				if (size > 0)
				{
					draw zone at: #user_location wireframe: false border: false color: (can_drop ? c1 : c2);
					draw string(size) at: #user_location + { -30, -30 } font: regular color: # black;
					draw "'r': remove" at: #user_location + { -30, 0 } font: regular color: # black;
					draw "'c': copy" at: #user_location + { -30, 30 } font: regular color: # black;
					draw "'a': add" at: #user_location + { -30, 60 } font: regular color: # black;
					
				} else {
					draw zone at: #user_location wireframe: false border: #black color: #wheat;
				}
			}
			
			// [Moving Agents] add being to the display
			species being;
			event #mouse_move action: move;
			event #mouse_up action: click;
			event 'r' action: kill;
			event 'c' action: duplicate;
			event 'a' action: add_being;
			
			
			species road ;
			species building ;
			species people ;	
			

		}
		
		display Toolsets background:#white name:"Tools panel" type: 2d 	{
			
			// [Tools Panel] display the action buttons
			species button aspect:normal ;
			event #mouse_down action:button_activate_act;   
			
			// [User Pause and Resume] display the sign and assign an event
			species pause_resume_button;
			event #mouse_down {
				if ((#user_location distance_to pause_resume_button[0]) < 50) {
					ask world {
						do toggle;
					}
				}			
			} 
			
			species add_species_button;
			event #mouse_down {
				write "mouse_down add_species_button";
				}	
		
			
		}
	}
}
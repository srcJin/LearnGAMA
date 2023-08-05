/***
* Name: ToolsPanel
* Author: Patrick Taillandier
* Description: Model which shows how to use the event layer to define a tools panel. In this model, the modelers can select one of 
* the 4 tools (icon - building1, building2, building3 and eraser) to carry out action on the map display. More precisely, when one tool 
* is selected (red rectangle), the tool change the color of the selected cells and display the corresponding icon (in map display).
* Tags: gui, user event, tool panel
***/

model ToolsPanel

global {

//		init{
//			create button number: 1 with: (location:{0,0});
//		}

	//current action type
	int action_type <- -1;	
	//images used for the buttons
	list<file> images <- [
		file("../includes/images/building1.png"),
		file("../includes/images/building2.png"),
		file("../includes/images/building3.png"),
		file("../includes/images/eraser.png")
	]; 
	
	
	action activate_act {
		button selected_but <- first(button overlapping (circle(10.0) at_location #user_location));
		if(selected_but != nil) {
			ask selected_but {
				ask button {bord_col<-#black;}
				if (action_type != id) {
					action_type<-id;
					bord_col<-#red;
				} else {
					action_type<- -1;
				}
				
			}
		}
	}
	
	action cell_management {
		cell selected_cell <- first(cell overlapping (circle(1.0) at_location #user_location));
		if(selected_cell != nil) {
			ask selected_cell {
				building <- action_type;
				switch action_type {
					match 0 {color <- #red;}
					match 1 {color <- #blue;}
					match 2 {color <- #yellow;}
					match 3 {color <- #black; building <- -1;}
				}
			}
		}
	}

}

grid cell width: 10 height: 10 {
	rgb color <- #black ;
	int building <- -1;
	aspect default {
		if (building >= 0) {
			draw image_file(images[building]) size:{shape.width * 0.5,shape.height * 0.5} ;
		}
		 
	}
}

// https://gama-platform.org/wiki/GridSpecies
grid button width: 4 height: 1
{
	// point location <- { 0, 0 };
	int id <- int(self);
	rgb bord_col<-#green;
	
	aspect normal {
		draw circle(5) color:#blue border: bord_col at: { 20* id + 20 , -20 };
		draw image_file(images[id]) size:{5,5} at: { 20* id +20 , -20 };
	}
}


experiment ToolsPanel type: gui {
	output {
		display map type: opengl  {
			grid cell border: #white;
			species cell;
			event #mouse_down action:cell_management;
			
			species button aspect:normal;
			event #mouse_down action:activate_act;    
		}
	}
}

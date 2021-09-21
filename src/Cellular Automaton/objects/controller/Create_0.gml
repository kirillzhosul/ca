/// @description Initialisation.
// @author Kirill Zhosul (@kirillzhosul)


#region Macros.

#region Rules.

// Rules.
__RULES = ds_map_create();

#region Conway`s Game of Life rules.

// Rules.
__RULES[RULE_TYPE.GAME_OF_LIFE] = ds_map_create();

// Default state.
__RULES[RULE_TYPE.GAME_OF_LIFE][? "DEFAULT_STATE"] = function(){ 
	return CELL_STATE.GOF_DIED;
};

// Color rule.
__RULES[RULE_TYPE.GAME_OF_LIFE][? "DRAW_COLOR"]    = function(_state){ 
	return _state == CELL_STATE.GOF_DIED ? c_gray : c_ltgray 
};

// Update rule.
__RULES[RULE_TYPE.GAME_OF_LIFE][? "UPDATE_RULE"]   = function(_neighbours_count, _state){ 
	return (_neighbours_count < 2 || _neighbours_count > 3) ? CELL_STATE.GOF_DIED : ((_state == CELL_STATE.GOF_DIED && _neighbours_count == 3) ? CELL_STATE.GOF_ALIVE : _state); 
};

// Click rule.
__RULES[RULE_TYPE.GAME_OF_LIFE][? "MOUSE_CLICK"]   = function(_state){ 
	return mouse_check_button(mb_left) ? CELL_STATE.GOF_ALIVE : (mouse_check_button(mb_right) ? CELL_STATE.GOF_DIED : _state);
};

// Neighbours rule.
__RULES[RULE_TYPE.GAME_OF_LIFE][? "NEIGHBOURS_STATE"] = CELL_STATE.GOF_ALIVE;

#endregion

#region Wireworld rules.

// Rules.
__RULES[RULE_TYPE.WIREWORLD] = ds_map_create();

// Default state.
__RULES[RULE_TYPE.WIREWORLD][? "DEFAULT_STATE"] = function(){ 
	return CELL_STATE.WW_EMPTY;
};

// Color rule.
__RULES[RULE_TYPE.WIREWORLD][? "DRAW_COLOR"]    = function(_state){ 
	return _state == CELL_STATE.WW_EMPTY ? c_dkgray : (_state == CELL_STATE.WW_ELECTRON_HEAD ? c_blue : (_state == CELL_STATE.WW_ELECTRON_TAIL ? c_red : (_state == CELL_STATE.WW_CONDUCTOR ? c_yellow : c_white)));
};

// Update rules.
__RULES[RULE_TYPE.WIREWORLD][? "UPDATE_RULE"]   = function(_neighbours_count, _state){ 
	// Heads, tails.
	
	switch(_state){
		case CELL_STATE.WW_EMPTY:
		break;
		case CELL_STATE.WW_ELECTRON_TAIL:
			_state = CELL_STATE.WW_CONDUCTOR
		break;
		case CELL_STATE.WW_ELECTRON_HEAD:
			_state = CELL_STATE.WW_ELECTRON_TAIL
		break;
		case CELL_STATE.WW_CONDUCTOR:
			if (_neighbours_count >= 1 and _neighbours_count <= 2){
				_state = CELL_STATE.WW_ELECTRON_HEAD;
			}
		break;
	}
	
	// Returning.
	return _state;
};

// Click rule.
__RULES[RULE_TYPE.WIREWORLD][? "MOUSE_CLICK"]   = function(_state){ 
	return mouse_check_button_pressed(mb_left) ? (_state == CELL_STATE.WW_EMPTY ? CELL_STATE.WW_CONDUCTOR : CELL_STATE.WW_EMPTY) : (mouse_check_button(mb_right) ? (CELL_STATE.WW_ELECTRON_HEAD) : _state);
};

// Neighbours rule.
__RULES[RULE_TYPE.WIREWORLD][? "NEIGHBOURS_STATE"] = CELL_STATE.WW_ELECTRON_HEAD;

#endregion

#endregion

// Current rule.
#macro RULE RULE_TYPE.GAME_OF_LIFE

// Size of one cell.
#macro CELL_SIZE 32

// World size.
#macro WORLD_W room_width / CELL_SIZE
#macro WORLD_H room_height / CELL_SIZE

// Bigger value - less update calls.
#macro UPDATE_WAIT_TIME room_speed / 2

#endregion

#region Enums.

// Cell states.
enum CELL_STATE{
	// Conway`s Game Of Life.
	GOF_DIED,
	GOF_ALIVE,
	
	// Wireworld.
	WW_EMPTY,
	WW_ELECTRON_HEAD,
	WW_ELECTRON_TAIL,
	WW_CONDUCTOR,
}

// Rule types.
enum RULE_TYPE{
	GAME_OF_LIFE,
	WIREWORLD,
}

#endregion

#region Structs.

function __cell() constructor{
	// Cell struct.
	
	// Default state.
	var _rule = controller.__rule_get("DEFAULT_STATE")
	self.state = _rule();
	
	self.draw = function (_x, _y) {
		// @function __cell.draw(_x, _y)
		// @description Function that draws cell.
		
		// Drawing outline.
		draw_set_color(c_black);
		draw_rectangle(_x, _y, _x + CELL_SIZE, _y + CELL_SIZE, true);
		
		// Setting draw color.
		var _rule = controller.__rule_get("DRAW_COLOR");
		draw_set_color(_rule(self.state));
		
		// Drawing cell.
		draw_rectangle(_x, _y, _x + CELL_SIZE, _y + CELL_SIZE, false);
	}
	
	self.update = function (_neighbours_count) {
		// @function __cell.update(_neighbours_count)
		// @description Function that updates cell.
		
		// Updating state.
		var _rule = controller.__rule_get("UPDATE_RULE");
		self.state = _rule(_neighbours_count, self.state);
	}
}

#endregion

#region Functions.

function __rule_get(_rule){
	// @function __rule_get(_rule)
	// @description Function that returns rule.
	
	// Returning.
	return __RULES[RULE][? _rule];
}

function __world_initialise(){
	// @function __world_initialise()
	// @description Function that initialises world.
	
	// Clearing variable.
	__world_cells = [];
	
	// Initialising.
	for (var _current_x = 0; _current_x < WORLD_W; _current_x++){
		// Iterating over x.
		
		for (var _current_y = 0; _current_y < WORLD_H; _current_y++){
			// Iterating over y.
	
			// Filling new cell.
			__world_cells[_current_x][_current_y] = new __cell();
		}
	}

}

function __world_draw(){
	// @function __world_draw()
	// @description Function that draws world.

	// Drawing.
	for (var _current_x = 0; _current_x < WORLD_W; _current_x++){
		// Iterating over x.
		
		for (var _current_y = 0; _current_y < WORLD_H; _current_y++){
			// Iterating over y.
	
			// Getting cell.
			var _cell = __world_cells[_current_x][_current_y];
			
			// Drawing cell.
			_cell.draw(CELL_SIZE * _current_x, CELL_SIZE * _current_y);
			
			if mouse_check_button(mb_left) or mouse_check_button(mb_right){
				// If clicked.
				
				if point_in_rectangle(mouse_x, mouse_y, CELL_SIZE * _current_x, CELL_SIZE * _current_y, CELL_SIZE * _current_x + CELL_SIZE, CELL_SIZE * _current_y + CELL_SIZE){
					// If hovered.
					
					// Changing state.
					var _rule = __rule_get("MOUSE_CLICK")
					_cell.state = _rule(_cell.state);
				}
			}
		}
	}
}

function __world_update(){
	// @function __world_update()
	// @description Function that updates world.
	
	// Updating update state.
	__update_state ++;
	
	// Passing if not time.
	if __update_state != UPDATE_WAIT_TIME return;
	
	// Nullificate update state.
	__update_state = 0;
	
	// Updating.
	for (var _current_y = 0; _current_y < WORLD_H; _current_y++){
		// Iterating over y.
			
		for (var _current_x = 0; _current_x < WORLD_W; _current_x++){
			// Iterating over x.
	
			// Getting cell.
			var _cell = __world_cells[_current_x][_current_y];
			
			// Counting heighbours.
			var _neighbours_count = __world_cell_count_neighbours(_current_x, _current_y);
			
			// Updating cell.
			_cell.update(_neighbours_count);
		}
	}
}

function __world_cell_count_neighbours(_cell_x, _cell_y){
	// @function __world_cell_count_heighbours(_cell_x, _cell_y)
	// @description Function that counts cell neighbours.
	
	// Counting.
	var _neighbours_count = 0;

	for (var _x = -1; _x < 2; _x++){
		// Iterating over x.
		for (var _y = -1; _y < 2; _y++){
			// Iterating over y
			
			// Passing if self.
			if _x == 0 and _y == 0 continue;
			
			// Getting check position.
			var _check_x = _cell_x + _x
			var _check_y = _cell_y + _y;
			
			// Checking bounds of world.
			if _check_x < 0 or _check_y < 0 continue;
			if _check_x >= WORLD_W or _check_y >= WORLD_H continue;
			
			// Adding.
			_neighbours_count += __world_cells[_check_x][_check_y].state == __rule_get("NEIGHBOURS_STATE");
		}
	}
	
	// Returning.
	return _neighbours_count;
}

#endregion

#region Entry point.

// Update state, if == UPDATE_WAIT, update will be called.
__update_state = 0;

// Initialise world.
__world_initialise();

#endregion
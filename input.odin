package main

import rl "vendor:raylib"

Input_Buffer :: struct {
	actions: [Input_Action]Buffered_Input,
}

Buffered_Input :: union {
	f32,
}

Input_Action :: enum {
	Jump,
}

update_buffer :: proc() {
	frametime := rl.GetFrameTime()

	for &buffered in input_buffer.actions {
		switch &v in buffered {
		case f32:
			v -= frametime
			if v <= 0 {
				buffered = nil
			}
		}
	}
}

buffer_action :: proc(action: Input_Action) {
	switch &v in input_buffer.actions[action] {
	case f32:
		v = 0.15
	case:
		input_buffer.actions[action] = 0.15
	}
}

consume_action :: proc(action: Input_Action) {
	input_buffer.actions[action] = nil
}

is_action_buffered :: proc(action: Input_Action) -> bool {
	_, action_pressed := input_buffer.actions[action].(f32)
	return action_pressed
}

input :: proc() {
	frametime := rl.GetFrameTime()
	update_buffer()
	// Tracking raw input in the input buffer
	if rl.IsKeyPressed(.SPACE) do buffer_action(.Jump)
	set_player_movement_delta()
}

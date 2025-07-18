package main

import rl "vendor:raylib"

set_player_movement_delta :: proc() {
	for &entity in entities {
		delta: f32
		if rl.IsKeyDown(.A) {
			delta -= 1
		}
		if rl.IsKeyDown(.D) {
			delta += 1
		}
		entity.x_delta = delta
		if delta != 0 {
			entity.facing = delta
		}
	}
}


player_jump :: proc() {
	for &entity in entities {
		if entity.tag == .Player {
			if is_action_buffered(.Jump) {
				#partial switch entity.state {
				case .Grounded:
					entity.velocity.y = -100
					consume_action(.Jump)
				}
			}
		}
	}
}

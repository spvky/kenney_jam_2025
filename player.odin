package main

import rl "vendor:raylib"

Static_Meter :: struct {
	charge: f32,
	max_charge: f32
}

draw_static_meter :: proc() {
	rl.DrawRectanglePro({x=10,y=20, width = 16, height=104},{0,0}, 0, rl.WHITE)
	rl.DrawRectanglePro({x=18,y=122, width = 12, height=100},{6,0}, 180, rl.BLUE)
	// rl.DrawRectangle(12,122, 12, -96, rl.BLUE)
}

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

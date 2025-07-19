package main

import "core:math"
import rl "vendor:raylib"

Static_Meter :: struct {
	charge:           f32,
	max_charge:       f32,
	displayed_charge: f32,
}

has_charge :: proc(amount: f32) -> bool {
	using static_meter

	return charge >= amount
}

add_charge :: proc(amount: f32) {
	using static_meter

	charge = clamp(charge + amount, 0, max_charge)
}

spend_charge :: proc(amount: f32) {
	using static_meter

	charge -= amount
}

handle_static_meter :: proc(frametime: f32) {
	using static_meter

	displayed_charge = math.lerp(displayed_charge, charge, frametime * 5)
}

draw_static_meter :: proc() {
	using static_meter

	frametime := rl.GetFrameTime()
	handle_static_meter(frametime)
	rl.DrawRectanglePro({x = 10, y = 20, width = 16, height = 104}, {0, 0}, 0, rl.WHITE)
	rl.DrawRectanglePro({x = 18, y = 122, width = 12, height = charge}, {6, 0}, 180, rl.BLUE)
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
				case .Airborne:
					if has_charge(20) {
						entity.velocity.y = -150
						consume_action(.Jump)
						spend_charge(20)
					}
				}
			}
		}
	}
}

package main

import "core:math"
import particles "particles"
import ripple "ripple"
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
						pos := get_relative_pos(entity.translation)
						pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}
						ripple.add(pos, .Teal)
						entity.velocity.y = -150
						consume_action(.Jump)
						spend_charge(20)
					}
				}
			}
		}
	}
}

player_dash :: proc() {
	for &entity in entities {
		if entity.tag == .Player {
			if entity.state == .Grounded && is_action_buffered(.Dash) && has_charge(30) {
				entity.speed.max = 150
				entity.speed.acceleration = 450
				consume_action(.Dash)
				spend_charge(30)
			}
		}
	}
}

check_kill_player :: proc() {
	level := gamestate.current_level
	player := &entities[Entity_Tag.Player]
	pos := get_relative_pos(player.translation)
	pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}


	if check_killzone(level, player.translation) || player.translation.y > level.position.y + f32(level.height) {
		ripple.add(pos, .Red)

		player.translation = get_spawn_point(level)
		player.velocity = {0, 0}
		player.snapshot = player.translation

		center_position := player.translation
		particles.add({position = center_position, lifetime = 1, radius = 0.5, kind = .Ripple})
		pos := get_relative_pos(center_position)
		pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}
		ripple.add(pos, .Teal, 80)

	}
}

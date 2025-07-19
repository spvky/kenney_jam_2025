package main

import "core:math"
import "particles"
import "ripple"
import rl "vendor:raylib"

Player :: struct {
	state:            Player_State,
	radius:           f32,
	animation_player: Animation_Player,
	translation:      Vec2,
	velocity:         Vec2,
	snapshot:         Vec2,
	x_delta:          f32,
	speed:            Speed,
	facing:           f32,
}


Player_State :: enum {
	Grounded,
	Airborne,
}

Animation_Player :: struct {
	frame_length:      f32,
	current_time:      f32,
	current_frame:     int,
	current_animation: Animation,
	texture:           ^rl.Texture2D,
}

Animation :: union #no_nil {
	SingleFrame,
	MultiFrame,
}

SingleFrame :: struct {
	idx: int,
}

MultiFrame :: struct {
	start: int,
	end:   int,
}

Animation_Tag :: enum {
	Idle,
	Run,
	Jump,
}

Speed :: struct {
	base_max:          f32,
	max:               f32,
	base_acceleration: f32,
	acceleration:      f32,
	deceleration:      f32,
}


Static_Meter :: struct {
	charge:           f32,
	max_charge:       f32,
	displayed_charge: f32,
}

make_player :: proc(spawn_point: rl.Vector2) -> Player {
	return Player {
		state = .Grounded,
		radius = 6,
		animation_player = Animation_Player {
			frame_length = 0.25,
			texture = &player_texture,
			current_animation = player_animations[.Idle],
		},
		facing = 1,
		translation = spawn_point,
		speed = Speed{base_max = 50, max = 50, base_acceleration = 275, acceleration = 275, deceleration = 0.025},
	}
}

load_player_texture :: proc() -> rl.Texture2D {
	player_tex := rl.LoadTexture("assets/textures/player.png")
	return player_tex
}

unload_player_texture :: proc() {
	rl.UnloadTexture(player_texture)
}


import "core:fmt"

animate_player :: proc() {
	frametime := rl.GetFrameTime()
	using player.animation_player
	current_time += frametime
	switch ca in current_animation {
	case SingleFrame:
	// If it's a single frame animation do nothing
	case MultiFrame:
		if current_time > frame_length {
			current_time = 0
			new_frame := current_frame + 1
			if new_frame > ca.end {
				new_frame = ca.start
			}
			player.animation_player.current_frame = new_frame
		}
	}
}

render_player :: proc() {
	texture := player.animation_player.texture^
	texture_rec := rl.Rectangle {
		x      = f32(player.animation_player.current_frame) * 16,
		y      = 0,
		width  = 16 * player.facing,
		height = 16,
	}
	offset := Vec2{-8, -8}
	rl.DrawTextureRec(texture, texture_rec, get_relative_pos(player.snapshot + offset), rl.WHITE)
}

has_charge :: proc(amount: f32) -> bool {
	using static_meter

	return charge >= amount
}

add_charge :: proc(amount: f32) {
	using static_meter

	new_charge := clamp(charge + amount, 0, max_charge)
	if charge != 100 && new_charge == 100 {
		ripple.add({0.5, 0.5}, .Teal)
	}
	charge = new_charge
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
	delta: f32
	if rl.IsKeyDown(.A) {
		delta -= 1
	}
	if rl.IsKeyDown(.D) {
		delta += 1
	}
	player.x_delta = delta
	if delta != 0 {
		player.facing = delta
	}
}

start_of_animation :: proc(animation: Animation) -> int {
	switch a in animation {
	case SingleFrame:
		return a.idx
	case MultiFrame:
		return a.start
	}
	return 0
}

set_player_animation :: proc() {
	switch player.state {
	case .Airborne:
		if player.animation_player.current_animation != player_animations[.Jump] {
			player.animation_player.current_animation = player_animations[.Jump]
			player.animation_player.current_frame = start_of_animation(player_animations[.Jump])
		}
	case .Grounded:
		if math.abs(player.velocity.x) < 0.5 {
			if player.animation_player.current_animation != player_animations[.Idle] {
				player.animation_player.current_animation = player_animations[.Idle]
				player.animation_player.current_frame = start_of_animation(player_animations[.Idle])
			}
		} else {
			if player.animation_player.current_animation != player_animations[.Run] {
				player.animation_player.current_animation = player_animations[.Run]
				player.animation_player.current_frame = start_of_animation(player_animations[.Run])
			}
		}
	}
}

player_jump :: proc() {
	if is_action_buffered(.Jump) {
		#partial switch player.state {
		case .Grounded:
			player.velocity.y = -125
			consume_action(.Jump)
		case .Airborne:
			if has_charge(20) {
				pos := get_relative_pos(player.translation)
				pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}
				ripple.add(pos, .Teal)
				player.velocity.y = -175
				consume_action(.Jump)
				spend_charge(20)
			}
		}
	}
}

player_dash :: proc() {
	if player.state == .Grounded && is_action_buffered(.Dash) && has_charge(30) {
		player.speed.max = 150
		player.speed.acceleration = 450
		pos := get_relative_pos(player.translation)
		pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}
		ripple.add(pos, .Teal)
		consume_action(.Dash)
		spend_charge(30)
	}
}

check_kill_player :: proc() {
	level := gamestate.current_level
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

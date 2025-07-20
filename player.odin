package main

import "core:math"
import "particles"
import "ripple"
import rl "vendor:raylib"


////////////// Physics values ///////////////////

// How far can the player jump horizontally (in pixels)
MAX_JUMP_DISTANCE: f32 : TILE_SIZE * 3
// How long to reach jump peak (in seconds)
TIME_TO_PEAK: f32 : 0.35
// How long to reach height we jumped from (in seconds)
TIME_TO_DESCENT: f32 : 0.2
// How many pixels high can we jump
JUMP_HEIGHT: f32 : TILE_SIZE * 2

max_speed := calculate_max_speed()
jump_speed := calulate_jump_speed()
rising_gravity := calculate_rising_gravity()
falling_gravity := calculate_falling_gravity()


calulate_jump_speed :: proc() -> f32 {
	return (-2 * JUMP_HEIGHT) / TIME_TO_PEAK
}

calculate_rising_gravity :: proc() -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_PEAK, 2)
}

calculate_falling_gravity :: proc() -> f32 {
	return (2 * JUMP_HEIGHT) / math.pow(TIME_TO_DESCENT, 2)
}

calculate_max_speed :: proc() -> f32 {
	return MAX_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT)
}

//////////////////////////////////////////////

Player :: struct {
	state:            Player_State,
	previous_state:   Player_State,
	radius:           f32,
	animation_player: Animation_Player,
	translation:      Vec2,
	velocity:         Vec2,
	snapshot:         Vec2,
	x_delta:          f32,
	coyote_time:      f32,
	speed:            Speed,
	facing:           f32,
	grounded_lockout: f32,
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
	max:          f32,
	acceleration: f32,
	deceleration: f32,
}


Static_Meter :: struct {
	charge:           f32,
	max_charge:       f32,
	displayed_charge: f32,
}


COST :: 25

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
		speed = Speed{max = max_speed, acceleration = 275, deceleration = 0.75},
	}
}

load_player_texture :: proc() -> rl.Texture2D {
	player_tex := rl.LoadTexture("assets/textures/player.png")
	return player_tex
}

unload_player_texture :: proc() {
	rl.UnloadTexture(player_texture)
}

animate_player :: proc(frametime: f32) {
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
	jump_sound_index := int(rl.GetTime() * 2) % 3

	if player.grounded_lockout > 0 {
		player.grounded_lockout -= TICK_RATE
		if player.grounded_lockout < 0 {
			player.grounded_lockout = 0
		}
	}
	if is_action_buffered(.Jump) {
		#partial switch player.state {
		case .Grounded:
			player.coyote_time = 0
			player.velocity.y = jump_speed
			consume_action(.Jump)
			player.grounded_lockout = 0.2
		case .Airborne:
			if player.coyote_time > 0 {
				player.coyote_time = 0
				player.velocity.y = jump_speed
				consume_action(.Jump)
			} else {
				if has_charge(COST) {
					pos := get_relative_pos(player.translation)
					pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}
					ripple.add(pos, .Teal)
					particles.add({position = player.translation, lifetime = 0.4, radius = 0.5, kind = .Ripple})
					player.velocity.y = jump_speed
					consume_action(.Jump)
					spend_charge(COST)
				} else {return}
			}
		}
		play_sound(Sound(int(Sound.Jump1) + jump_sound_index))

	}
}

// Height = (gravity * t2)/8
// 64 / 

player_land :: proc() {
	player.coyote_time = 0.15
	play_sound(.Land)
}

track_player_state :: proc() {
	if player.state != player.previous_state {
		#partial switch player.state {
		case .Grounded:
			player_land()
		}
	}
	player.previous_state = player.state
}

player_dash :: proc() {
	if is_action_buffered(.Dash) && has_charge(COST) {
		// Dash Physics
		pos := get_relative_pos(player.translation)
		pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}
		ripple.add(pos, .Teal)
		consume_action(.Dash)
		spend_charge(COST)
	}
}

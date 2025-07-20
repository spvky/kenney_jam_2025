package main

import "core:fmt"
import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"


Platform :: struct {
	translation: Vec2,
	size:        Vec2,
}

Collision_Data :: struct {
	normal: Vec2,
	mtv:    Vec2,
}


physics_step :: proc() {
	player_platform_collision()
	apply_gravity()
	player_jump()
	player_dash()
	manage_player_velocity()
	simulate_dynamics()
}

simulate_dynamics :: proc() {
	player.snapshot = player.translation
	player.translation += player.velocity * TICK_RATE
}

apply_gravity :: proc() {
	switch player.state {
	case .Airborne:
		if player.velocity.y < 0 {
			player.velocity.y += rising_gravity * TICK_RATE
		} else {
			player.velocity.y += falling_gravity * TICK_RATE
		}
		if player.coyote_time > 0 {
			player.coyote_time -= TICK_RATE
		}
		if player.coyote_time < 0 {
			player.coyote_time = 0
		}
	case .Grounded:
		player.velocity.y = 0
	}
}

manage_player_velocity :: proc() {
	max, acceleration, deceleration := player.speed.max, player.speed.acceleration, player.speed.deceleration
	if player.x_delta != 0 {
		if player.x_delta * player.velocity.x < max {
			player.velocity.x += TICK_RATE * acceleration * player.x_delta
		}
	} else {
		factor := 1 - deceleration
		player.velocity.x = player.velocity.x * factor
		if math.abs(player.velocity.x) < 0.3 {
			player.velocity.x = 0
		}
	}
}

player_platform_collision :: proc() {
	// Helper proc to calculate collision
	calculate_collision :: proc(
		collisions: ^[dynamic]Collision_Data,
		nearest_player: Vec2,
		nearest_collider: Vec2,
		radius: f32,
	) {
		collision: Collision_Data
		collision_vector := nearest_player - nearest_collider
		pen_depth := radius - l.length(collision_vector)
		collision_normal := l.normalize(collision_vector)
		mtv := collision_normal * pen_depth
		collision.normal = collision_normal
		collision.mtv = mtv
		append(collisions, collision)
	}

	collisions := make([dynamic]Collision_Data, 0, 8, allocator = context.temp_allocator)

	level := gamestate.levels[gamestate.current_level]

	for tile in level.tiles {
		if !tile_has_property(tile, .Collision) {continue}
		nearest_platform := project_point_onto_position(tile.position + level.position, player.translation)
		if l.distance(player.translation, nearest_platform) < player.radius {
			calculate_collision(&collisions, player.translation, nearest_platform, player.radius)
		}
	}

	// Respond to collisions
	for collision in collisions {
		player.translation += collision.mtv
		x_dot := math.abs(l.dot(collision.normal, Vec2{1, 0}))
		y_dot := math.abs(l.dot(collision.normal, Vec2{0, 1}))
		if x_dot > 0.7 {
			player.velocity.x = 0
		}
		if y_dot > 0.7 {
			player.velocity.y = 0
		}
	}

	ground_hits: int

	for tile in level.tiles {
		if !tile_has_property(tile, .Collision) {continue}

		feet_position := player.translation + Vec2{0, player.radius + 2}
		nearest_feet := project_point_onto_position(tile.position + level.position, feet_position)
		if l.distance(feet_position, nearest_feet) < 0.5 {
			if tile_has_property(tile, .Static_Gen) {
				add_charge(TICK_RATE * (math.abs(player.velocity.x * 1.2)))
			}
			ground_hits += 1
		}
	}

	if ground_hits > 0 && player.grounded_lockout == 0 {
		player.state = .Grounded
		player_land()
	} else {
		player.state = .Airborne
	}
}

project_point_onto_position :: proc(position: Vec2, point: Vec2) -> Vec2 {
	min := position
	max := position + {TILE_SIZE, TILE_SIZE}
	return l.clamp(point, min, max)
}

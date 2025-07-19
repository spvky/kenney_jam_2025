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
	entity_platform_collision()
	apply_gravity()
	player_jump()
	player_dash()
	manage_entity_velocity()
	simulate_dynamics()
}

simulate_dynamics :: proc() {
	for &entity in entities {
		entity.snapshot = entity.translation
		entity.translation += entity.velocity * TICK_RATE
	}
}

apply_gravity :: proc() {
	for &entity in entities {
		switch entity.state {
		case .Airborne:
			entity.velocity.y += 200 * TICK_RATE
		case .Grounded:
			entity.velocity.y = 0
		}
	}
}

manage_entity_velocity :: proc() {
	for &entity in entities {
		max, acceleration, deceleration, base_max, base_acceleration :=
			entity.speed.max,
			entity.speed.acceleration,
			entity.speed.deceleration,
			entity.speed.base_max,
			entity.speed.base_acceleration
		if entity.x_delta != 0 {
			if entity.x_delta * entity.velocity.x < max {
				entity.velocity.x += TICK_RATE * acceleration * entity.x_delta
			}
		} else {
			factor := 1 - deceleration
			entity.velocity.x = entity.velocity.x * factor
			if math.abs(entity.velocity.x) < 0.3 {
				entity.velocity.x = 0
			}
		}
		if max > entity.speed.base_max {
			entity.speed.max = l.lerp(max, base_max, TICK_RATE)
			if entity.speed.max < base_max {
				entity.speed.max = base_max
			}
		}
		if acceleration > entity.speed.base_acceleration {
			entity.speed.acceleration = l.lerp(acceleration, base_acceleration, TICK_RATE)
			if entity.speed.acceleration < base_acceleration {
				entity.speed.acceleration = base_acceleration
			}
		}
	}
}

entity_platform_collision :: proc() {
	// Helper proc to calculate collision
	calculate_collision :: proc(
		collisions: ^[dynamic]Collision_Data,
		nearest_entity: Vec2,
		nearest_collider: Vec2,
		radius: f32,
	) {
		collision: Collision_Data
		collision_vector := nearest_entity - nearest_collider
		pen_depth := radius - l.length(collision_vector)
		collision_normal := l.normalize(collision_vector)
		mtv := collision_normal * pen_depth
		collision.normal = collision_normal
		collision.mtv = mtv
		append(collisions, collision)
	}

	for &entity in entities {
		collisions := make([dynamic]Collision_Data, 0, 8, allocator = context.temp_allocator)

		for tile in gamestate.current_level.tiles {
			if !tile_has_property(tile, .Collision) {continue}
			nearest_platform := project_point_onto_position(
				tile.position + gamestate.current_level.position,
				entity.translation,
			)
			if l.distance(entity.translation, nearest_platform) < entity.radius {
				calculate_collision(&collisions, entity.translation, nearest_platform, entity.radius)
			}
		}

		// Respond to collisions
		for collision in collisions {
			entity.translation += collision.mtv
			x_dot := math.abs(l.dot(collision.normal, Vec2{1, 0}))
			y_dot := math.abs(l.dot(collision.normal, Vec2{0, 1}))
			if x_dot > 0.7 {
				entity.velocity.x = 0
			}
			if y_dot > 0.7 {
				entity.velocity.y = 0
			}
		}

		ground_hits: int

		for tile in gamestate.current_level.tiles {
			if !tile_has_property(tile, .Collision) {continue}

			feet_position := entity.translation + Vec2{0, entity.radius + 2}
			nearest_feet := project_point_onto_position(
				tile.position + gamestate.current_level.position,
				feet_position,
			)
			if l.distance(feet_position, nearest_feet) < 0.5 {
				if tile_has_property(tile, .Static_Gen) {
					add_charge(TICK_RATE * (math.abs(entity.velocity.x) / 5))
				}
				ground_hits += 1
			}
		}

		if ground_hits > 0 {
			entity.state = .Grounded
		} else {
			entity.state = .Airborne
		}
	}
}

project_point_onto_position :: proc(position: Vec2, point: Vec2) -> Vec2 {
	min := position
	max := position + {TILE_SIZE, TILE_SIZE}
	return l.clamp(point, min, max)
}

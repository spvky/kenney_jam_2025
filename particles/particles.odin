package particles

import "core:math"
import rl "vendor:raylib"

base_wind_speed: f32 = -16.0
wind_amplitude: f32 = 15.0
wind_frequency: f32 = 20

ParticleType :: enum {
	Leaf,
	Ripple,
}

Particle :: struct {
	position: rl.Vector2,
	velocity: rl.Vector2,
	lifetime: f32,
	radius:   f32,
	kind:     ParticleType,
}

particles: [dynamic]Particle

update :: proc() {
	i := 0
	dt := rl.GetFrameTime()
	for i < len(particles) {
		particle := &particles[i]
		particle.lifetime -= dt
		if particle.lifetime <= 0 {
			ordered_remove(&particles, i)
			continue
		}

		switch particle.kind {
		case .Leaf:
			time := f32(rl.GetTime())
			wind_wave := math.sin_f32((2 * math.PI * time + particle.position.y) / wind_frequency)
			particle.velocity.x = (base_wind_speed + wind_amplitude * wind_wave) * dt
			particle.velocity.y = 10 * dt

			particle.position += particle.velocity
		case .Ripple:
			particle.radius += dt * 20
		}

		i += 1
	}
}

draw :: proc(get_relative_pos: proc(pos: rl.Vector2) -> rl.Vector2) {
	for particle in particles {
		relative_pos := get_relative_pos(particle.position)
		switch particle.kind {
		case .Leaf:
			rl.DrawCircleV(relative_pos, particle.radius, rl.WHITE)
		case .Ripple:
			rl.DrawCircleLinesV(relative_pos, particle.radius, rl.WHITE)
		}
	}
}

add :: proc(particle: Particle) {
	append(&particles, particle)
}

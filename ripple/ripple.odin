package ripple

import rl "vendor:raylib"

MAX_RIPPLES :: 10
times: [MAX_RIPPLES]f32
diffuse: [MAX_RIPPLES]f32
centers: [MAX_RIPPLES]rl.Vector2
gradients: [MAX_RIPPLES]i32

PALETTE_COUNT :: 10
palette := [PALETTE_COUNT]rl.Vector3 {
	{.1, .8, .7},
	{.8, .2, .3},
	{.13, .8, .2},
	{1, .8, .2},
	{.1, .1, .1},
	{.1, .1, .1},
	{.1, .1, .1},
	{.1, .1, .1},
	{.1, .1, .1},
	{.1, .1, .1},
}

PaletteEnum :: enum {
	Teal,
	Red,
	Green,
	Yellow,
}

ripple_count: i32 = 0

set_shader_uniforms :: proc(shader: rl.Shader) {
	rl.SetShaderValueV(shader, rl.GetShaderLocation(shader, "u_times"), &times, .FLOAT, MAX_RIPPLES)
	rl.SetShaderValueV(shader, rl.GetShaderLocation(shader, "u_diffuse"), &diffuse, .FLOAT, MAX_RIPPLES)
	rl.SetShaderValueV(shader, rl.GetShaderLocation(shader, "u_centers"), &centers, .VEC2, MAX_RIPPLES)
	rl.SetShaderValueV(shader, rl.GetShaderLocation(shader, "u_gradients"), &gradients, .INT, MAX_RIPPLES)
	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "u_ripples_count"), &ripple_count, .INT)

	rl.SetShaderValueV(shader, rl.GetShaderLocation(shader, "u_palette"), &palette, .VEC3, PALETTE_COUNT)
}

update :: proc() {
	dt := rl.GetFrameTime()
	i := 0
	for i < int(ripple_count) {
		times[i] += dt
		if times[i] > 1 {
			for j := i + 1; j < int(ripple_count); j += 1 {
				times[j - 1] = times[j]
				diffuse[j - 1] = diffuse[j]
				centers[j - 1] = centers[j]
				gradients[j - 1] = gradients[j]
			}
			ripple_count -= 1
			continue
		}
		i += 1
	}
}

add :: proc(center: rl.Vector2, gradient: PaletteEnum, diffuse_: f32 = 0) {
	if ripple_count >= MAX_RIPPLES {return}

	idx := int(ripple_count)
	times[idx] = 0
	diffuse[idx] = diffuse_
	gradients[idx] = i32(gradient)
	centers[idx] = center

	ripple_count += 1
}

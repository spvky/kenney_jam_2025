package transition

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Transition :: struct {
	progress:         f32,
	shader:           rl.Shader,
	fallback_texture: rl.Texture,
	to:               rl.Texture,
	from:             rl.Texture,
}

transition: Transition

init :: proc(screen_width: i32, screen_height: i32) {

	temp_fallback := rl.LoadRenderTexture(screen_width, screen_height)
	rl.BeginTextureMode(temp_fallback)
	rl.ClearBackground(rl.RAYWHITE)
	rl.EndTextureMode()

	transition.fallback_texture = temp_fallback.texture

	transition.shader = rl.LoadShader(nil, "assets/shaders/transition.glsl")
	transition.progress = 1
}

start :: proc(from: Maybe(rl.Texture), to: Maybe(rl.Texture)) {

	if from_val, from_ok := from.?; from_ok {
		transition.from = from_val
	} else {
		transition.from = transition.fallback_texture
	}

	if to_val, to_ok := to.?; to_ok {
		transition.to = to_val
	} else {
		transition.to = transition.fallback_texture
	}

	transition.progress = 0
}

update :: proc() {
	dt := rl.GetFrameTime()
	transition.progress = math.min(transition.progress + dt, 1)
	rl.SetShaderValue(
		transition.shader,
		rl.GetShaderLocation(transition.shader, "progress"),
		&transition.progress,
		.FLOAT,
	)
}

draw :: proc() {
	rl.BeginShaderMode(transition.shader)
	rl.SetShaderValueTexture(transition.shader, rl.GetShaderLocation(transition.shader, "from"), transition.from)
	rl.DrawTexture(transition.to, 0, 0, rl.WHITE)
	rl.EndShaderMode()

}

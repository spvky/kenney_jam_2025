package main

import math "core:math"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1600
WINDOW_HEIGHT :: 900

SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 360
TICK_RATE :: 1.0 / 200.0

time: Time
gamestate: GameState

Time :: struct {
	t:               f32,
	simulation_time: f32,
	started:         bool,
}

GameState :: struct {
	render_surface: rl.RenderTexture,
}

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "KenneyJam")
	defer rl.CloseWindow()

	gamestate.render_surface = rl.LoadRenderTexture(
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
	)

	for !rl.WindowShouldClose() {
		update()
		draw()
	}
}


draw :: proc() {
	rl.BeginTextureMode(gamestate.render_surface)
	rl.ClearBackground(rl.BLACK)

	rl.DrawCircle(20, 20, 2, rl.WHITE)
	rl.EndTextureMode()

	rl.BeginDrawing()
	rl.DrawTexturePro(
		gamestate.render_surface.texture,
		{0, 0, SCREEN_WIDTH, -SCREEN_HEIGHT},
		{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT},
		{0, 0},
		0,
		rl.WHITE,
	)
	rl.EndDrawing()
}


update :: proc() -> f32 {
	if !time.started {
		time.t = f32(rl.GetTime())
		time.started = true
	}
	// Get Input
	//

	t1 := f32(rl.GetTime())
	elapsed := math.min(t1 - time.t, 0.25)

	time.t = t1
	time.simulation_time += elapsed
	for time.simulation_time >= TICK_RATE {
		// Physics stuff
		//
		time.simulation_time -= TICK_RATE
	}
	return time.simulation_time / TICK_RATE
}

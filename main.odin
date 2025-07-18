package main

import rl "vendor:raylib"

SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 900
TICK_RATE :: 1.0 / 200.0

time: Time

Time :: struct {
	t:               f32,
	simulation_time: f32,
	started:         bool,
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "KenneyJam")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		update()
		draw()
	}
}


draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
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
	elapsed := t1 - time.t
	if elapsed > 0.25 {
		elapsed = 0.25
	}
	time.t = t1
	time.simulation_time += elapsed
	for time.simulation_time >= TICK_RATE {
		// Physics stuff
		//
		time.simulation_time -= TICK_RATE
	}
	return time.simulation_time / TICK_RATE
}

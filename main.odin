package main

import fmt "core:fmt"
import math "core:math"
import ldtk "ldtk"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1600
WINDOW_HEIGHT :: 900

SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 360
TICK_RATE :: 1.0 / 200.0

time: Time
gamestate: GameState
input_buffer: Input_Buffer
entity_textures: [Entity_Tag]rl.Texture2D
entities := make([dynamic]Entity, 0, 16)
platforms := [?]Platform{{translation = {70, 90}, size = {30, 5}}}
tilesheet: rl.Texture

Time :: struct {
	t:               f32,
	simulation_time: f32,
	started:         bool,
}

GameState :: struct {
	render_surface: rl.RenderTexture,
	level:          Level,
}

Vec2 :: [2]f32

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "KenneyJam")
	defer rl.CloseWindow()
	entity_textures = load_textures()
	tilesheet = rl.LoadTexture(
		"assets/Tilemap/monochrome_tilemap_transparent.png",
	)
	append(&entities, make_player())


	if project, ok := ldtk.load_from_file(
		   "assets/level.ldtk",
		   context.temp_allocator,
	   ).?; ok {

		gamestate.level.tiles = load_tiles(
			project.levels[0],
			project.defs.tilesets[0],
		)
	}

	gamestate.render_surface = rl.LoadRenderTexture(
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
	)

	for !rl.WindowShouldClose() {
		update()
		draw()
		free_all(context.temp_allocator)
	}
	unload_textures()
	delete(entities)
}


draw :: proc() {
	rl.BeginTextureMode(gamestate.render_surface)
	rl.ClearBackground(rl.BLACK)
	draw_tiles(gamestate.level, tilesheet)
	render_entities()
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
	animate_entities()
	if !time.started {
		time.t = f32(rl.GetTime())
		time.started = true
	}
	input()

	t1 := f32(rl.GetTime())
	elapsed := math.min(t1 - time.t, 0.25)

	time.t = t1
	time.simulation_time += elapsed
	for time.simulation_time >= TICK_RATE {
		// Physics stuff
		physics_step()
		//
		time.simulation_time -= TICK_RATE
	}
	return time.simulation_time / TICK_RATE
}

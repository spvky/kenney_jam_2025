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
	camera_offset:  rl.Vector2,
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

		// TEMPORARY
		level := project.levels[0]

		gamestate.level.tiles = load_tiles(level, project.defs.tilesets[0])
		gamestate.level.width = level.px_width
		gamestate.level.height = level.px_height
		gamestate.level.position = {f32(level.world_x), f32(level.world_y)}
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

get_relative_pos :: proc(pos: rl.Vector2) -> rl.Vector2 {
	return(
		pos -
		gamestate.camera_offset +
		{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2} \
	)
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

	level := gamestate.level

	target_position :=
		(entities[Entity_Tag.Player].snapshot - gamestate.camera_offset) / 20
	gamestate.camera_offset += target_position

	// clamping to level in x axis
	gamestate.camera_offset.x = math.max(
		level.position.x + SCREEN_WIDTH / 2,
		math.min(
			level.position.x + f32(level.width) - (SCREEN_WIDTH / 2),
			gamestate.camera_offset.x,
		),
	)

	// clamping to level in y axis
	gamestate.camera_offset.y = math.max(
		level.position.y + SCREEN_HEIGHT / 2,
		math.min(
			level.position.y + f32(level.height) - (SCREEN_HEIGHT / 2),
			gamestate.camera_offset.y,
		),
	)

	return time.simulation_time / TICK_RATE
}

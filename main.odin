package main

import fmt "core:fmt"
import math "core:math"
import ldtk "ldtk"
import ripple "ripple"
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
ui_textures: [Ui_Texture_Tag]rl.Texture2D
entities := make([dynamic]Entity, 0, 16)
static_meter := Static_Meter {
	max_charge = 100,
	charge     = 0,
}
tilesheet: rl.Texture


Time :: struct {
	t:               f32,
	simulation_time: f32,
	started:         bool,
}

GameState :: struct {
	render_surface:       rl.RenderTexture,
	levels:               [dynamic]Level,
	current_level:        Level,
	intermediate_surface: rl.RenderTexture,
	camera_offset:        rl.Vector2,
	vfx_shader:           rl.Shader,
}

Vec2 :: [2]f32


update_shader_uniforms :: proc() {
	shader := gamestate.vfx_shader
	width := SCREEN_WIDTH
	height := SCREEN_HEIGHT
	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "u_tex_width"), &width, .INT)
	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "u_tex_height"), &height, .INT)

	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "u_camera_offset_x"), &gamestate.camera_offset.x, .FLOAT)
	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "u_camera_offset_y"), &gamestate.camera_offset.y, .FLOAT)

	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "u_time"), &time, .FLOAT)

	ripple.set_shader_uniforms(shader)

}

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "KenneyJam")
	defer rl.CloseWindow()
	entity_textures = load_entity_textures()
	ui_textures = load_ui_textures()
	tilesheet = rl.LoadTexture("assets/Tilemap/monochrome_tilemap_transparent.png")

	gamestate.vfx_shader = rl.LoadShader(nil, "assets/shaders/vfx.glsl")


	if project, ok := ldtk.load_from_file("assets/level.ldtk", context.temp_allocator).?; ok {
		gamestate.levels = get_all_levels(project)
		gamestate.current_level = gamestate.levels[0]
	}

	append(&entities, make_player(get_spawn_point(gamestate.current_level)))

	gamestate.render_surface = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)
	gamestate.intermediate_surface = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)

	for !rl.WindowShouldClose() {
		update()
		draw()
		free_all(context.temp_allocator)
	}
	unload_textures()
	delete(entities)
}

get_relative_pos :: proc(pos: rl.Vector2) -> rl.Vector2 {
	return pos - gamestate.camera_offset + {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
}

draw :: proc() {
	update_shader_uniforms()

	rl.BeginTextureMode(gamestate.intermediate_surface)
	rl.ClearBackground(rl.BLACK)
	draw_tiles(gamestate.current_level, tilesheet)
	render_entities()
	rl.EndTextureMode()

	rl.BeginTextureMode(gamestate.render_surface)
	rl.BeginShaderMode(gamestate.vfx_shader)
	rl.DrawTexturePro(
		gamestate.intermediate_surface.texture,
		{0, 0, SCREEN_WIDTH, -SCREEN_HEIGHT},
		{0, 0, SCREEN_WIDTH, SCREEN_HEIGHT},
		{0, 0},
		0,
		rl.WHITE,
	)
	rl.EndShaderMode()

	draw_static_meter()
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

	level := gamestate.current_level

	target_position := (entities[Entity_Tag.Player].snapshot - gamestate.camera_offset) / 20
	gamestate.camera_offset += target_position

	// clamping to level in x axis
	gamestate.camera_offset.x = math.max(
		level.position.x + SCREEN_WIDTH / 2,
		math.min(level.position.x + f32(level.width) - (SCREEN_WIDTH / 2), gamestate.camera_offset.x),
	)

	// clamping to level in y axis
	gamestate.camera_offset.y = math.max(
		level.position.y + SCREEN_HEIGHT / 2,
		math.min(level.position.y + f32(level.height) - (SCREEN_HEIGHT / 2), gamestate.camera_offset.y),
	)


	player := entities[Entity_Tag.Player]
	pos := get_relative_pos(player.translation)
	pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}
	if (rl.IsKeyPressed(.E)) {
		ripple.add(pos, 1)
		ripple.add(pos, 2)
	}
	if (rl.IsKeyPressed(.Q)) {
		ripple.add(pos, 0)
	}

	check_kill_player()
	ripple.update()
	return time.simulation_time / TICK_RATE
}

check_kill_player :: proc() {
	level := gamestate.current_level
	player := &entities[Entity_Tag.Player]
	pos := get_relative_pos(player.translation)
	pos /= {SCREEN_WIDTH, SCREEN_HEIGHT}


	if check_killzone(level, player.translation) || player.translation.y > level.position.y + f32(level.height) {
		ripple.add(pos, 1)

		player.translation = get_spawn_point(level)
		player.velocity = {0, 0}
		player.snapshot = player.translation

	}
}

check_killzone :: proc(level: Level, pos: rl.Vector2) -> bool {

	pos_rect := rl.Rectangle{pos[0], pos[1], TILE_SIZE, TILE_SIZE}

	for entity in level.entities {
		#partial switch entity.type {
		case .Killzone:
			entity_position := entity.position + level.position
			killzone_rect := rl.Rectangle{entity_position[0], entity_position[1], TILE_SIZE, TILE_SIZE}
			if rl.CheckCollisionRecs(pos_rect, killzone_rect) {
				return true
			}
		}
	}
	return false
}

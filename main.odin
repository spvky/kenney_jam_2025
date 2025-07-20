package main

import fmt "core:fmt"
import math "core:math"
import ldtk "ldtk"
import particles "particles"
import ripple "ripple"
import transition "transition"
import rl "vendor:raylib"
WINDOW_WIDTH :: 1600
WINDOW_HEIGHT :: 900

SCREEN_WIDTH :: 480
SCREEN_HEIGHT :: 360
TICK_RATE :: 1.0 / 200.0

player: Player
enemies: [dynamic]Enemy
time: Time
gamestate: GameState
input_buffer: Input_Buffer
player_texture: rl.Texture2D
enemy_texture: rl.Texture2D
ui_textures: [Ui_Texture_Tag]rl.Texture2D
sounds: [Sound]rl.Sound
static_meter := Static_Meter {
	max_charge = 100,
	charge     = 0,
}

player_animations := [Animation_Tag]Animation {
	.Idle = SingleFrame{idx = 0},
	.Run = MultiFrame{start = 1, end = 3},
	.Jump = SingleFrame{idx = 4},
}
tilesheet: rl.Texture


Time :: struct {
	t:               f32,
	simulation_time: f32,
	started:         bool,
}

GameStateEnum :: enum {
	MainMenu,
	Playing,
}

MainMenuContext :: struct {
	selected:         u32,
	starting_playing: bool,
}

GameState :: struct {
	render_surface:       rl.RenderTexture,
	levels:               [dynamic]Level,
	current_level:        int,
	intermediate_surface: rl.RenderTexture,
	camera_offset:        rl.Vector2,
	vfx_shader:           rl.Shader,
	state:                GameStateEnum,
	menu_context:         MainMenuContext,
	transitioning:        bool,
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
	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()


	player_texture = load_player_texture()
	enemy_texture = load_enemy_texture()
	sounds = load_sounds()
	transition.init(SCREEN_WIDTH, SCREEN_HEIGHT)

	ui_textures = load_ui_textures()
	tilesheet = rl.LoadTexture("assets/Tilemap/monochrome_tilemap_transparent.png")

	gamestate.vfx_shader = rl.LoadShader(nil, "assets/shaders/vfx.glsl")


	if project, ok := ldtk.load_from_file("assets/level.ldtk", context.temp_allocator).?; ok {
		gamestate.levels = get_all_levels(project)
		gamestate.current_level = 0
	}

	player = make_player(get_spawn_point(gamestate.levels[gamestate.current_level]))

	gamestate.render_surface = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)
	gamestate.intermediate_surface = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)

	for !rl.WindowShouldClose() {
		update()
		draw()
		free_all(context.temp_allocator)
	}
	delete(enemies)
	unload_player_texture()
	unload_enemy_texture()
}

get_relative_pos :: proc(pos: rl.Vector2) -> rl.Vector2 {
	return pos - gamestate.camera_offset + {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
}

draw :: proc() {
	switch gamestate.state {
	case .Playing:
		update_shader_uniforms()

		rl.BeginTextureMode(gamestate.intermediate_surface)
		rl.ClearBackground(rl.BLACK)
		particles.draw(get_relative_pos)
		draw_tiles(gamestate.levels[gamestate.current_level], tilesheet)
		render_player()
		render_enemies()
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
		transition.draw()
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
	case .MainMenu:
		rl.BeginTextureMode(gamestate.render_surface)
		rl.ClearBackground(rl.BLACK)
		font_size :: 10

		options: [2]string = {"play", "quit"}
		for i in 0 ..< len(options) {
			option := options[i]
			current_selected := i == int(gamestate.menu_context.selected)
			text := rl.TextFormat(current_selected ? "* %s" : " %s", option)
			text_width := rl.MeasureText(text, font_size)
			rl.DrawText(
				text,
				SCREEN_WIDTH / 2 - text_width,
				i32(100 + i * font_size),
				font_size,
				current_selected ? {25, 204, 176, 255} : rl.WHITE,
			)
		}
		transition.draw()
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
}

update :: proc() -> f32 {
	switch gamestate.state {
	case .Playing:
		frametime := rl.GetFrameTime()
		animate_player(frametime)
		animate_enemies(frametime)
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
			time.simulation_time -= TICK_RATE
		}
		set_player_animation()
		track_player_state()
		level := gamestate.levels[gamestate.current_level]

		target_position := (player.snapshot - gamestate.camera_offset) / 20
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

		for tile in level.tiles {
			if tile_has_property(tile, .LeafEmitter) {
				if abs(math.sin(f32(rl.GetTime() * 3) + tile.position.x)) < 0.002 {
					center_position := tile.position + level.position + ({TILE_SIZE, TILE_SIZE} / 2)
					particles.add({position = center_position, lifetime = 15, radius = 0.5, kind = .Leaf})
				}
			}
		}

		if gamestate.transitioning {
			if transition.transition.progress == 1 {
				gamestate.current_level += 1
				transition.start(nil, gamestate.render_surface.texture)
				spawn_player(get_spawn_point(gamestate.levels[gamestate.current_level]))
				gamestate.transitioning = false

			}
		}

		transition.update()
		handle_triggers()
		ripple.update()
		particles.update()
	case .MainMenu:
		transition.update()
		ctx := &gamestate.menu_context
		blip_sound_index := int(rl.GetTime() * 2) % 3
		if (ctx.starting_playing) {
			if transition.transition.progress == 1 {
				gamestate.state = .Playing
				transition.start(nil, gamestate.render_surface.texture)
			}
		} else {
			menu_options :: 2
			if rl.IsKeyPressed(.W) {
				ctx.selected = (ctx.selected + 1) % menu_options
				play_sound(Sound(int(Sound.Select1) + blip_sound_index))
			} else if rl.IsKeyPressed(.S) {
				ctx.selected = (ctx.selected + menu_options - 1) % menu_options
				play_sound(Sound(int(Sound.Select1) + blip_sound_index))
			} else if rl.IsKeyPressed(.E) {
				play_sound(Sound(int(Sound.Select1) + blip_sound_index))

				switch ctx.selected {
				case 0:
					// start playing
					ctx.starting_playing = true
					transition.start(gamestate.render_surface.texture, nil)
				case 1:
					// quit
					rl.CloseWindow()
				}
			}
		}
	}
	return time.simulation_time / TICK_RATE
}

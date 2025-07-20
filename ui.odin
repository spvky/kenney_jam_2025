package main

import math "core:math"
import "ripple"
import rl "vendor:raylib"

Ui_Texture_Tag :: enum {
	StaticMeter,
	StaticMeterFull,
}

load_ui_textures :: proc() -> [Ui_Texture_Tag]rl.Texture2D {
	meter_tex := rl.LoadTexture("assets/textures/static_gauge_normal.png")
	meter_full_tex := rl.LoadTexture("assets/textures/static_gauge_full.png")
	return [Ui_Texture_Tag]rl.Texture2D{.StaticMeter = meter_tex, .StaticMeterFull = meter_full_tex}
}

draw_static_meter :: proc() {
	using static_meter

	frametime := rl.GetFrameTime()
	handle_static_meter(frametime)
	color: rl.Color = charge == 100 ? {25, 204, 176, 255} : {255, 255, 255, 255}
	meter_texture := charge == 100 ? ui_textures[.StaticMeterFull] : ui_textures[.StaticMeter]
	rl.DrawRectanglePro({x = 16, y = 128, width = 8, height = displayed_charge}, {6, 0}, 180, color)
	rl.DrawTextureV(meter_texture, {10, 10}, rl.WHITE)
}

draw_collectible_counter :: proc(level_index: int, tilesheet: rl.Texture) {
	total_count := 0
	collected_count := 0

	texture_collectible: Collectible

	font_size := i32(20)
	padding := i32(10)

	for collectible in collectibles {
		if total_count == 0 {
			texture_collectible = collectible
		}
		if collectible.level_index == gamestate.current_level {
			total_count += 1
			if collectible.is_collected {
				collected_count += 1
			}
		}
	}

	text := rl.TextFormat("%d/%d", collected_count, total_count)
	text_width := rl.MeasureText(text, font_size)
	x := SCREEN_WIDTH - text_width - padding
	y := padding

	texture_x := f32(x) - texture_collectible.tile_rect.width

	rl.DrawText(text, x + 1, y + 1, font_size, rl.BLACK)
	rl.DrawText(text, x, y, font_size, rl.WHITE)
	rl.DrawTextureRec(tilesheet, texture_collectible.tile_rect, {texture_x, f32(y)}, rl.WHITE)
}

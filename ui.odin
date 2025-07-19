package main

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
	meter_texture := charge == 100 ? ui_textures[.StaticMeterFull] : ui_textures[.StaticMeter]
	rl.DrawRectanglePro({x = 16, y = 128, width = 8, height = displayed_charge}, {6, 0}, 180, rl.WHITE)
	rl.DrawTextureV(meter_texture, {10, 10}, rl.WHITE)
}

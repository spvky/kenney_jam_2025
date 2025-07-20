package main

import rl "vendor:raylib"

Enemy :: struct {
	translation: Vec2,
}

enemy_frame_index: int
enemy_frame_length: f32 = 0.25
enemy_frame_progress: f32

animate_enemies :: proc(frametime: f32) {
	enemy_frame_progress += frametime
	if enemy_frame_progress >= enemy_frame_length {
		enemy_frame_progress = 0
		if enemy_frame_index == 1 do enemy_frame_index = 0
		if enemy_frame_index == 0 do enemy_frame_index = 1
	}
}

render_enemies :: proc() {
	for enemy in enemies {
		texture_rec := rl.Rectangle {
			x      = f32(enemy_frame_index) * 16,
			y      = 0,
			width  = 16,
			height = 16,
		}
		offset := Vec2{-8, -8}
		rl.DrawTextureRec(enemy_texture, texture_rec, get_relative_pos(enemy.translation + offset), rl.WHITE)
	}
}


load_enemy_texture :: proc() -> rl.Texture2D {
	enemy_tex := rl.LoadTexture("assets/textures/enemy.png")
	return enemy_tex
}


unload_enemy_texture :: proc() {
	rl.UnloadTexture(enemy_texture)
}

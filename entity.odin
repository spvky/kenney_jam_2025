package main

import rl "vendor:raylib"

Entity :: struct {
	tag: Entity_Tag,
	state: Entity_State,
	radius: f32,
	animation_player: AnimationPlayer,
	translation: Vec2,
	velocity: Vec2,
	snapshot: Vec2,
}

Entity_Tag :: enum {
	Player
}

Entity_State :: enum {
	Grounded,
	Airborne
}

AnimationPlayer :: struct {
	anim_index: int,
	anim_length: int,
	frame_length: f32,
	frametime: f32,
	texture: ^rl.Texture2D
}

make_player :: proc() -> Entity {
	return Entity {
		tag = .Player,
		state = .Grounded,
		radius = 6,
		animation_player = AnimationPlayer {
			anim_index = 2,
			anim_length = 3,
			frame_length = 0.25,
			frametime = 0,
			texture = &entity_textures[.Player]
		},
		translation = {70,50}
	}
}

load_textures :: proc() -> [Entity_Tag]rl.Texture2D {
	player_tex := rl.LoadTexture("assets/textures/player.png")
	return [Entity_Tag]rl.Texture2D{
		.Player = player_tex
	}
}

unload_textures :: proc() {
	for v,k in entity_textures {
		rl.UnloadTexture(v)
	}
}


animate_entities :: proc() {
	frametime := rl.GetFrameTime()
	for &entity in entities {
		entity.animation_player.frametime += frametime
		if entity.animation_player.frametime > entity.animation_player.frame_length {
			entity.animation_player.anim_index += 1
			entity.animation_player.frametime = 0
			if entity.animation_player.anim_index > entity.animation_player.anim_length {
				entity.animation_player.anim_index = 1
			}
		}
	}
}

render_entities :: proc() {
	for entity in entities {
		texture := entity.animation_player.texture^
		texture_rec := rl.Rectangle{x=f32(entity.animation_player.anim_index)*16,y=0,width=16, height=16}
		offset := Vec2{-8,-8}
		rl.DrawTextureRec(texture, texture_rec, entity.snapshot + offset, rl.WHITE)
	}
}


package main

import ripple "ripple"
import rl "vendor:raylib"

Collectible :: struct {
	position:     Vec2,
	is_collected: bool,
	tile_rect:    rl.Rectangle,
	level_index:  int,
}

collectibles: [dynamic]Collectible
collected :: true

collect_collectible :: proc(collectible: ^Collectible) {

	collectible.is_collected = collected
	ripple.add(get_relative_pos(collectible.position) / {SCREEN_WIDTH, SCREEN_HEIGHT}, .Gold, 50.)
}

load_collectibles :: proc(levels: [dynamic]Level) {

	for i in 0 ..< len(levels) {
		level := levels[i]
		for entity in level.entities {

			if entity.type == .Collectible {

				if tile, ok := entity.tile.?; ok {
					tile_rect := rl.Rectangle{f32(tile.x), f32(tile.y), f32(tile.w), f32(tile.h)}
					append(&collectibles, Collectible{entity.position + level.position, !collected, tile_rect, i})
				}


			}

		}
	}
}

draw_collectibles :: proc(level_index: int, tileset: rl.Texture) {

	for collectible in collectibles {
		if collectible.level_index == level_index && !collectible.is_collected {

			rl.DrawTextureRec(tileset, collectible.tile_rect, get_relative_pos(collectible.position), rl.WHITE)
		}
	}

}

reset_collectibles :: proc(level_index: int) {
	for &collectible in collectibles {
		if collectible.level_index == level_index && collectible.is_collected {
			collectible.is_collected = !collected
		}
	}
}


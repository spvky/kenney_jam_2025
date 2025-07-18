package main

import rl "vendor:raylib"
Level :: struct {
	tiles: [dynamic]Tile,
}

Tile :: struct {
	draw_coords: rl.Rectangle,
	rotation:    f32,
	alpha:       f32,
	position:    rl.Vector2,
}

draw_tiles :: proc(level: Level, tilesheet: rl.Texture) {
	for tile in level.tiles {
		rl.DrawTextureRec(tilesheet, tile.draw_coords, tile.position, rl.WHITE)
	}
}

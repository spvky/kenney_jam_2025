package main
import fmt "core:fmt"
import ldtk "ldtk"
import rl "vendor:raylib"

TILE_SIZE :: 16

Level :: struct {
	tiles: [dynamic]Tile,
}

Tile :: struct {
	draw_coords: rl.Rectangle,
	rotation:    f32,
	alpha:       f32,
	position:    rl.Vector2,
}

load_tiles :: proc(level: ldtk.Level) -> [dynamic]Tile {

	tiles: [dynamic]Tile

	for layer in level.layer_instances {
		switch layer.type {
		case .Entities:
		case .Tiles:
		case .AutoLayer, .IntGrid:
			for tile in layer.auto_layer_tiles {
				append(
					&tiles,
					Tile {
						{
							f32(tile.src[0]),
							f32(tile.src[1]),
							TILE_SIZE,
							TILE_SIZE,
						},
						0,
						tile.a,
						{f32(tile.px[0]), f32(tile.px[1])},
					},
				)
			}

		}
	}
	return tiles
}

draw_tiles :: proc(level: Level, tilesheet: rl.Texture) {
	for tile in level.tiles {
		rl.DrawTextureRec(tilesheet, tile.draw_coords, tile.position, rl.WHITE)
	}
}

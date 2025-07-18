package main
import fmt "core:fmt"
import ldtk "ldtk"
import rl "vendor:raylib"

TILE_SIZE :: 16

Level :: struct {
	tiles:    [dynamic]Tile,
	width:    int,
	height:   int,
	position: rl.Vector2,
}

Tile :: struct {
	draw_coords: rl.Rectangle,
	rotation:    f32,
	alpha:       f32,
	position:    rl.Vector2,
	properties: bit_set[Tile_Property]
}

Tile_Property :: enum {Collision, Slippery, Static_Gen}

properties_from_strings :: proc(properties: []string) -> bit_set[Tile_Property] {
	property_set: bit_set[Tile_Property]
	for value in properties {
		switch value {
			case "Collision":
				property_set = property_set | {.Collision}
			case "Slippery":
				property_set = property_set | {.Slippery}
			case "Static_Gen":
				property_set = property_set | {.Static_Gen}
		}
	}
	return property_set
}

tile_has_property :: proc(tile: Tile, property: Tile_Property) -> bool {
	return property in tile.properties
}

load_tiles :: proc(
	level: ldtk.Level,
	tileset_definition: ldtk.Tileset_Definition,
) -> [dynamic]Tile {
	tiles: [dynamic]Tile

	for layer in level.layer_instances {
		switch layer.type {
		case .Entities:
		case .Tiles:
		case .AutoLayer, .IntGrid:
			for tile in layer.auto_layer_tiles {
				raw_properties: [dynamic]string
				for def in tileset_definition.enum_tags {
					found := false
					for id in def.tile_ids {
						if id == tile.t {
							found = true
							break
						}
					}
					if found {
						append(&raw_properties, def.enum_value_id)
					}
				}
				properties := properties_from_strings(raw_properties[:])
				delete(raw_properties)
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
						properties,
					},
				)
			}
		}
	}
	return tiles
}

draw_tiles :: proc(level: Level, tilesheet: rl.Texture) {
	for tile in level.tiles {
		rl.DrawTextureRec(
			tilesheet,
			tile.draw_coords,
			get_relative_pos(tile.position),
			rl.WHITE,
		)
	}
}

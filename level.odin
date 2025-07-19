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
	entities: [dynamic]Level_Entity,
}

Tile :: struct {
	draw_coords: rl.Rectangle,
	rotation:    f32,
	alpha:       f32,
	position:    rl.Vector2,
	properties:  bit_set[Tile_Property],
}

Level_Entity :: struct {
	type:     enum {
		Killzone,
		Next_level,
		Player_spawn,
	},
	position: rl.Vector2,
}

Tile_Property :: enum {
	Collision,
	Slippery,
	Static_Gen,
	LeafEmitter,
}

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
		case "LeafEmitter":
			property_set = property_set | {.LeafEmitter}
		}
	}
	return property_set
}

tile_has_property :: proc(tile: Tile, property: Tile_Property) -> bool {
	return property in tile.properties
}

add_tile :: proc(tiles: ^[dynamic]Tile, tileset_definition: ldtk.Tileset_Definition, tile: ldtk.Tile_Instance) {
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
		tiles,
		Tile {
			{f32(tile.src[0]), f32(tile.src[1]), TILE_SIZE, TILE_SIZE},
			0,
			tile.a,
			{f32(tile.px[0]), f32(tile.px[1])},
			properties,
		},
	)

}

add_entity :: proc(entities: ^[dynamic]Level_Entity, entity_instance: ldtk.Entity_Instance) {
	entity := Level_Entity {
		position = {f32(entity_instance.px[0]), f32(entity_instance.px[1])},
	}

	switch entity_instance.identifier {
	case "Killzone":
		entity.type = .Killzone
	case "Player_spawn":
		entity.type = .Player_spawn
	case "Next_level":
		entity.type = .Next_level
	}

	append(entities, entity)
}


load_level :: proc(level: ldtk.Level, tileset_definition: ldtk.Tileset_Definition) -> Level {
	tiles: [dynamic]Tile
	entities: [dynamic]Level_Entity

	for layer in level.layer_instances {
		switch layer.type {
		case .Entities:
			for entity in layer.entity_instances {
				add_entity(&entities, entity)
			}

		case .Tiles:
			for tile in layer.grid_tiles {
				add_tile(&tiles, tileset_definition, tile)
			}
		case .AutoLayer, .IntGrid:
			for tile in layer.auto_layer_tiles {
				add_tile(&tiles, tileset_definition, tile)
			}
		}
	}

	return {
		entities = entities,
		tiles = tiles,
		height = level.px_height,
		width = level.px_width,
		position = {f32(level.world_x), f32(level.world_y)},
	}
}

draw_tiles :: proc(level: Level, tilesheet: rl.Texture) {
	for tile in level.tiles {
		rl.DrawTextureRec(tilesheet, tile.draw_coords, get_relative_pos(tile.position + level.position), rl.WHITE)
	}
}

get_all_levels :: proc(project: ldtk.Project) -> [dynamic]Level {

	levels: [dynamic]Level

	for level in project.levels {

		append(&levels, load_level(level, project.defs.tilesets[0]))
	}
	return levels
}

get_spawn_point :: proc(level: Level) -> rl.Vector2 {
	for entity in level.entities {
		if entity.type == .Player_spawn {
			return entity.position
		}
	}
	assert(false)
	return {0, 0}
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

switch_level :: proc(current_index: int) {


}

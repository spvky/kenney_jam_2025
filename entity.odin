package main

import rl "vendor:raylib"

Entity :: struct {
	tag: Entity_Tag,
}

Entity_Tag :: enum {
	Player,
	Enemy
}

Entity_Textures :: struct {
	textures: [Entity_Tag]rl.Texture2D
}

// load_textures :: proc() -> Entity_Textures {

// }

package main

import rl "vendor:raylib"


Sound :: enum {
	Land,
}


load_sounds :: proc() -> [Sound]rl.Sound {
	return [Sound]rl.Sound{.Land = rl.LoadSound("assets/sounds/land.wav")}
}

play_sound :: proc(sound_tag: Sound) {
	rl.PlaySound(sounds[sound_tag])
}

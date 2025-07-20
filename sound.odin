package main

import rl "vendor:raylib"


Sound :: enum {
	Land,
	Jump1,
	Jump2,
	Jump3,
}


load_sounds :: proc() -> [Sound]rl.Sound {
	rl.SetMasterVolume(0.2)
	return [Sound]rl.Sound {
		.Land = rl.LoadSound("assets/sounds/land.wav"),
		.Jump1 = rl.LoadSound("assets/sounds/Jump.wav"),
		.Jump2 = rl.LoadSound("assets/sounds/Jump1.wav"),
		.Jump3 = rl.LoadSound("assets/sounds/Jump2.wav"),
	}
}

play_sound :: proc(sound_tag: Sound) {
	rl.PlaySound(sounds[sound_tag])
}

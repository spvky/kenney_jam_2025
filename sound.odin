package main

import rl "vendor:raylib"


Sound :: enum {
	Land,
	Jump1,
	Jump2,
	Jump3,
	Death,
	Select1,
	Select2,
	Select3,
	Charged,
	Collect1,
	Collect2,
	Collect3,
	Collect4,
}


load_sounds :: proc() -> [Sound]rl.Sound {
	rl.SetMasterVolume(0.2)
	return [Sound]rl.Sound {
		.Land = rl.LoadSound("assets/sounds/land.wav"),
		.Jump1 = rl.LoadSound("assets/sounds/Jump.wav"),
		.Jump2 = rl.LoadSound("assets/sounds/Jump1.wav"),
		.Jump3 = rl.LoadSound("assets/sounds/Jump2.wav"),
		.Death = rl.LoadSound("assets/sounds/Boom.wav"),
		.Select1 = rl.LoadSound("assets/sounds/Blip.wav"),
		.Select2 = rl.LoadSound("assets/sounds/Blip1.wav"),
		.Select3 = rl.LoadSound("assets/sounds/Blip2.wav"),
		.Charged = rl.LoadSound("assets/sounds/Charged.wav"),
		.Collect1 = rl.LoadSound("assets/sounds/Pickup.wav"),
		.Collect2 = rl.LoadSound("assets/sounds/Pickup1.wav"),
		.Collect3 = rl.LoadSound("assets/sounds/Pickup2.wav"),
		.Collect4 = rl.LoadSound("assets/sounds/Pickup3.wav"),
	}
}

play_sound :: proc(sound_tag: Sound) {
	rl.PlaySound(sounds[sound_tag])
}

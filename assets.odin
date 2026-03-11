package main

import rl "vendor:raylib"

assets: Assets

Assets :: struct {
	font: rl.Font,
}

load_assets :: proc() {
	assets.font = rl.LoadFont("assets/dungeon-mode.ttf")
}

unload_assets :: proc() {
	rl.UnloadFont(assets.font)
}

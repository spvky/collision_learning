package main

import rl "vendor:raylib"

Player :: struct {
	position: Vec3,
	speed:    f32,
}

player: Player

debug_draw_player :: proc() {
	rl.DrawModel(gimbal, player.position, 1, rl.WHITE)
}

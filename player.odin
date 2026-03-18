package main

import l "core:math/linalg"
import gm "shared:ghst/math"
import rl "vendor:raylib"

Player :: struct {
	position:    Vec3,
	velocity:    Vec3,
	speed:       f32,
	move_delta:  Vec3,
	state:       Player_State,
	flags:       bit_set[Player_Flag;u16],
	flag_timers: [Player_Flag]f32,
}

player: Player

init_player :: proc(position: Vec3) {
	player.position = position
	player.speed = 5
}

debug_draw_player :: proc() {
	// rl.DrawModel(gimbal, player.position, 1, rl.WHITE)
	rl.DrawSphere(player.position, 0.5, rl.BLUE)
}

move_player :: proc() {
	move_delta: Vec3
	if rl.IsKeyDown(.A) {
		move_delta.x -= 1
	}
	if rl.IsKeyDown(.D) {
		move_delta.x += 1
	}
	if rl.IsKeyDown(.W) {
		move_delta.z += 1
	}
	if rl.IsKeyDown(.S) {
		move_delta.z -= 1
	}
	player.move_delta = l.normalize0(move_delta)
	player.velocity = interpolate_vector(move_delta) * player.speed
	camera.look_target = player.position
}

apply_player_velocity :: proc() {
	delta := rl.GetFrameTime()
	player.position += player.velocity * delta
}

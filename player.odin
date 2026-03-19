package main

import "core:fmt"
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

player_update :: proc() {
	move_player()
	apply_player_gravity()
	apply_player_velocity()
	player_collision()
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
	y_velo := player.velocity.y
	player.velocity = interpolate_vector(move_delta) * player.speed
	player.velocity.y = y_velo
	camera.look_target = player.position
}

apply_player_gravity :: proc() {
	delta := rl.GetFrameTime()
	player.velocity.y -= 1 * delta
}

apply_player_velocity :: proc() {
	delta := rl.GetFrameTime()
	player.position += player.velocity * delta
}

player_collision :: proc() {
	player_sphere: Sphere
	player_sphere.x = player.position.x
	player_sphere.y = player.position.y
	player_sphere.z = player.position.z
	player_sphere.w = 0.5
	collided_normals := make([dynamic]Vec3, 0, 4)
	for t in test_level_tris {
		collision, pen_normal, pen_depth := sphere_triangle_collision(player_sphere, t, true)
		if collision {
			already_resolved_normal: bool
			for cn in collided_normals {
				if pen_normal == cn {
					already_resolved_normal = true
					break
				}
			}
			if !already_resolved_normal {
				player.position += pen_normal * pen_depth
				append(&collided_normals, pen_normal)
				fmt.printfln("Col Normal: %v\nCol Depth: %v", pen_normal, pen_depth)
			}
		}
	}
}

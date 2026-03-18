package main

import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

Camera :: struct {
	using raw:     rl.Camera3D,
	target_offset: Vec3,
	target_angle:  f32,
	angle:         f32,
	look_target:   Vec3,
	smoothing:     f32,
	forward:       Vec3,
	right:         Vec3,
	mode:          Camera_Mode,
}

camera: Camera

Camera_Mode :: enum {
	Octal,
	Free,
}

ROT_SEGMENT :: f32(math.PI / 4)

init_camera :: proc() {
	camera = Camera {
		fovy          = 90,
		position      = {5, 2, -10},
		up            = {0, 1, 0},
		target_offset = {0, 5, 5},
		smoothing     = 10,
	}
}

update_camera_position :: proc() {
	delta := rl.GetFrameTime()
	shift: f32
	switch camera.mode {
	case .Octal:
		if rl.IsKeyPressed(.LEFT) {
			camera.target_angle += ROT_SEGMENT
		}
		if rl.IsKeyPressed(.RIGHT) {
			camera.target_angle -= ROT_SEGMENT
		}
	case .Free:
		if rl.IsKeyDown(.A) {
			shift += 1
		}

		if rl.IsKeyDown(.D) {
			shift -= 1
		}
		camera.target_angle += delta * shift * 1
	}

	camera.angle = math.lerp(camera.angle, camera.target_angle, delta * camera.smoothing)

	// camera.angle +=
	offset := Vec3 {
		math.cos(camera.angle) * camera.target_offset.z,
		camera.target_offset.y,
		math.sin(camera.angle) * camera.target_offset.z,
	}


	new_position := camera.look_target + offset
	camera.position = l.lerp(camera.position, new_position, delta * camera.smoothing)
	camera.target = camera.look_target
	camera.forward = l.normalize0(camera.position - camera.look_target)
	camera.right = l.normalize0(l.cross(camera.forward, Vec3{0, 1, 0}))
}

interpolate_vector :: proc(vector: Vec3) -> Vec3 {
	true_vec := (camera.forward * -vector.z) + (camera.right * -vector.x)
	true_vec.y = 0
	return l.normalize0(true_vec)
}
